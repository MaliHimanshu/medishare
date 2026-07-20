/**
 * Dashboard Service
 * ------------------
 * File: src/services/dashboard.service.js
 *
 * Contains all optimized Prisma queries for dashboard analytics.
 * Uses count(), aggregate(), groupBy() and parallel Promise.all()
 * execution to minimize response times.
 *
 * Methods:
 * - getHomeDashboard()
 * - getUserDashboard()
 * - getAdminDashboard()
 * - getMonthlyStatistics()
 * - getCategoryStatistics()
 * - getEquipmentStatusStats()
 * - getDonationStats()
 * - getRequestStats()
 * - getRecentActivities()
 * - getTopDonors()
 * - getTopRequestedEquipment()
 */

const prisma = require("../config/prisma");

// ─────────────────────────────────────────────
// Helper: Date N months ago
// ─────────────────────────────────────────────

/**
 * Returns a Date object for N months before today (UTC midnight).
 * Used to build date range filters for monthly statistics.
 *
 * @param {number} months - How many months back
 * @returns {Date}
 */
const monthsAgo = (months) => {
  const d = new Date();
  d.setMonth(d.getMonth() - months);
  d.setDate(1);
  d.setHours(0, 0, 0, 0);
  return d;
};

/**
 * Returns a short "YYYY-MM" label for grouping monthly data.
 *
 * @param {Date} date
 * @returns {string} e.g. "2024-03"
 */
const toMonthLabel = (date) => {
  const d = new Date(date);
  const year = d.getFullYear();
  const month = String(d.getMonth() + 1).padStart(2, "0");
  return `${year}-${month}`;
};

// ─────────────────────────────────────────────
// 1. Home Dashboard
// ─────────────────────────────────────────────

/**
 * Returns platform-wide summary counts for the home dashboard.
 * All queries run in parallel via Promise.all() for performance.
 *
 * @returns {Promise<Object>} - Aggregated platform stats
 */
const getHomeDashboard = async () => {
  const [
    totalUsers,
    totalEquipment,
    availableEquipment,
    requestedEquipment,
    donatedEquipment,
    unavailableEquipment,
    totalDonations,
    totalRequests,
    totalHospitals,
    totalNotifications,
  ] = await Promise.all([
    prisma.user.count(),
    prisma.equipment.count(),
    prisma.equipment.count({ where: { status: "AVAILABLE" } }),
    prisma.equipment.count({ where: { status: "REQUESTED" } }),
    prisma.equipment.count({ where: { status: "DONATED" } }),
    prisma.equipment.count({ where: { status: "UNAVAILABLE" } }),
    prisma.donation.count(),
    prisma.request.count(),
    prisma.hospital.count(),
    prisma.notification.count(),
  ]);

  return {
    totalUsers,
    totalEquipment,
    equipment: {
      available: availableEquipment,
      requested: requestedEquipment,
      donated: donatedEquipment,
      unavailable: unavailableEquipment,
    },
    totalDonations,
    totalRequests,
    totalHospitals,
    totalNotifications,
  };
};

// ─────────────────────────────────────────────
// 2. User Dashboard
// ─────────────────────────────────────────────

/**
 * Returns personalized stats for the logged-in user.
 *
 * @param {string} userId - Authenticated user ID
 * @returns {Promise<Object>} - User-specific counts and summaries
 */
const getUserDashboard = async (userId) => {
  const [
    myEquipment,
    myDonations,
    myRequests,
    pendingRequests,
    completedDonations,
    unreadNotifications,
  ] = await Promise.all([
    // Equipment listed by this user
    prisma.equipment.count({ where: { ownerId: userId } }),

    // Donations made by this user
    prisma.donation.count({ where: { donorId: userId } }),

    // Requests made by this user
    prisma.request.count({ where: { requesterId: userId } }),

    // Pending requests for this user's equipment (received requests)
    prisma.request.count({
      where: {
        equipment: { ownerId: userId },
        status: "PENDING",
      },
    }),

    // Completed donations by this user
    prisma.donation.count({
      where: { donorId: userId, status: "COMPLETED" },
    }),

    // Unread notifications for this user
    prisma.notification.count({
      where: { userId, isRead: false },
    }),
  ]);

  return {
    myEquipment,
    myDonations,
    myRequests,
    pendingRequests,
    completedDonations,
    unreadNotifications,
  };
};

