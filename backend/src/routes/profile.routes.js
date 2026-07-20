const express = require("express");

const router = express.Router();

const protect = require("../middleware/auth.middleware");

const {
  getMyProfile,
  updateMyProfile,
} = require("../controllers/profile.controller");

// Get Logged-in User Profile
router.get("/", protect, getMyProfile);

// Update Logged-in User Profile
router.put("/", protect, updateMyProfile);

module.exports = router;