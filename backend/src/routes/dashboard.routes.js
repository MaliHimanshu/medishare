const express = require("express");

const router = express.Router();

const protect = require("../middleware/auth.middleware");

const {
  getDashboardSummary,
  getRecentRequests,
  getRecentDonations,
  getRecentNotifications,
} = require("../controllers/dashboard.controller");

// Dashboard Summary
router.get("/summary", protect, getDashboardSummary);

// Recent Requests
router.get("/recent-requests", protect, getRecentRequests);

// Recent Donations
router.get("/recent-donations", protect, getRecentDonations);

// Recent Notifications
router.get("/recent-notifications", protect, getRecentNotifications);

module.exports = router;