const express = require("express");

const router = express.Router();

const protect = require("../middleware/auth.middleware");

const {
  getMyProfile,
  updateMyProfile,
  verifyUser,
} = require("../controllers/profile.controller");

// Get Logged-in User Profile
router.get("/", protect, getMyProfile);

// Update Logged-in User Profile
router.put("/", protect, updateMyProfile);

// Admin: Verify Organization User
router.patch("/verify/:userId", protect, verifyUser);

module.exports = router;