// ─────────────────────────────────────────────
// 3. Admin Dashboard
// ─────────────────────────────────────────────

/**
 * Returns full administrative statistics.
 * Only accessible by ADMIN role users.
 *
 * @returns {Promise<Object>} - Admin-level system statistics
 */
const getAdminDashboard = async () => {
  // Last 30 days threshold for "active users"
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

  const [
    totalUsers,
    totalEquipment,
    totalDonations,
    totalRequests,
    totalHospitals,
    activeUsers,
    pendingDonations,
    pendingRequests,
    completedDonations,
    completedRequests,
    usersByRole,
  ] = await Promise.all([
    prisma.user.count(),
    prisma.equipment.count(),
    prisma.donation.count(),
    prisma.request.count(),
    prisma.hospital.count(),

    // Active users: created account in last 30 days
    prisma.user.count({
      where: { createdAt: { gte: thirtyDaysAgo } },
    }),

    prisma.donation.count({ where: { status: "PENDING" } }),
    prisma.request.count({ where: { status: "PENDING" } }),
    prisma.donation.count({ where: { status: "COMPLETED" } }),
    prisma.request.count({ where: { status: "COMPLETED" } }),

    // Users grouped by role
    prisma.user.groupBy({
      by: ["role"],
      _count: { role: true },
    }),
  ]);

  // Transform usersByRole into a cleaner object
  const userRoleBreakdown = usersByRole.reduce((acc, item) => {
    acc[item.role] = item._count.role;
    return acc;
  }, {});

  return {
    totalUsers,
    totalEquipment,
    totalDonations,
    totalRequests,
    totalHospitals,
    activeUsers,
    pending: {
      donations: pendingDonations,
      requests: pendingRequests,
    },
    completed: {
      donations: completedDonations,
      requests: completedRequests,
    },
    usersByRole: userRoleBreakdown,
  };
};

// ─────────────────────────────────────────────
// 4. Monthly Statistics (Last 12 Months)
// ─────────────────────────────────────────────

/**
 * Returns monthly counts for equipment, donations, requests,
 * and new users for the past 12 months.
 *
 * Uses Prisma groupBy on createdAt truncated to month using
 * raw date filtering across multiple models in parallel.
 *
 * @returns {Promise<Object>} - Monthly data arrays (12 entries each)
 */
const getMonthlyStatistics = async () => {
  const twelveMonthsAgo = monthsAgo(12);

  // Run all four monthly groupBy queries in parallel
  const [equipment, donations, requests, users] = await Promise.all([
    prisma.equipment.findMany({
      where: { createdAt: { gte: twelveMonthsAgo } },
      select: { createdAt: true },
      orderBy: { createdAt: "asc" },
    }),
    prisma.donation.findMany({
      where: { createdAt: { gte: twelveMonthsAgo } },
      select: { createdAt: true },
      orderBy: { createdAt: "asc" },
    }),
    prisma.request.findMany({
      where: { createdAt: { gte: twelveMonthsAgo } },
      select: { createdAt: true },
      orderBy: { createdAt: "asc" },
    }),
    prisma.user.findMany({
      where: { createdAt: { gte: twelveMonthsAgo } },
      select: { createdAt: true },
      orderBy: { createdAt: "asc" },
    }),
  ]);

  /**
   * Groups an array of { createdAt } objects by "YYYY-MM" month label
   * and returns a sorted array of { month, count } objects.
   *
   * @param {Array<{createdAt: Date}>} records
   * @returns {Array<{month: string, count: number}>}
   */
  const groupByMonth = (records) => {
    const map = {};
    records.forEach((r) => {
      const label = toMonthLabel(r.createdAt);
      map[label] = (map[label] || 0) + 1;
    });
    return Object.entries(map)
      .map(([month, count]) => ({ month, count }))
      .sort((a, b) => a.month.localeCompare(b.month));
  };

  return {
    equipment: groupByMonth(equipment),
    donations: groupByMonth(donations),
    requests: groupByMonth(requests),
    newUsers: groupByMonth(users),
  };
};

