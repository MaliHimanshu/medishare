const trackingService = require("../services/tracking.service");
const {
  pingSchema,
  historyQuerySchema,
} = require("../validators/tracking.validator");

const startTracking = async (req, res) => {
  try {
    const rental = await trackingService.startTracking(
      req.params.rentalId,
      req.user.id
    );

    return res.status(200).json({
      success: true,
      message: "Live tracking started.",
      data: rental,
    });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

const stopTracking = async (req, res) => {
  try {
    const rental = await trackingService.stopTracking(
      req.params.rentalId,
      req.user.id,
      req.user.role
    );

    return res.status(200).json({
      success: true,
      message: "Live tracking stopped.",
      data: rental,
    });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

const publishPing = async (req, res) => {
  try {
    const validated = pingSchema.parse(req.body);

    const ping = await trackingService.publishPing(
      req.params.rentalId,
      req.user.id,
      validated
    );

    return res.status(201).json({
      success: true,
      message: "Location updated.",
      data: ping,
    });
  } catch (error) {
    if (error.name === "ZodError") {
      return res.status(400).json({
        success: false,
        message: error.errors?.[0]?.message || "Invalid location payload.",
      });
    }

    return res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

const getLatestTracking = async (req, res) => {
  try {
    const data = await trackingService.getLatestTracking(
      req.params.rentalId,
      req.user.id,
      req.user.role
    );

    return res.status(200).json({
      success: true,
      data,
    });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

const getTrackingHistory = async (req, res) => {
  try {
    const query = historyQuerySchema.parse(req.query);

    const data = await trackingService.getTrackingHistory(
      req.params.rentalId,
      req.user.id,
      req.user.role,
      query
    );

    return res.status(200).json({
      success: true,
      data,
    });
  } catch (error) {
    if (error.name === "ZodError") {
      return res.status(400).json({
        success: false,
        message: error.errors?.[0]?.message || "Invalid query parameters.",
      });
    }

    return res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

module.exports = {
  startTracking,
  stopTracking,
  publishPing,
  getLatestTracking,
  getTrackingHistory,
};
