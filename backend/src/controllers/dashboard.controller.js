const dashboardService = require("../services/dashboard.service");

// Dashboard Summary
const getDashboardSummary = async (req, res) => {
  try {
    const summary = await dashboardService.getDashboardSummary();

    return res.status(200).json({
      success: true,
      data: summary,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// Recent Requests
const getRecentRequests = async (req, res) => {
  try {
    const requests = await dashboardService.getRecentRequests();

    return res.status(200).json({
      success: true,
      data: requests,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// Recent Donations
const getRecentDonations = async (req, res) => {
  try {
    const donations = await dashboardService.getRecentDonations();

    return res.status(200).json({
      success: true,
      data: donations,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// Recent Notifications
const getRecentNotifications = async (req, res) => {
  try {
    const notifications = await dashboardService.getRecentNotifications();

    return res.status(200).json({
      success: true,
      data: notifications,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

module.exports = {
  getDashboardSummary,
  getRecentRequests,
  getRecentDonations,
  getRecentNotifications,
};