// ─────────────────────────────────────────────
// 5. Category Statistics
// ─────────────────────────────────────────────

/**
 * Returns equipment count grouped by category.
 * Useful for pie charts on the dashboard.
 *
 * @returns {Promise<Array<{category: string, count: number}>>}
 */
const getCategoryStatistics = async () => {
  const grouped = await prisma.equipment.groupBy({
    by: ["category"],
    _count: { category: true },
    orderBy: { _count: { category: "desc" } },
  });

  return grouped.map((item) => ({
    category: item.category,
    count: item._count.category,
  }));
};

// ─────────────────────────────────────────────
// 6. Equipment Status Statistics
// ─────────────────────────────────────────────

/**
 * Returns equipment count for each status.
 * Useful for status-breakdown pie/donut charts.
 *
 * @returns {Promise<Object>} - Counts per status
 */
const getEquipmentStatusStats = async () => {
  const grouped = await prisma.equipment.groupBy({
    by: ["status"],
    _count: { status: true },
  });

  // Build a predictable object with all statuses defaulting to 0
  const result = {
    AVAILABLE: 0,
    REQUESTED: 0,
    DONATED: 0,
    UNAVAILABLE: 0,
  };

  grouped.forEach((item) => {
    result[item.status] = item._count.status;
  });

  return result;
};

// ─────────────────────────────────────────────
// 7. Donation Status Statistics
// ─────────────────────────────────────────────

/**
 * Returns donation count grouped by status.
 *
 * @returns {Promise<Object>} - Counts per donation status
 */
const getDonationStats = async () => {
  const grouped = await prisma.donation.groupBy({
    by: ["status"],
    _count: { status: true },
  });

  const result = {
    PENDING: 0,
    APPROVED: 0,
    COMPLETED: 0,
    CANCELLED: 0,
  };

  grouped.forEach((item) => {
    result[item.status] = item._count.status;
  });

  return result;
};

// ─────────────────────────────────────────────
// 8. Request Status Statistics
// ─────────────────────────────────────────────

/**
 * Returns request count grouped by status.
 *
 * @returns {Promise<Object>} - Counts per request status
 */
const getRequestStats = async () => {
  const grouped = await prisma.request.groupBy({
    by: ["status"],
    _count: { status: true },
  });

  const result = {
    PENDING: 0,
    APPROVED: 0,
    REJECTED: 0,
    COMPLETED: 0,
    CANCELLED: 0,
  };

  grouped.forEach((item) => {
    result[item.status] = item._count.status;
  });

  return result;
};

// ─────────────────────────────────────────────
// 9. Recent Activities
// ─────────────────────────────────────────────

/**
 * Returns the latest records across all major entities.
 * All queries run in parallel and return the 5 most recent items.
 *
 * @returns {Promise<Object>} - Recent equipment, donations, requests, notifications
 */
