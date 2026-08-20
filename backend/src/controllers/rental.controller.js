const rentalService = require("../services/rental.service");
const {
  rentalSchema,
  rentalStatusUpdateSchema,
  rentalQuerySchema,
  verifyPaymentSchema,
} = require("../validators/rental.validator");

// Create Rental
const createRental = async (req, res) => {
  try {
    const data = rentalSchema.parse(req.body);

    const rental = await rentalService.createRental(req.user.id, data);

    return res.status(201).json({
      success: true,
      message: "Rental request created successfully.",
      data: rental,
    });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

// Get All Rentals
const getAllRentals = async (req, res) => {
  try {
    rentalQuerySchema.parse(req.query);

    const rentals = await rentalService.getAllRentals();

    return res.status(200).json({
      success: true,
      count: rentals.length,
      data: rentals,
    });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

// Get Rental By ID
const getRentalById = async (req, res) => {
  try {
    const rental = await rentalService.getRentalById(req.params.id);

    return res.status(200).json({
      success: true,
      data: rental,
    });
  } catch (error) {
    return res.status(404).json({
      success: false,
      message: error.message,
    });
  }
};

// Update Rental Status
const updateRentalStatus = async (req, res) => {
  try {
    const { status } = rentalStatusUpdateSchema.parse(req.body);

    const rental = await rentalService.updateRentalStatus(
      req.params.id,
      status
    );

    return res.status(200).json({
      success: true,
      message: "Rental status updated successfully.",
      data: rental,
    });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

// Delete Rental
const deleteRental = async (req, res) => {
  try {
    const result = await rentalService.deleteRental(req.params.id);

    return res.status(200).json(result);
  } catch (error) {
    return res.status(404).json({
      success: false,
      message: error.message,
    });
  }
};

// Create Razorpay Order
const createPaymentOrder = async (req, res) => {
  try {
    const orderData = await rentalService.createRazorpayOrder(
      req.params.id,
      req.user.id
    );

    return res.status(200).json({
      success: true,
      message: "Razorpay order created successfully.",
      data: orderData,
    });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

// Verify Razorpay Payment
const verifyPayment = async (req, res) => {
  try {
    const validatedData = verifyPaymentSchema.parse(req.body);

    const result = await rentalService.verifyRazorpayPayment(
      req.params.id,
      req.user.id,
      validatedData
    );

    return res.status(200).json({
      success: true,
      message: "Payment verified successfully.",
      data: result,
    });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

// Record Payment Failure
const recordPaymentFailure = async (req, res) => {
  try {
    await rentalService.recordPaymentFailure(req.params.id, req.user.id);

    return res.status(200).json({
      success: true,
      message: "Payment failure recorded.",
    });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

module.exports = {
  createRental,
  getAllRentals,
  getRentalById,
  updateRentalStatus,
  deleteRental,
  createPaymentOrder,
  verifyPayment,
  recordPaymentFailure,
};
