const {
  notificationSchema,
  notificationQuerySchema,
} = require("../validators/notification.validator");

const notificationService = require("../services/notification.service");

// Create Notification
const createNotification = async (req, res) => {
  try {
    const data = notificationSchema.parse(req.body);

    const notification = await notificationService.createNotification(data);

    return res.status(201).json({
      success: true,
      message: "Notification created successfully.",
      data: notification,
    });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

// Get Logged-in User Notifications
const getMyNotifications = async (req, res) => {
  try {
    const query = notificationQuerySchema.parse(req.query);

    const result = await notificationService.getMyNotifications(
      req.user.id,
      query
    );

    return res.status(200).json({
      success: true,
      ...result,
    });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

// Mark Notification as Read
const markAsRead = async (req, res) => {
  try {
    const notification = await notificationService.markAsRead(
      req.params.id,
      req.user.id
    );

    return res.status(200).json({
      success: true,
      message: "Notification marked as read.",
      data: notification,
    });
  } catch (error) {
    return res.status(404).json({
      success: false,
      message: error.message,
    });
  }
};

// Delete Notification
const deleteNotification = async (req, res) => {
  try {
    const result = await notificationService.deleteNotification(
      req.params.id,
      req.user.id
    );

    return res.status(200).json(result);
  } catch (error) {
    return res.status(404).json({
      success: false,
      message: error.message,
    });
  }
};

module.exports = {
  createNotification,
  getMyNotifications,
  markAsRead,
  deleteNotification,
};