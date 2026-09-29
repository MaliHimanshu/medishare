/**
 * Emergency Alert Routes
 * ----------------------
 * File: src/routes/emergencyAlert.routes.js
 */

const express = require("express");
const router = express.Router();

const protect = require("../middleware/auth.middleware");
const authorize = require("../middleware/role.middleware");

const {
  createAlert,
  getMyAlerts,
  getAlert,
  updateStatus,
  getActiveAlerts,
  respond,
  updateResponse,
  saveDeviceToken,
} = require("../controllers/emergencyAlert.controller");

// Hospital Endpoints
router.post(
  "/",
  protect,
  authorize("HOSPITAL", "ADMIN"),
  createAlert
);

router.get(
  "/my",
  protect,
  authorize("HOSPITAL", "ADMIN"),
  getMyAlerts
);

router.patch(
  "/:id/status",
  protect,
  authorize("HOSPITAL", "ADMIN"),
  updateStatus
);

// NGO Endpoints
router.get(
  "/",
  protect,
  authorize("NGO", "ADMIN"),
  getActiveAlerts
);

router.post(
  "/:id/respond",
  protect,
  authorize("NGO", "ADMIN"),
  respond
);

router.patch(
  "/:id/respond",
  protect,
  authorize("NGO", "ADMIN"),
  updateResponse
);

// Shared Alert Detail (Hospital & NGO)
router.get(
  "/:id",
  protect,
  getAlert
);

// Device token registration
router.post(
  "/device-token",
  protect,
  saveDeviceToken
);

module.exports = router;
