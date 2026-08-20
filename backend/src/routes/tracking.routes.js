const express = require("express");
const router = express.Router();

const protect = require("../middleware/auth.middleware");

const {
  startTracking,
  stopTracking,
  publishPing,
  getLatestTracking,
  getTrackingHistory,
} = require("../controllers/tracking.controller");

router.use(protect);

router.post("/:rentalId/start", startTracking);
router.post("/:rentalId/stop", stopTracking);
router.post("/:rentalId/ping", publishPing);
router.get("/:rentalId", getLatestTracking);
router.get("/:rentalId/history", getTrackingHistory);

module.exports = router;
