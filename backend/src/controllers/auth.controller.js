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
} = require("../validators/auth.validator");

const {
  registerUser,
  loginUser,
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

module.exports = {
  register,
  login,
};