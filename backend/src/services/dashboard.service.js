const prisma = require("../config/prisma");

// Dashboard Summary
const getDashboardSummary = async (user) => {
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

  // Compute role-tailored statistics
  let roleStats = {};

  if (user) {
    if (user.role === "DONOR") {
      const [myEquipment, rentalRequests, activeRentals, myDonations] =
        await Promise.all([
          prisma.equipment.count({ where: { ownerId: user.id } }),
          prisma.rental.count({
            where: { equipment: { ownerId: user.id }, status: "PENDING" },
          }),
          prisma.rental.count({
            where: { equipment: { ownerId: user.id }, status: "ACTIVE" },
          }),
          prisma.donation.count({ where: { donorId: user.id } }),
        ]);

      roleStats = {
        myEquipment,
        rentalRequests,
        activeRentals,
        donations: myDonations,
      };
    } else if (user.role === "RECIPIENT") {
      const [activeRentals, myRequests] = await Promise.all([
        prisma.rental.count({
          where: { renterId: user.id, status: "ACTIVE" },
        }),
        prisma.request.count({ where: { requesterId: user.id } }),
      ]);

      roleStats = {
        availableNearby: availableEquipment,
        activeRental: activeRentals,
        activeRentals,
        myRequests,
      };
    } else if (user.role === "NGO") {
      const [beneficiaries, pendingReqs, myRequests] = await Promise.all([
        prisma.user.count({ where: { role: "RECIPIENT" } }),
        prisma.request.count({ where: { status: "PENDING" } }),
        prisma.request.count({ where: { requesterId: user.id } }),
      ]);

      roleStats = {
        availableEquipment,
        pendingRequests: pendingReqs,
        donations: completedDonations,
        beneficiaries,
        activeRequests: myRequests,
      };
    } else if (user.role === "HOSPITAL") {
      const [hospitalEquipment, equipmentRequests, activeRentals] =
        await Promise.all([
          prisma.equipment.count({ where: { ownerId: user.id } }),
          prisma.request.count({
            where: { equipment: { ownerId: user.id } },
          }),
          prisma.rental.count({
            where: {
              OR: [
                { equipment: { ownerId: user.id } },
                { renterId: user.id },
              ],
              status: "ACTIVE",
            },
          }),
        ]);

      roleStats = {
        hospitalEquipment,
        equipmentRequests,
        activeRentals,
        availableEquipment,
      };
    }
  }

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
    role: user?.role ?? "DONOR",
    ...roleStats,
    roleStats,
  };
};

// Recent Requests (scoped by role)
const getRecentRequests = async (user) => {
  let where = {};
  if (user && user.role !== "ADMIN") {
    if (user.role === "DONOR") {
      where = { equipment: { ownerId: user.id } };
    } else if (user.role === "RECIPIENT") {
      where = { requesterId: user.id };
    } else if (user.role === "HOSPITAL") {
      where = {
        OR: [
          { equipment: { ownerId: user.id } },
          { requesterId: user.id },
        ],
      };
    }
  }

  return prisma.request.findMany({
    where,
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