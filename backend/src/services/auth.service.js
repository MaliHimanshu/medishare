/**
 * Auth Service
 * ----------------
 * File: src/services/auth.service.js
 *
 * Handles authentication business logic.
 */

const crypto = require("crypto");
const bcrypt = require("bcryptjs");
const generateToken = require("../utils/generateToken");
const prisma = require("../config/prisma");
const { sendSms } = require("./sms.service");

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
      phone: data.phone,
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
  if (data.phone) {
    try {
      await sendOtp(data.phone);
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

/**
 * Send OTP
 */
const sendOtp = async (phone) => {
  const user = await prisma.user.findFirst({
    where: { phone },
  });

  if (!user) {
    throw new Error("No account found with this phone number");
  }

  if (user.phoneVerified) {
    throw new Error("Phone number is already verified");
  }

  // 30-second cooldown check
  if (user.phoneOtpLastSentAt) {
    const timeSinceLastSent = Date.now() - new Date(user.phoneOtpLastSentAt).getTime();
    if (timeSinceLastSent < 30000) {
      throw new Error(`Please wait ${Math.ceil((30000 - timeSinceLastSent) / 1000)}s before requesting a new OTP`);
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
    },
  });

  // Send the actual SMS
  if (process.env.NODE_ENV !== "production") {
    console.log(`\n========================================\n[DEV ONLY] OTP for ${phone}: ${otp}\n========================================\n`);
  }
  await sendSms(phone, `Your MediShare verification code is: ${otp}. It will expire in 5 minutes.`);

  return true;
};

/**
 * Verify OTP
 */
const verifyOtp = async (phone, otp) => {
  const user = await prisma.user.findFirst({
    where: { phone },
  });

  if (!user) {
    throw new Error("No account found with this phone number");
  }

  if (user.phoneVerified) {
    throw new Error("Phone number is already verified");
  }

  if (!user.phoneOtpHash || !user.phoneOtpExpiresAt) {
    throw new Error("No OTP requested or OTP has expired");
  }

  // Check attempt limit
  if (user.phoneOtpAttempts >= 5) {
    throw new Error("Too many attempts. Please try again later.");
  }

  // Check expiration
  if (new Date() > new Date(user.phoneOtpExpiresAt)) {
    throw new Error("This code has expired. Request a new one.");
  }

  const isValid = await bcrypt.compare(otp, user.phoneOtpHash);

  if (!isValid) {
    // Increment attempts
    await prisma.user.update({
      where: { id: user.id },
      data: {
        phoneOtpAttempts: { increment: 1 },
      },
    });
    throw new Error("Incorrect code. Please try again.");
  }

  // Success
  await prisma.user.update({
    where: { id: user.id },
    data: {
      phoneVerified: true,
      phoneOtpHash: null,
      phoneOtpExpiresAt: null,
      phoneOtpAttempts: 0,
    },
  });

  return true;
};

const jwt = require("jsonwebtoken");

/**
 * Send Forgot Password OTP (email or phone)
 */
const sendForgotPasswordOtp = async (target, type) => {
  const whereClause = type === "email" ? { email: target.toLowerCase() } : { phone: target };

  const user = await prisma.user.findFirst({
    where: whereClause,
  });

  if (!user) {
    throw new Error(`No account found with this ${type === "email" ? "email address" : "phone number"}`);
  }

  // 30-second cooldown check
  if (user.phoneOtpLastSentAt) {
    const timeSinceLastSent = Date.now() - new Date(user.phoneOtpLastSentAt).getTime();
    if (timeSinceLastSent < 30000) {
      throw new Error(`Please wait ${Math.ceil((30000 - timeSinceLastSent) / 1000)}s before requesting a new OTP`);
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

  console.log(`\n========================================\n[DEV ONLY] Forgot Password OTP for ${target} (${type}): ${otp}\n========================================\n`);

  if (type === "phone" && user.phone) {
    try {
      await sendSms(user.phone, `Your MediShare password reset verification code is: ${otp}. It will expire in 5 minutes.`);
    } catch (smsErr) {
      console.warn("SMS send warning:", smsErr.message);
    }
  }

  return true;
};

/**
 * Verify Forgot Password OTP (email or phone)
 */
const verifyForgotPasswordOtp = async (target, type, otp) => {
  const whereClause = type === "email" ? { email: target.toLowerCase() } : { phone: target };

  const user = await prisma.user.findFirst({
    where: whereClause,
  });

  if (!user) {
    throw new Error(`No account found with this ${type === "email" ? "email address" : "phone number"}`);
  }

  if (!user.phoneOtpHash || !user.phoneOtpExpiresAt) {
    throw new Error("No OTP was requested or the code has expired.");
  }

  if (user.phoneOtpAttempts >= 5) {
    throw new Error("Too many incorrect attempts. Please request a new OTP.");
  }

  if (new Date() > new Date(user.phoneOtpExpiresAt)) {
    throw new Error("This verification code has expired. Please request a new code.");
  }

  const isValid = await bcrypt.compare(otp, user.phoneOtpHash);

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
};