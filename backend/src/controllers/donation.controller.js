const donationService = require("../services/donation.service");
const {
  donationSchema,
  statusUpdateSchema,
  donationQuerySchema,
} = require("../validators/donation.validator");

// Create Donation
const createDonation = async (req, res) => {
  try {
    const data = donationSchema.parse(req.body);

    const donation = await donationService.createDonation(
      req.user.id,
      data
    );

    return res.status(201).json({
      success: true,
      message: "Donation created successfully.",
      data: donation,
    });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

// Get All Donations
const getAllDonations = async (req, res) => {
  try {
    donationQuerySchema.parse(req.query);

    const donations = await donationService.getAllDonations();

    return res.status(200).json({
      success: true,
      count: donations.length,
      data: donations,
    });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

// Get Donation By ID
const getDonationById = async (req, res) => {
  try {
    const donation = await donationService.getDonationById(req.params.id);

    return res.status(200).json({
      success: true,
      data: donation,
    });
  } catch (error) {
    return res.status(404).json({
      success: false,
      message: error.message,
    });
  }
};

// Update Donation Status
const updateDonationStatus = async (req, res) => {
  try {
    const { status } = statusUpdateSchema.parse(req.body);

    const donation = await donationService.updateDonationStatus(
      req.params.id,
      status
    );

    return res.status(200).json({
      success: true,
      message: "Donation status updated successfully.",
      data: donation,
    });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

// Delete Donation
const deleteDonation = async (req, res) => {
  try {
    const result = await donationService.deleteDonation(req.params.id);

    return res.status(200).json(result);
  } catch (error) {
    return res.status(404).json({
      success: false,
      message: error.message,
    });
  }
};

module.exports = {
  createDonation,
  getAllDonations,
  getDonationById,
  updateDonationStatus,
  deleteDonation,
};