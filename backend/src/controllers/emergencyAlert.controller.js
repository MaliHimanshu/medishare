/**
 * Emergency Alert Controller
 * --------------------------
 * File: src/controllers/emergencyAlert.controller.js
 *
 * REST API handlers for emergency alerts and responses.
 */

const {
  createEmergencyAlertSchema,
  updateAlertStatusSchema,
  respondEmergencyAlertSchema,
  updateEmergencyResponseSchema,
} = require("../validators/emergencyAlert.validator");

const {
  createEmergencyAlert,
  getHospitalAlerts,
  getAlertDetails,
  updateAlertStatus,
  getActiveAlertsForNgo,
  respondToAlert,
  updateNgoResponse,
} = require("../services/emergencyAlert.service");

const prisma = require("../config/prisma");

/**
 * Hospital: Create Emergency Alert
 * POST /api/emergency-alerts
 */
const createAlert = async (req, res) => {
  try {
    const data = createEmergencyAlertSchema.parse(req.body);
    const io = req.app.get("io");

    const result = await createEmergencyAlert(req.user, data, io);

    return res.status(201).json({
      success: true,
      message: "Emergency alert sent successfully.",
      data: result.alert,
      notifiedNgos: result.notifiedCount,
    });
  } catch (error) {
    const statusCode = error.statusCode || (error.name === "ZodError" ? 400 : 500);
    return res.status(statusCode).json({
      success: false,
      message: error.message || "Failed to create emergency alert.",
      ...(error.issues ? { errors: error.issues } : {}),
    });
  }
};

/**
 * Hospital: Get Hospital's Own Alerts
 * GET /api/emergency-alerts/my
 */
const getMyAlerts = async (req, res) => {
  try {
    const alerts = await getHospitalAlerts(req.user.id);
    return res.status(200).json({
      success: true,
      data: alerts,
    });
  } catch (error) {
    const statusCode = error.statusCode || 500;
    return res.status(statusCode).json({
      success: false,
      message: error.message || "Failed to retrieve emergency alerts.",
    });
  }
};

/**
 * Hospital / NGO: Get Emergency Alert Details
 * GET /api/emergency-alerts/:id
 */
const getAlert = async (req, res) => {
  try {
    const alert = await getAlertDetails(req.params.id, req.user);
    return res.status(200).json({
      success: true,
      data: alert,
    });
  } catch (error) {
    const statusCode = error.statusCode || 500;
    return res.status(statusCode).json({
      success: false,
      message: error.message || "Failed to retrieve alert details.",
    });
  }
};

/**
 * Hospital: Update Alert Status
 * PATCH /api/emergency-alerts/:id/status
 */
const updateStatus = async (req, res) => {
  try {
    const data = updateAlertStatusSchema.parse(req.body);
    const io = req.app.get("io");

    const updated = await updateAlertStatus(
      req.params.id,
      req.user.id,
      data.status,
      io
    );

    return res.status(200).json({
      success: true,
      message: "Alert status updated successfully.",
      data: updated,
    });
  } catch (error) {
    const statusCode = error.statusCode || (error.name === "ZodError" ? 400 : 500);
    return res.status(statusCode).json({
      success: false,
      message: error.message || "Failed to update alert status.",
      ...(error.issues ? { errors: error.issues } : {}),
    });
  }
};

/**
 * NGO: Get Active Relevant Alerts
 * GET /api/emergency-alerts
 */
const getActiveAlerts = async (req, res) => {
  try {
    const alerts = await getActiveAlertsForNgo(req.user.id);
    return res.status(200).json({
      success: true,
      data: alerts,
    });
  } catch (error) {
    const statusCode = error.statusCode || 500;
    return res.status(statusCode).json({
      success: false,
      message: error.message || "Failed to retrieve active emergency alerts.",
    });
  }
};

/**
 * NGO: Submit Available Quantity
 * POST /api/emergency-alerts/:id/respond
 */
const respond = async (req, res) => {
  try {
    const data = respondEmergencyAlertSchema.parse(req.body);
    const io = req.app.get("io");

    const result = await respondToAlert(req.params.id, req.user, data, io);

    return res.status(201).json({
      success: true,
      message: "Response submitted successfully.",
      data: result.response,
      totalAvailable: result.totalAvailable,
      alertStatus: result.alertStatus,
    });
  } catch (error) {
    const statusCode = error.statusCode || (error.name === "ZodError" ? 400 : 500);
    return res.status(statusCode).json({
      success: false,
      message: error.message || "Failed to submit response.",
      ...(error.issues ? { errors: error.issues } : {}),
    });
  }
};

/**
 * NGO: Update Response
 * PATCH /api/emergency-alerts/:id/respond
 */
const updateResponse = async (req, res) => {
  try {
    const data = updateEmergencyResponseSchema.parse(req.body);
    const io = req.app.get("io");

    const result = await updateNgoResponse(
      req.params.id,
      req.user.id,
      data,
      io
    );

    return res.status(200).json({
      success: true,
      message: "Response updated successfully.",
      data: result.response,
      totalAvailable: result.totalAvailable,
      alertStatus: result.alertStatus,
    });
  } catch (error) {
    const statusCode = error.statusCode || (error.name === "ZodError" ? 400 : 500);
    return res.status(statusCode).json({
      success: false,
      message: error.message || "Failed to update response.",
      ...(error.issues ? { errors: error.issues } : {}),
    });
  }
};

/**
 * User: Register / Update Device FCM Token
 * POST /api/emergency-alerts/device-token
 */
const saveDeviceToken = async (req, res) => {
  try {
    const { token } = req.body;
    if (!token || typeof token !== "string" || !token.trim()) {
      return res.status(400).json({
        success: false,
        message: "Device token is required.",
      });
    }

    await prisma.user.update({
      where: { id: req.user.id },
      data: { fcmToken: token.trim() },
    });

    return res.status(200).json({
      success: true,
      message: "Device token registered successfully.",
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message || "Failed to save device token.",
    });
  }
};

module.exports = {
  createAlert,
  getMyAlerts,
  getAlert,
  updateStatus,
  getActiveAlerts,
  respond,
  updateResponse,
  saveDeviceToken,
};
