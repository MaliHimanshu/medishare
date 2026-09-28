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
const { sendEmailOtp } = require("./email.service");
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
 * Send OTP
 * Supports phone (via Twilio Verify) and email (via 6-digit cryptographic OTP)
 */
const sendOtp = async (destination, type) => {
  const isEmail = type === "email" || (typeof destination === "string" && destination.includes("@"));

  if (isEmail) {
    const email = destination.trim().toLowerCase();
    const user = await prisma.user.findFirst({ where: { email } });

    // 30-second cooldown check if user exists
    if (user && user.phoneOtpLastSentAt) {
      const timeSinceLastSent = Date.now() - new Date(user.phoneOtpLastSentAt).getTime();
      if (timeSinceLastSent < 30000) {
        const waitSeconds = Math.ceil((30000 - timeSinceLastSent) / 1000);
        throw new Error(`Please wait ${waitSeconds}s before requesting a new OTP`);
      }
    }

    const otp = generateOtp();
    const otpHash = await bcrypt.hash(`email:${otp}`, 10);
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes

    await sendEmailOtp(email, otp);

    if (user) {
      await prisma.user.update({
        where: { id: user.id },
        data: {
          phoneOtpHash: otpHash,
          phoneOtpExpiresAt: expiresAt,
          phoneOtpLastSentAt: new Date(),
          phoneOtpAttempts: 0,
        },
      });
    }

    return {
      success: true,
      message: "OTP sent successfully to your email",
    };
  }

  // Phone flow
  const normalizedPhone = normalizePhoneNumber(destination);
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
 * Supports phone (via Twilio Verify) and email (via 6-digit cryptographic OTP)
 */
const verifyOtp = async (destination, otp, type) => {
  if (!otp || typeof otp !== "string" || otp.trim().length !== 6) {
    return {
      success: false,
      message: "Invalid or expired OTP",
    };
  }

  const isEmail = type === "email" || (typeof destination === "string" && destination.includes("@"));

  if (isEmail) {
    const email = destination.trim().toLowerCase();
    const user = await prisma.user.findFirst({ where: { email } });

    if (!user) {
      return {
        success: false,
        message: "No account found with this email",
      };
    }

    if (!user.phoneOtpHash || !user.phoneOtpExpiresAt) {
      return {
        success: false,
        message: "No OTP was requested or the code has expired.",
      };
    }

    if (user.phoneOtpAttempts >= 5) {
      return {
        success: false,
        message: "Too many incorrect attempts. Please request a new OTP.",
      };
    }

    if (new Date() > new Date(user.phoneOtpExpiresAt)) {
      return {
        success: false,
        message: "This verification code has expired. Please request a new code.",
      };
    }

    const isValid = await bcrypt.compare(`email:${otp.trim()}`, user.phoneOtpHash);
    if (!isValid) {
      await prisma.user.update({
        where: { id: user.id },
        data: {
          phoneOtpAttempts: { increment: 1 },
        },
      });
      return {
        success: false,
        message: "Incorrect verification code. Please try again.",
      };
    }

    const updatedUser = await prisma.user.update({
      where: { id: user.id },
      data: {
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
      message: "Email verified successfully",
      user: userWithoutPassword,
      token,
    };
  }

  // Phone flow
  const normalizedPhone = normalizePhoneNumber(destination);

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

  if (type === "phone") {
    const normalizedPhone = normalizePhoneNumber(user.phone || target);
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
      message: "OTP sent successfully to your phone",
    };
  }

  // Email OTP flow: generate 6-digit OTP, 5-minute expiry, type-isolated hash
  const otp = generateOtp();
  const otpHash = await bcrypt.hash(`email:${otp}`, 10);
  const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes

  // Send real email or dev log via email service
  const emailResult = await sendEmailOtp(user.email, otp);

  await prisma.user.update({
    where: { id: user.id },
    data: {
      phoneOtpHash: otpHash,
      phoneOtpExpiresAt: expiresAt,
      phoneOtpLastSentAt: new Date(),
      phoneOtpAttempts: 0,
    },
  });

  return {
    success: true,
    message: "OTP sent successfully to your email",
    ...(process.env.NODE_ENV !== "production" && emailResult?.otp ? { devOtp: emailResult.otp } : {}),
  };
};

/**
 * Verify Forgot Password OTP (email or phone)
 */
const verifyForgotPasswordOtp = async (target, type, otp) => {
  if (!otp || typeof otp !== "string" || otp.trim().length !== 6) {
    throw new Error("OTP must be exactly 6 digits");
  }

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

  // If user has NO phoneOtpHash and type is phone, check Twilio Verify
  if (type === "phone" && !user.phoneOtpHash) {
    const { isConfigured } = getVerifyConfig();
    const normalizedPhone = normalizePhoneNumber(user.phone || target);

    if (isConfigured) {
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
    }
  }

  // Database-stored OTP verification (Email OTP or Phone fallback)
  if (!user.phoneOtpHash || !user.phoneOtpExpiresAt) {
    throw new Error("No OTP was requested or the code has expired. Please request a new OTP.");
  }

  if (user.phoneOtpAttempts >= 5) {
    throw new Error("Too many incorrect attempts. Please request a new OTP.");
  }

  if (new Date() > new Date(user.phoneOtpExpiresAt)) {
    throw new Error("This verification code has expired. Please request a new code.");
  }

  // Cross-channel protection: ensure email OTP cannot verify phone and vice versa
  let isValid = false;
  const typedMatch = await bcrypt.compare(`${type}:${otp.trim()}`, user.phoneOtpHash);
  if (typedMatch) {
    isValid = true;
  } else {
    const plainMatch = await bcrypt.compare(otp.trim(), user.phoneOtpHash);
    if (plainMatch) isValid = true;
  }

  if (!isValid) {
    await prisma.user.update({
      where: { id: user.id },
      data: {
        phoneOtpAttempts: { increment: 1 },
      },
    });
    throw new Error("Incorrect verification code. Please try again.");
  }

  // Clear OTP immediately so it cannot be verified or used again
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