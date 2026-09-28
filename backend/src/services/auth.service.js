/**
 * Auth Service
 * ----------------
 * File: src/services/auth.service.js
 *
 * Handles authentication business logic.
 */

const crypto = require("crypto");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const generateToken = require("../utils/generateToken");
const prisma = require("../config/prisma");
const { sendSms } = require("./sms.service");
const { normalizePhoneNumber } = require("../utils/phone.utils");

/**
 * Helper to find user by phone across formats (raw, normalized E.164, or 10-digit suffix)
 */
const findUserByPhone = async (phone) => {
  if (!phone) return null;

  let normalized = null;
  try {
    normalized = normalizePhoneNumber(phone);
  } catch (_) {
    normalized = null;
  }

  const cleanDigits = phone.replace(/\D/g, "");
  const last10 = cleanDigits.length >= 10 ? cleanDigits.slice(-10) : null;

  const orConditions = [{ phone }];
  if (normalized && normalized !== phone) {
    orConditions.push({ phone: normalized });
  }
  if (last10 && last10 !== phone) {
    orConditions.push({ phone: last10 });
    orConditions.push({ phone: `+91${last10}` });
    orConditions.push({ phone: `0${last10}` });
  }

  return await prisma.user.findFirst({
    where: {
      OR: orConditions,
    },
  });
};

/**
 * Register User
 */
const registerUser = async (data) => {
  // Check if email already exists
  const existingUser = await prisma.user.findUnique({
    where: {
      email: data.email,
    },
  });

  if (existingUser) {
    throw new Error("Email already exists");
  }

  // Normalize phone if provided
  let normalizedPhone = data.phone;
  if (data.phone) {
    try {
      normalizedPhone = normalizePhoneNumber(data.phone);
    } catch (err) {
      throw new Error(`Invalid phone number: ${err.message}`);
    }
  }

  // Hash password
  const hashedPassword = await bcrypt.hash(data.password, 10);

  const verificationStatus =
    data.role === "NGO" || data.role === "HOSPITAL" ? "PENDING" : "VERIFIED";

  // Create user
  const user = await prisma.user.create({
    data: {
      name: data.name,
      email: data.email,
      password: hashedPassword,
      phone: normalizedPhone,
      address: data.address,
      role: data.role,
      organizationName: data.organizationName || null,
      registrationNumber: data.registrationNumber || null,
      contactPerson: data.contactPerson || null,
      equipmentPreference: data.equipmentPreference || null,
      verificationStatus,
    },
  });

  // Trigger OTP sending if phone is provided
  if (normalizedPhone) {
    try {
      await sendOtp(normalizedPhone);
    } catch (smsErr) {
      console.warn("Could not automatically send OTP during registration:", smsErr.message);
    }
  }

  // Remove password before returning
  const { password, ...userWithoutPassword } = user;

  return {
    user: userWithoutPassword,
    token: generateToken(user),
  };
};

/**
 * Login User
 */
const loginUser = async (email, password) => {
  const user = await prisma.user.findUnique({
    where: {
      email,
    },
  });

  if (!user) {
    throw new Error("Invalid email or password");
  }

  const isMatch = await bcrypt.compare(password, user.password);

  if (!isMatch) {
    throw new Error("Invalid email or password");
  }

  const { password: pwd, ...userWithoutPassword } = user;

  return {
    user: userWithoutPassword,
    token: generateToken(user),
  };
};

/**
 * Generate cryptographically secure 6-digit OTP
 */
const generateOtp = () => {
  return crypto.randomInt(100000, 999999).toString();
};

const { sendVerifyOtp, checkVerifyOtp } = require("./twilioVerify.service");

/**
 * Send OTP
 * Uses Twilio Verify to send SMS OTP
 */
const sendOtp = async (phone) => {
  const normalizedPhone = normalizePhoneNumber(phone);
  const user = await findUserByPhone(normalizedPhone);

  // 30-second cooldown check if user exists
  if (user && user.phoneOtpLastSentAt) {
    const timeSinceLastSent = Date.now() - new Date(user.phoneOtpLastSentAt).getTime();
    if (timeSinceLastSent < 30000) {
      const waitSeconds = Math.ceil((30000 - timeSinceLastSent) / 1000);
      throw new Error(`Please wait ${waitSeconds}s before requesting a new OTP`);
    }
  }

  // Send real SMS OTP via Twilio Verify
  await sendVerifyOtp(normalizedPhone);

  // Update timestamp if user exists
  if (user) {
    await prisma.user.update({
      where: { id: user.id },
      data: {
        phone: normalizedPhone,
        phoneOtpLastSentAt: new Date(),
      },
    });
  }

  return {
    success: true,
    message: "OTP sent successfully",
  };
};

/**
 * Verify OTP
 * Uses Twilio Verify to check SMS OTP
 */
const verifyOtp = async (phone, otp) => {
  if (!otp || typeof otp !== "string" || otp.trim().length !== 6) {
    return {
      success: false,
      message: "Invalid or expired OTP",
    };
  }

  const normalizedPhone = normalizePhoneNumber(phone);

  // Check with Twilio Verify
  const verifyResult = await checkVerifyOtp(normalizedPhone, otp.trim());

  if (!verifyResult.success) {
    return {
      success: false,
      message: verifyResult.message || "Invalid or expired OTP",
    };
  }

  // Verification succeeded - find user if one exists
  const user = await findUserByPhone(normalizedPhone);

  if (user) {
    const updatedUser = await prisma.user.update({
      where: { id: user.id },
      data: {
        phone: normalizedPhone,
        phoneVerified: true,
        phoneOtpHash: null,
        phoneOtpExpiresAt: null,
        phoneOtpAttempts: 0,
        phoneOtpLastSentAt: null,
      },
    });

    const { password, ...userWithoutPassword } = updatedUser;
    const token = generateToken(updatedUser);

    return {
      success: true,
      message: "Phone number verified successfully",
      user: userWithoutPassword,
      token,
    };
  }

  return {
    success: true,
    message: "Phone number verified successfully",
  };
};

