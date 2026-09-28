/**
 * Auth Controller
 * -----------------------
 * File: src/controllers/auth.controller.js
 *
 * Handles authentication requests.
 */

const {
  registerSchema,
  loginSchema,
  otpSendSchema,
  otpVerifySchema,
  forgotPasswordSendSchema,
  forgotPasswordVerifySchema,
  resetPasswordSchema,
} = require("../validators/auth.validator");

const {
  registerUser,
  loginUser,
  sendOtp,
  verifyOtp,
  sendForgotPasswordOtp,
  verifyForgotPasswordOtp,
  resetForgotPassword,
} = require("../services/auth.service");

/**
 * Register Controller
 * POST /api/auth/register
 */
const register = async (req, res) => {
  try {
    const data = registerSchema.parse(req.body);

    const result = await registerUser(data);

    return res.status(201).json({
      success: true,
      message: "User registered successfully",
      data: result.user,
      token: result.token,
      otpSent: result.otpSent,
      ...(result.otpError ? { otpError: result.otpError } : {}),
    });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

/**
 * Login Controller
 * POST /api/auth/login
 */
const login = async (req, res) => {
  try {
    const data = loginSchema.parse(req.body);

    const result = await loginUser(
      data.email,
      data.password
    );

    return res.status(200).json({
      success: true,
      message: "Login successful",
      data: result.user,
      token: result.token,
    });
  } catch (error) {
    return res.status(401).json({
      success: false,
      message: error.message,
    });
  }
};

/**
 * Send OTP Controller
 * POST /api/auth/send-otp
 * POST /api/auth/resend-otp
 */
const sendOtpController = async (req, res) => {
  try {
    const data = otpSendSchema.parse(req.body);
    const destination = data.phone || data.email || data.target;
    const type = data.type || (data.email || (destination && destination.includes("@")) ? "email" : "phone");
    const result = await sendOtp(destination, type);

    return res.status(200).json({
      success: true,
      message: result.message || "OTP sent successfully",
    });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

/**
 * Verify OTP Controller
 * POST /api/auth/verify-otp
 */
const verifyOtpController = async (req, res) => {
  try {
    const data = otpVerifySchema.parse(req.body);
    const destination = data.phone || data.email || data.target;
    const type = data.type || (data.email || (destination && destination.includes("@")) ? "email" : "phone");
    const result = await verifyOtp(destination, data.otp, type);

    if (!result.success) {
      return res.status(400).json({
        success: false,
        message: result.message || "Invalid or expired OTP",
      });
    }

    const responsePayload = {
      success: true,
      message: result.message || "Verified successfully",
    };

    if (result.token) {
      responsePayload.token = result.token;
    }
    if (result.user) {
      responsePayload.user = result.user;
      responsePayload.data = result.user;
    }

    return res.status(200).json(responsePayload);
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message || "Invalid or expired OTP",
    });
  }
};

/**
 * Forgot Password - Send OTP Controller
 * POST /api/auth/forgot-password/send-otp
 */
const forgotPasswordSendController = async (req, res) => {
  try {
    const data = forgotPasswordSendSchema.parse(req.body);
    const result = await sendForgotPasswordOtp(data.target, data.type);

    return res.status(200).json({
      success: true,
      message: result?.message || `OTP sent successfully to your ${data.type}`,
      ...(result?.devOtp ? { devOtp: result.devOtp } : {}),
    });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

/**
 * Forgot Password - Verify OTP Controller
 * POST /api/auth/forgot-password/verify-otp
 */
const forgotPasswordVerifyController = async (req, res) => {
  try {
    const data = forgotPasswordVerifySchema.parse(req.body);
    const result = await verifyForgotPasswordOtp(data.target, data.type, data.otp);

    return res.status(200).json({
      success: true,
      message: "OTP verified successfully",
      resetToken: result.resetToken,
    });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

/**
 * Forgot Password - Reset Password Controller
 * POST /api/auth/forgot-password/reset-password
 */
const resetPasswordController = async (req, res) => {
  try {
    const data = resetPasswordSchema.parse(req.body);
    await resetForgotPassword(data.target, data.type, data.resetToken, data.newPassword);

    return res.status(200).json({
      success: true,
      message: "Password reset successfully",
    });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

module.exports = {
  register,
  login,
  sendOtpController,
  verifyOtpController,
  forgotPasswordSendController,
  forgotPasswordVerifyController,
  resetPasswordController,
};