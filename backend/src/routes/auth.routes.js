/**
 * Auth Routes
 * --------------------
 * File: src/routes/auth.routes.js
 */

const express = require("express");

const router = express.Router();

const {
  register,
  login,
} = require("../controllers/auth.controller");

const protect = require("../middleware/auth.middleware");

// Public Routes
router.post("/register", register);
router.post("/login", login);

// Protected Route
router.get("/me", protect, (req, res) => {
  res.status(200).json({
    success: true,
    data: req.user,
  });
});

module.exports = router;