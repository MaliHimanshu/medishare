const express = require("express");
const router = express.Router();

const {
  createDonation,
  getAllDonations,
  getDonationById,
  updateDonationStatus,
  deleteDonation,
} = require("../controllers/donation.controller");

const protect = require("../middleware/auth.middleware");

// Create Donation
router.post("/", protect, createDonation);

// Get All Donations
router.get("/", protect, getAllDonations);

// Get Donation By ID
router.get("/:id", protect, getDonationById);

// Update Donation Status
router.patch("/:id/status", protect, updateDonationStatus);

// Delete Donation
router.delete("/:id", protect, deleteDonation);

module.exports = router;