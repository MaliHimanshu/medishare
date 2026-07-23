const prisma = require("../config/prisma");

// Dashboard Summary
const getDashboardSummary = async () => {
  const [
    totalUsers,
    totalEquipment,
    availableEquipment,
    totalRequests,
    pendingRequests,
    approvedRequests,
    completedDonations,
    totalHospitals,
    totalNotifications,
  ] = await Promise.all([
    prisma.user.count(),

    prisma.equipment.count(),

    prisma.equipment.count({
      where: {
        status: "AVAILABLE",
      },
    }),

    prisma.request.count(),

    prisma.request.count({
      where: {
        status: "PENDING",
      },
    }),

    prisma.request.count({
      where: {
        status: "APPROVED",
      },
    }),

    prisma.donation.count({
      where: {
        status: "COMPLETED",
      },
    }),

    prisma.hospital.count(),

    prisma.notification.count(),
  ]);

  return {
    totalUsers,
    totalEquipment,
    availableEquipment,
    totalRequests,
    pendingRequests,
    approvedRequests,
    completedDonations,
    totalHospitals,
    totalNotifications,
  };
};

// Recent Requests
const getRecentRequests = async () => {
  return prisma.request.findMany({
    take: 5,
    orderBy: {
      createdAt: "desc",
    },
    include: {
      requester: {
        select: {
          id: true,
          name: true,
          email: true,
        },
      },
      equipment: {
        select: {
          id: true,
          name: true,
          status: true,
        },
      },
    },
  });
};

// Recent Donations
const getRecentDonations = async () => {
  return prisma.donation.findMany({
    take: 5,
    orderBy: {
      createdAt: "desc",
    },
    include: {
      donor: {
        select: {
          id: true,
          name: true,
          email: true,
        },
      },
      equipment: {
        select: {
          id: true,
          name: true,
        },
      },
    },
  });
};

// Recent Notifications
const getRecentNotifications = async () => {
  return prisma.notification.findMany({
    take: 5,
    orderBy: {
      createdAt: "desc",
    },
    include: {
      user: {
        select: {
          id: true,
          name: true,
          email: true,
        },
      },
    },
  });
};

module.exports = {
  getDashboardSummary,
  getRecentRequests,
  getRecentDonations,
  getRecentNotifications,
};