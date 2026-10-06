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

  // Trigger SMS OTP sending if phone is provided
  let otpSent = false;
  let otpError = null;

  if (normalizedPhone) {
    try {
      await sendOtp(normalizedPhone);
      otpSent = true;
    } catch (smsErr) {
      otpError = smsErr.message;
      console.warn("Could not automatically send OTP during registration:", smsErr.message);
    }
  }

  // Remove password before returning
  const { password, ...userWithoutPassword } = user;

  return {
    user: userWithoutPassword,
    token: generateToken(user),
    otpSent,
    ...(otpError ? { otpError } : {}),
  };
};

/**
 * Login User (supports email or phone number)
 */
const loginUser = async (identifier, password) => {
  if (!identifier || !password) {
    throw new Error("Email/phone and password are required");
  }

  const isEmail = identifier.includes("@");
  let user;

  if (isEmail) {
    user = await prisma.user.findUnique({
      where: {
        email: identifier.trim().toLowerCase(),
      },
    });
  } else {
    user = await findUserByPhone(identifier);
  }

  if (!user) {
    throw new Error("Invalid email/phone or password");
  }

  const isMatch = await bcrypt.compare(password, user.password);

  if (!isMatch) {
    throw new Error("Invalid email/phone or password");
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

const { sendVerifyOtp, checkVerifyOtp, getVerifyConfig } = require("./twilioVerify.service");

/**
 * Send OTP (SMS via Twilio Verify)
 */
const sendOtp = async (destination, type) => {
  let targetPhone = destination;

  // If email was provided, resolve to user's registered phone
  if (typeof destination === "string" && destination.includes("@")) {
    const user = await prisma.user.findFirst({
      where: { email: destination.trim().toLowerCase() },
    });
    if (!user) {
      throw new Error("No account found with this email address");
    }
    if (!user.phone) {
      throw new Error("No registered phone number found for this account to receive SMS verification");
    }
    targetPhone = user.phone;
  }

  const normalizedPhone = normalizePhoneNumber(targetPhone);
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
    message: "OTP sent successfully to your phone",
  };
};

/**
 * Verify OTP (SMS via Twilio Verify)
 */
const verifyOtp = async (destination, otp, type, userId = null) => {
  if (!otp || typeof otp !== "string" || otp.trim().length !== 6) {
    return {
      success: false,
      message: "Invalid or expired OTP",
    };
  }

  let targetPhone = destination;
  if (typeof destination === "string" && destination.includes("@")) {
    const user = await prisma.user.findFirst({
      where: { email: destination.trim().toLowerCase() },
    });
    if (!user || !user.phone) {
      return {
        success: false,
        message: "No registered phone number found for this account",
      };
    }
    targetPhone = user.phone;
  }

  const normalizedPhone = normalizePhoneNumber(targetPhone);

  // Check with Twilio Verify
  const verifyResult = await checkVerifyOtp(normalizedPhone, otp.trim());

  if (!verifyResult.success) {
    return {
      success: false,
      message: verifyResult.message || "Invalid or expired OTP",
    };
  }

  // Verification succeeded - find user securely using authenticated session if available
  let user;
  if (userId) {
    user = await prisma.user.findUnique({ where: { id: userId } });
  }
  // Fallback ONLY if not authenticated (should not happen for standard profile verification)
  if (!user) {
    user = await findUserByPhone(normalizedPhone);
  }

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
 * Send Forgot Password OTP (via Twilio Verify SMS)
 */
const sendForgotPasswordOtp = async (target, type) => {
  let user;
  if (typeof target === "string" && target.includes("@")) {
    user = await prisma.user.findFirst({
      where: { email: target.trim().toLowerCase() },
    });
    if (!user) {
      throw new Error("No account found with this email address");
    }
    if (!user.phone) {
      throw new Error("No registered phone number found for this account to receive SMS verification");
    }
  } else {
    user = await findUserByPhone(target);
    if (!user) {
      throw new Error("No account found with this phone number");
    }
  }

  const normalizedPhone = normalizePhoneNumber(user.phone);

  // 30-second cooldown check
  if (user.phoneOtpLastSentAt) {
    const timeSinceLastSent = Date.now() - new Date(user.phoneOtpLastSentAt).getTime();
    if (timeSinceLastSent < 30000) {
      throw new Error(
        `Please wait ${Math.ceil((30000 - timeSinceLastSent) / 1000)}s before requesting a new OTP`
      );
    }
  }

  await sendVerifyOtp(normalizedPhone);

  await prisma.user.update({
    where: { id: user.id },
    data: {
      phoneOtpHash: null,
      phoneOtpExpiresAt: null,
      phoneOtpLastSentAt: new Date(),
      phoneOtpAttempts: 0,
    },
  });

  return {
    success: true,
    message: "OTP sent successfully to your phone via SMS",
    phone: normalizedPhone,
  };
};

/**
 * Verify Forgot Password OTP (via Twilio Verify SMS)
 */
const verifyForgotPasswordOtp = async (target, type, otp) => {
  if (!otp || typeof otp !== "string" || otp.trim().length !== 6) {
    throw new Error("OTP must be exactly 6 digits");
  }

  let user;
  if (typeof target === "string" && target.includes("@")) {
    user = await prisma.user.findFirst({
      where: { email: target.trim().toLowerCase() },
    });
  } else {
    user = await findUserByPhone(target);
  }

  if (!user || !user.phone) {
    throw new Error("User account or registered phone not found");
  }

  const normalizedPhone = normalizePhoneNumber(user.phone);

  const verifyResult = await checkVerifyOtp(normalizedPhone, otp.trim());
  if (!verifyResult.success) {
    throw new Error(verifyResult.message || "Invalid or expired OTP");
  }

  await prisma.user.update({
    where: { id: user.id },
    data: {
      phoneOtpHash: null,
      phoneOtpExpiresAt: null,
      phoneOtpAttempts: 0,
    },
  });

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