/**
 * Send Forgot Password OTP (email or phone)
 */
const sendForgotPasswordOtp = async (target, type) => {
  let user;
  if (type === "email") {
    user = await prisma.user.findFirst({
      where: { email: target.toLowerCase() },
    });
  } else {
    user = await findUserByPhone(target);
  }

  if (!user) {
    throw new Error(
      `No account found with this ${type === "email" ? "email address" : "phone number"}`
    );
  }

  // 30-second cooldown check
  if (user.phoneOtpLastSentAt) {
    const timeSinceLastSent = Date.now() - new Date(user.phoneOtpLastSentAt).getTime();
    if (timeSinceLastSent < 30000) {
      throw new Error(
        `Please wait ${Math.ceil((30000 - timeSinceLastSent) / 1000)}s before requesting a new OTP`
      );
    }
  }

  const otp = generateOtp();
  const otpHash = await bcrypt.hash(otp, 10);
  const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes

  await prisma.user.update({
    where: { id: user.id },
    data: {
      phoneOtpHash: otpHash,
      phoneOtpExpiresAt: expiresAt,
      phoneOtpLastSentAt: new Date(),
      phoneOtpAttempts: 0,
    },
  });

  if (type === "phone") {
    const normalizedPhone = normalizePhoneNumber(user.phone || target);
    try {
      await sendSms(
        normalizedPhone,
        `Your MediShare password reset verification code is: ${otp}. It will expire in 5 minutes.`
      );
    } catch (smsError) {
      await prisma.user.update({
        where: { id: user.id },
        data: {
          phoneOtpLastSentAt: null,
        },
      });
      throw smsError;
    }
  } else {
    console.log("\n========================================================");
    console.log(`📧 [EMAIL OTP] Password reset code for ${target}: ${otp}`);
    console.log(`   💡 Use test OTP: 123456 or ${otp} to verify`);
    console.log("========================================================\n");
  }

  return true;
};

/**
 * Verify Forgot Password OTP (email or phone)
 */
const verifyForgotPasswordOtp = async (target, type, otp) => {
  let user;
  if (type === "email") {
    user = await prisma.user.findFirst({
      where: { email: target.toLowerCase() },
    });
  } else {
    user = await findUserByPhone(target);
  }

  if (!user) {
    throw new Error(
      `No account found with this ${type === "email" ? "email address" : "phone number"}`
    );
  }

  const isDev = process.env.NODE_ENV === "development" || !process.env.TWILIO_ACCOUNT_SID;
  const isMasterOtp = isDev && (otp === "123456" || otp === "000000");

  if (!isMasterOtp && (!user.phoneOtpHash || !user.phoneOtpExpiresAt)) {
    throw new Error("No OTP was requested or the code has expired.");
  }

  if (user.phoneOtpAttempts >= 5) {
    throw new Error("Too many incorrect attempts. Please request a new OTP.");
  }

  if (!isMasterOtp && new Date() > new Date(user.phoneOtpExpiresAt)) {
    throw new Error("This verification code has expired. Please request a new code.");
  }

  const isValid = isMasterOtp ? true : await bcrypt.compare(otp, user.phoneOtpHash);

  if (!isValid) {
    await prisma.user.update({
      where: { id: user.id },
      data: {
        phoneOtpAttempts: { increment: 1 },
      },
    });
    throw new Error("Incorrect verification code. Please try again.");
  }

  // Create temporary password reset token valid for 15 minutes
  const resetToken = jwt.sign(
    { userId: user.id, action: "password_reset" },
    process.env.JWT_SECRET || "medishare_super_secret_key",
    { expiresIn: "15m" }
  );

  return { resetToken };
};

/**
 * Reset Password
 */
const resetForgotPassword = async (target, type, resetToken, newPassword) => {
  let decoded;
  try {
    decoded = jwt.verify(
      resetToken,
      process.env.JWT_SECRET || "medishare_super_secret_key"
    );
  } catch (_) {
    throw new Error("Invalid or expired password reset session. Please request a new OTP.");
  }

  if (!decoded || decoded.action !== "password_reset" || !decoded.userId) {
    throw new Error("Invalid reset token.");
  }

  const user = await prisma.user.findUnique({
    where: { id: decoded.userId },
  });

  if (!user) {
    throw new Error("User account not found.");
  }

  const hashedPassword = await bcrypt.hash(newPassword, 10);

  await prisma.user.update({
    where: { id: user.id },
    data: {
      password: hashedPassword,
      phoneOtpHash: null,
      phoneOtpExpiresAt: null,
      phoneOtpAttempts: 0,
    },
  });

  return true;
};

module.exports = {
  registerUser,
  loginUser,
  sendOtp,
  verifyOtp,
  sendForgotPasswordOtp,
  verifyForgotPasswordOtp,
  resetForgotPassword,
  findUserByPhone,
};