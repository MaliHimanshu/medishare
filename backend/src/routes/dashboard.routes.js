const express = require("express");

const {
  getHomeDashboard,
  getUserDashboard,
  getAdminDashboard,
  getMonthlyStatistics,
  getCategoryStatistics,
  getEquipmentStatusStats,
  getDonationStats,
  getRequestStats,
  getRecentActivities,
  getTopDonors,
  getTopRequestedEquipment,
} = require("../services/dashboard.service");

const router = express.Router();

router.get("/", async (req, res, next) => {
  try {
    const dashboard = await getHomeDashboard();

    return res.status(200).json({
      success: true,
      data: dashboard,
    });
  } catch (error) {
    next(error);
  }
});

router.get("/user", async (req, res, next) => {
  try {
    const dashboard = await getUserDashboard(req.user?.id || req.query.userId);

    return res.status(200).json({
      success: true,
      data: dashboard,
    });
  } catch (error) {
    next(error);
  }
});

router.get("/admin", async (req, res, next) => {
  try {
    const dashboard = await getAdminDashboard();

    return res.status(200).json({
      success: true,
      data: dashboard,
    });
  } catch (error) {
    next(error);
  }
});

router.get("/stats/monthly", async (req, res, next) => {
  try {
    const stats = await getMonthlyStatistics();
    return res.status(200).json({ success: true, data: stats });
  } catch (error) {
    next(error);
  }
});

router.get("/stats/categories", async (req, res, next) => {
  try {
    const stats = await getCategoryStatistics();
    return res.status(200).json({ success: true, data: stats });
  } catch (error) {
    next(error);
  }
});

router.get("/stats/equipment-status", async (req, res, next) => {
  try {
    const stats = await getEquipmentStatusStats();
    return res.status(200).json({ success: true, data: stats });
  } catch (error) {
    next(error);
  }
});

router.get("/stats/donations", async (req, res, next) => {
  try {
    const stats = await getDonationStats();
    return res.status(200).json({ success: true, data: stats });
  } catch (error) {
    next(error);
  }
});

router.get("/stats/requests", async (req, res, next) => {
  try {
    const stats = await getRequestStats();
    return res.status(200).json({ success: true, data: stats });
  } catch (error) {
    next(error);
  }
});

router.get("/activities", async (req, res, next) => {
  try {
    const activities = await getRecentActivities();
    return res.status(200).json({ success: true, data: activities });
  } catch (error) {
    next(error);
  }
});

router.get("/top-donors", async (req, res, next) => {
  try {
    const topDonors = await getTopDonors();
    return res.status(200).json({ success: true, data: topDonors });
  } catch (error) {
    next(error);
  }
});

router.get("/top-requests", async (req, res, next) => {
  try {
    const topRequestedEquipment = await getTopRequestedEquipment();
    return res.status(200).json({ success: true, data: topRequestedEquipment });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
