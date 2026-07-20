const express = require("express");

const router = express.Router();

const protect = require("../middleware/auth.middleware");

const {
  createNotification,
  getMyNotifications,
  markAsRead,
  deleteNotification,
} = require("../controllers/notification.controller");

// Create Notification
router.post("/", protect, createNotification);

// Get Logged-in User Notifications
router.get("/", protect, getMyNotifications);

// Mark Notification as Read
router.patch("/:id/read", protect, markAsRead);

// Delete Notification
router.delete("/:id", protect, deleteNotification);

module.exports = router;