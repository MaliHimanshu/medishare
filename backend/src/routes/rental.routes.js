const express = require("express");
const router = express.Router();

const {
  createRental,
  getAllRentals,
  getRentalById,
  updateRentalStatus,
  deleteRental,
  createPaymentOrder,
  verifyPayment,
  recordPaymentFailure,
} = require("../controllers/rental.controller");

const protect = require("../middleware/auth.middleware");

// Create Rental
router.post("/", protect, createRental);

// Get All Rentals
router.get("/", protect, getAllRentals);

// Get Rental By ID
router.get("/:id", protect, getRentalById);

// Update Rental Status
router.patch("/:id/status", protect, updateRentalStatus);

// Delete Rental
router.delete("/:id", protect, deleteRental);

// ── Razorpay Payment Routes ───────────────────────────────
// Create Razorpay Order
router.post("/:id/create-order", protect, createPaymentOrder);

// Verify Razorpay Payment (Server-side HMAC-SHA256 signature check)
router.post("/:id/verify-payment", protect, verifyPayment);

// Record Payment Failure
router.post("/:id/payment-failed", protect, recordPaymentFailure);

module.exports = router;