const getRecentActivities = async () => {
  const RECENT_LIMIT = 5;

  const [recentEquipment, recentDonations, recentRequests, recentNotifications] =
    await Promise.all([
      prisma.equipment.findMany({
        take: RECENT_LIMIT,
        orderBy: { createdAt: "desc" },
        select: {
          id: true,
          name: true,
          category: true,
          status: true,
          condition: true,
          createdAt: true,
          owner: { select: { id: true, name: true } },
        },
      }),

      prisma.donation.findMany({
        take: RECENT_LIMIT,
        orderBy: { createdAt: "desc" },
        select: {
          id: true,
          status: true,
          createdAt: true,
          equipment: { select: { id: true, name: true } },
          donor: { select: { id: true, name: true } },
        },
      }),

      prisma.request.findMany({
        take: RECENT_LIMIT,
        orderBy: { createdAt: "desc" },
        select: {
          id: true,
          status: true,
          reason: true,
          createdAt: true,
          equipment: { select: { id: true, name: true } },
          requester: { select: { id: true, name: true } },
        },
      }),

      prisma.notification.findMany({
        take: RECENT_LIMIT,
        orderBy: { createdAt: "desc" },
        select: {
          id: true,
          title: true,
          message: true,
          type: true,
          isRead: true,
          createdAt: true,
          user: { select: { id: true, name: true } },
        },
      }),
    ]);

  return {
    equipment: recentEquipment,
    donations: recentDonations,
    requests: recentRequests,
    notifications: recentNotifications,
  };
};

// ─────────────────────────────────────────────
// 10. Top Donors
// ─────────────────────────────────────────────

/**
 * Returns the top 10 users with the most completed donations.
 * Uses groupBy on donorId and counts donations per user.
 *
 * @returns {Promise<Array>} - Top 10 donors with their donation count
 */
const getTopDonors = async () => {
  const TOP_LIMIT = 10;

  // Group completed donations by donorId
  const grouped = await prisma.donation.groupBy({
    by: ["donorId"],
    where: { status: "COMPLETED" },
    _count: { donorId: true },
    orderBy: { _count: { donorId: "desc" } },
    take: TOP_LIMIT,
  });

  if (grouped.length === 0) return [];

  // Fetch user details for each donor in one query
  const donorIds = grouped.map((g) => g.donorId);
  const donors = await prisma.user.findMany({
    where: { id: { in: donorIds } },
    select: {
      id: true,
      name: true,
      email: true,
      profileImage: true,
      role: true,
    },
  });

  // Map donor details back with their donation count
  const donorMap = donors.reduce((acc, d) => {
    acc[d.id] = d;
    return acc;
  }, {});

  return grouped.map((g) => ({
    donor: donorMap[g.donorId] || null,
    donationCount: g._count.donorId,
  }));
};

// ─────────────────────────────────────────────
// 11. Top Requested Equipment
// ─────────────────────────────────────────────

/**
 * Returns the most requested equipment items.
 * Uses groupBy on equipmentId and counts requests per item.
 *
 * @returns {Promise<Array>} - Top 10 most requested equipment with request count
 */
const getTopRequestedEquipment = async () => {
  const TOP_LIMIT = 10;

  // Group all requests by equipmentId
  const grouped = await prisma.request.groupBy({
    by: ["equipmentId"],
    _count: { equipmentId: true },
    orderBy: { _count: { equipmentId: "desc" } },
    take: TOP_LIMIT,
  });

  if (grouped.length === 0) return [];

  // Fetch equipment details in one query
  const equipmentIds = grouped.map((g) => g.equipmentId);
  const equipmentList = await prisma.equipment.findMany({
    where: { id: { in: equipmentIds } },
    select: {
      id: true,
      name: true,
      category: true,
      status: true,
      condition: true,
      image: true,
      owner: { select: { id: true, name: true } },
    },
  });

  // Map equipment details back with their request count
  const equipmentMap = equipmentList.reduce((acc, e) => {
    acc[e.id] = e;
    return acc;
  }, {});

  return grouped.map((g) => ({
    equipment: equipmentMap[g.equipmentId] || null,
    requestCount: g._count.equipmentId,
  }));
};

// ─────────────────────────────────────────────
// Exports
// ─────────────────────────────────────────────

module.exports = {
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
};
