/**
 * @swagger
 * tags:
 *   name: Authentication
 *   description: User Authentication APIs
 */

/**
 * @swagger
 * /api/auth/register:
 *   post:
 *     summary: Register a new user
 *     description: Create a new user account.
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *               - email
 *               - password
 *               - role
 *             properties:
 *               name:
 *                 type: string
 *                 example: Amit Kumar
 *               email:
 *                 type: string
 *                 example: amit@gmail.com
 *               password:
 *                 type: string
 *                 example: Password@123
 *               phone:
 *                 type: string
 *                 example: "9876543210"
 *               address:
 *                 type: string
 *                 example: Ahmedabad
 *               role:
 *                 type: string
 *                 enum:
 *                   - ADMIN
 *                   - DONOR
 *                   - NGO
 *                   - HOSPITAL
 *                   - RECIPIENT
 *                 example: DONOR
 *     responses:
 *       201:
 *         description: User registered successfully.
 *       400:
 *         description: Validation error.
 */

/**
 * @swagger
 * /api/auth/login:
 *   post:
 *     summary: Login user
 *     description: Authenticate user and return JWT token.
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *             properties:
 *               email:
 *                 type: string
 *                 example: amit@gmail.com
 *               password:
 *                 type: string
 *                 example: Password@123
 *     responses:
 *       200:
 *         description: Login successful.
 *       401:
 *         description: Invalid credentials.
 */

/**
 * @swagger
 * /api/auth/send-otp:
 *   post:
 *     summary: Send SMS OTP
 *     description: Send a 6-digit OTP to the specified phone number using Twilio Verify.
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - phone
 *             properties:
 *               phone:
 *                 type: string
 *                 example: "+918000917657"
 *     responses:
 *       200:
 *         description: OTP sent successfully.
 *       400:
 *         description: Validation error or provider error.
 */

/**
 * @swagger
 * /api/auth/verify-otp:
 *   post:
 *     summary: Verify SMS OTP
 *     description: Check a 6-digit OTP code using Twilio Verify.
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - phone
 *               - otp
 *             properties:
 *               phone:
 *                 type: string
 *                 example: "+918000917657"
 *               otp:
 *                 type: string
 *                 example: "123456"
 *     responses:
 *       200:
 *         description: Phone number verified successfully.
 *       400:
 *         description: Invalid or expired OTP.
 */

/**
 * @swagger
 * /api/auth/me:
 *   get:
 *     summary: Get logged-in user profile
 *     description: Returns the currently authenticated user's profile.
 *     tags: [Authentication]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: User profile fetched successfully.
 *       401:
 *         description: Unauthorized.
 */

const express = require("express");

const router = express.Router();

const {
  register,
  login,
  sendOtpController,
  verifyOtpController,
  forgotPasswordSendController,
  forgotPasswordVerifyController,
  resetPasswordController,
} = require("../controllers/auth.controller");

const protect = require("../middleware/auth.middleware");

// ==========================
// Public Routes
// ==========================

// Register User
router.post("/register", register);

// Login User
router.post("/login", login);

// Send OTP (also for resend)
router.post("/send-otp", sendOtpController);
router.post("/resend-otp", sendOtpController);

// Verify OTP
router.post("/verify-otp", verifyOtpController);

// Forgot Password Flow
router.post("/forgot-password/send-otp", forgotPasswordSendController);
router.post("/forgot-password/verify-otp", forgotPasswordVerifyController);
router.post("/forgot-password/reset-password", resetPasswordController);

// ==========================
// Protected Routes
// ==========================

// Get Logged-in User Profile
router.get("/me", protect, (req, res) => {
  if (req.user) {
    console.log(`[SAFE DEBUG LOG] GET /api/auth/me response: email=${req.user.email}, database_role=${req.user.role}, me_response_role=${req.user.role}`);
  }
  res.status(200).json({
    success: true,
    data: req.user,
  });
});

module.exports = router;