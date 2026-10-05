const express = require("express");
const protect = require("../middleware/auth.middleware");
const { generateDeliveryOtp, verifyDeliveryOtp } = require("../controllers/delivery.controller");

const router = express.Router();

router.post("/:deliveryId/otp/generate", protect, generateDeliveryOtp);
router.post("/:deliveryId/otp/verify", protect, verifyDeliveryOtp);

module.exports = router;
