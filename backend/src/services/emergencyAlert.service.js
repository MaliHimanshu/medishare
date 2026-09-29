/**
 * Emergency Alert Service
 * -----------------------
 * File: src/services/emergencyAlert.service.js
 *
 * Handles emergency medical equipment alerts created by hospitals
 * and responses from eligible NGOs.
 */

const prisma = require("../config/prisma");
const {
  notifyNgosOfEmergency,
  notifyHospitalOfResponse,
} = require("./pushNotification.service");

/**
 * Identifies eligible NGOs for targeting
 * Phase-1 modular implementation:
 * - Selects all verified active NGOs
 * - Prioritizes NGOs with matching equipmentPreference or category
 * - Extensible for geographic radius calculation
 */
const findEligibleNgos = async ({ equipmentName, equipmentCategory, latitude, longitude }) => {
  const allNgos = await prisma.user.findMany({
    where: {
      role: "NGO",
    },
    select: {
      id: true,
      name: true,
      email: true,
      phone: true,
      address: true,
      organizationName: true,
      equipmentPreference: true,
      fcmToken: true,
    },
  });

  if (!allNgos || allNgos.length === 0) return [];

  const targetCategory = (equipmentCategory || "").toLowerCase().trim();
  const targetName = (equipmentName || "").toLowerCase().trim();

  // Sort/prioritize NGOs with matching preference if set
  return allNgos.sort((a, b) => {
    const prefA = (a.equipmentPreference || "").toLowerCase();
    const prefB = (b.equipmentPreference || "").toLowerCase();

    const matchA = targetCategory && prefA.includes(targetCategory) ? 1 : (targetName && prefA.includes(targetName) ? 1 : 0);
    const matchB = targetCategory && prefB.includes(targetCategory) ? 1 : (targetName && prefB.includes(targetName) ? 1 : 0);

    return matchB - matchA;
  });
};

/**
 * Create Emergency Alert (Hospital only)
 */
const createEmergencyAlert = async (hospitalUser, data, io) => {
  const expiresAt = data.expiresAt ? new Date(data.expiresAt) : null;

  const alert = await prisma.emergencyAlert.create({
    data: {
      hospitalId: hospitalUser.id,
      equipmentName: data.equipmentName.trim(),
      equipmentCategory: data.equipmentCategory ? data.equipmentCategory.trim() : null,
      quantityRequired: data.quantityRequired,
      description: data.description ? data.description.trim() : null,
      priority: data.priority || "HIGH",
      address: data.address ? data.address.trim() : hospitalUser.address || null,
      latitude: data.latitude || null,
      longitude: data.longitude || null,
      expiresAt,
      status: "ACTIVE",
    },
    include: {
      hospital: {
        select: {
          id: true,
          name: true,
          email: true,
          phone: true,
          address: true,
          organizationName: true,
        },
      },
    },
  });

  // Find eligible NGOs
  const eligibleNgos = await findEligibleNgos({
    equipmentName: alert.equipmentName,
    equipmentCategory: alert.equipmentCategory,
    latitude: alert.latitude,
    longitude: alert.longitude,
  });

  // Trigger push, in-app DB notifications, and Socket.io broadcast
  await notifyNgosOfEmergency({
    alert,
    hospitalName: hospitalUser.organizationName || hospitalUser.name,
    targetNgos: eligibleNgos,
    io,
  });

  return {
    alert,
    notifiedCount: eligibleNgos.length,
  };
};

/**
 * Get Hospital's own emergency alerts
 */
const getHospitalAlerts = async (hospitalId) => {
  const alerts = await prisma.emergencyAlert.findMany({
    where: {
      hospitalId,
    },
    include: {
      responses: {
        select: {
          id: true,
          quantityAvailable: true,
          status: true,
        },
      },
      _count: {
        select: { responses: true },
      },
    },
    orderBy: {
      createdAt: "desc",
    },
  });

  // Calculate total available quantity and response counts
  return alerts.map((alert) => {
    const totalAvailable = alert.responses
      .filter((r) => r.status !== "CANCELLED" && r.status !== "REJECTED")
      .reduce((sum, r) => sum + r.quantityAvailable, 0);

    const { responses, ...alertWithoutResponses } = alert;
    return {
      ...alertWithoutResponses,
      responseCount: alert._count.responses,
      totalAvailable,
    };
  });
};

/**
 * Get Emergency Alert details
 */
const getAlertDetails = async (alertId, user) => {
  const alert = await prisma.emergencyAlert.findUnique({
    where: { id: alertId },
    include: {
      hospital: {
        select: {
          id: true,
          name: true,
          phone: true,
          address: true,
          organizationName: true,
        },
      },
      responses: {
        include: {
          ngo: {
            select: {
              id: true,
              name: true,
              organizationName: true,
              phone: true,
              address: true,
            },
          },
        },
        orderBy: {
          createdAt: "desc",
        },
      },
    },
  });

  if (!alert) {
    const error = new Error("Emergency alert not found.");
    error.statusCode = 404;
    throw error;
  }

  // Calculate total available across active responses
  const activeResponses = alert.responses.filter(
    (r) => r.status !== "CANCELLED" && r.status !== "REJECTED"
  );
  const totalAvailable = activeResponses.reduce(
    (sum, r) => sum + r.quantityAvailable,
    0
  );

  // If requesting user is the owning hospital or admin, return all responses
  if (user.role === "ADMIN" || user.id === alert.hospitalId) {
    return {
      ...alert,
      totalAvailable,
    };
  }

  // If requesting user is an NGO: return alert info plus only their own response
  const myResponse = alert.responses.find((r) => r.ngoId === user.id) || null;

  return {
    id: alert.id,
    hospitalId: alert.hospitalId,
    equipmentName: alert.equipmentName,
    equipmentCategory: alert.equipmentCategory,
    quantityRequired: alert.quantityRequired,
    description: alert.description,
    priority: alert.priority,
    status: alert.status,
    address: alert.address,
    latitude: alert.latitude,
    longitude: alert.longitude,
    expiresAt: alert.expiresAt,
    createdAt: alert.createdAt,
    updatedAt: alert.updatedAt,
    hospital: alert.hospital,
    totalAvailable,
    myResponse,
  };
};

/**
 * Update Emergency Alert Status (Hospital only)
 */
const updateAlertStatus = async (alertId, hospitalId, status, io) => {
  const alert = await prisma.emergencyAlert.findUnique({
    where: { id: alertId },
  });

  if (!alert) {
    const error = new Error("Emergency alert not found.");
    error.statusCode = 404;
    throw error;
  }

  if (alert.hospitalId !== hospitalId) {
    const error = new Error("You are not authorized to update this emergency alert.");
    error.statusCode = 403;
    throw error;
  }

  const updated = await prisma.emergencyAlert.update({
    where: { id: alertId },
    data: { status },
  });

  if (io) {
    io.emit("emergency:status_updated", {
      alertId: updated.id,
      status: updated.status,
    });
  }

  return updated;
};

/**
 * Get active alerts relevant to NGOs
 */
const getActiveAlertsForNgo = async (ngoId) => {
  const alerts = await prisma.emergencyAlert.findMany({
    where: {
      status: {
        in: ["ACTIVE", "PARTIALLY_FULFILLED"],
      },
      OR: [
        { expiresAt: null },
        { expiresAt: { gt: new Date() } },
      ],
    },
    include: {
      hospital: {
        select: {
          id: true,
          name: true,
          organizationName: true,
          address: true,
          phone: true,
        },
      },
      responses: {
        where: {
          ngoId,
        },
      },
      _count: {
        select: { responses: true },
      },
    },
    orderBy: [
      { priority: "desc" },
      { createdAt: "desc" },
    ],
  });

  return alerts.map((alert) => {
    const myResponse = alert.responses[0] || null;
    const { responses, ...alertData } = alert;
    return {
      ...alertData,
      responseCount: alert._count.responses,
      myResponse,
      hasResponded: Boolean(myResponse),
    };
  });
};

/**
 * Submit NGO Response with available quantity
 */
const respondToAlert = async (alertId, ngoUser, data, io) => {
  const alert = await prisma.emergencyAlert.findUnique({
    where: { id: alertId },
    include: {
      hospital: {
        select: {
          id: true,
          name: true,
          organizationName: true,
        },
      },
    },
  });

  if (!alert) {
    const error = new Error("Emergency alert not found.");
    error.statusCode = 404;
    throw error;
  }

  // Check if alert is still open
  if (alert.status === "CANCELLED" || alert.status === "FULFILLED" || alert.status === "EXPIRED") {
    const error = new Error("This emergency alert is no longer active.");
    error.statusCode = 400;
    throw error;
  }

  // Check expiration
  if (alert.expiresAt && new Date(alert.expiresAt) < new Date()) {
    await prisma.emergencyAlert.update({
      where: { id: alertId },
      data: { status: "EXPIRED" },
    });
    const error = new Error("This emergency alert has expired.");
    error.statusCode = 400;
    throw error;
  }

  // Check for duplicate response
  const existingResponse = await prisma.emergencyAlertResponse.findUnique({
    where: {
      emergencyAlertId_ngoId: {
        emergencyAlertId: alertId,
        ngoId: ngoUser.id,
      },
    },
  });

  if (existingResponse) {
    const error = new Error("You have already responded to this emergency alert.");
    error.statusCode = 409;
    throw error;
  }

  // Create Response
  const response = await prisma.emergencyAlertResponse.create({
    data: {
      emergencyAlertId: alertId,
      ngoId: ngoUser.id,
      quantityAvailable: data.quantityAvailable,
      message: data.message ? data.message.trim() : null,
      status: "OFFERED",
    },
    include: {
      ngo: {
        select: {
          id: true,
          name: true,
          organizationName: true,
          phone: true,
          address: true,
        },
      },
    },
  });

  // Calculate new total available
  const allResponses = await prisma.emergencyAlertResponse.findMany({
    where: {
      emergencyAlertId: alertId,
      status: { notIn: ["CANCELLED", "REJECTED"] },
    },
    select: { quantityAvailable: true },
  });

  const totalAvailable = allResponses.reduce(
    (sum, r) => sum + r.quantityAvailable,
    0
  );

  // Auto-progress status if needed
  let updatedStatus = alert.status;
  if (totalAvailable >= alert.quantityRequired) {
    updatedStatus = "FULFILLED";
  } else if (totalAvailable > 0 && alert.status === "ACTIVE") {
    updatedStatus = "PARTIALLY_FULFILLED";
  }

  if (updatedStatus !== alert.status) {
    await prisma.emergencyAlert.update({
      where: { id: alertId },
      data: { status: updatedStatus },
    });
  }

  // Notify requesting hospital
  await notifyHospitalOfResponse({
    alert,
    response,
    ngoName: ngoUser.organizationName || ngoUser.name,
    totalAvailable,
    io,
  });

  return {
    response,
    totalAvailable,
    alertStatus: updatedStatus,
  };
};

/**
 * Update NGO Response
 */
const updateNgoResponse = async (alertId, ngoId, data, io) => {
  const existingResponse = await prisma.emergencyAlertResponse.findUnique({
    where: {
      emergencyAlertId_ngoId: {
        emergencyAlertId: alertId,
        ngoId,
      },
    },
    include: {
      emergencyAlert: true,
      ngo: {
        select: {
          id: true,
          name: true,
          organizationName: true,
        },
      },
    },
  });

  if (!existingResponse) {
    const error = new Error("Response not found.");
    error.statusCode = 404;
    throw error;
  }

  if (existingResponse.emergencyAlert.status === "CANCELLED" || existingResponse.emergencyAlert.status === "EXPIRED") {
    const error = new Error("This emergency alert is no longer active.");
    error.statusCode = 400;
    throw error;
  }

  const updatedResponse = await prisma.emergencyAlertResponse.update({
    where: { id: existingResponse.id },
    data: {
      ...(data.quantityAvailable !== undefined ? { quantityAvailable: data.quantityAvailable } : {}),
      ...(data.message !== undefined ? { message: data.message ? data.message.trim() : null } : {}),
      ...(data.status ? { status: data.status } : {}),
    },
    include: {
      ngo: {
        select: {
          id: true,
          name: true,
          organizationName: true,
          phone: true,
        },
      },
    },
  });

  // Recalculate total available
  const allResponses = await prisma.emergencyAlertResponse.findMany({
    where: {
      emergencyAlertId: alertId,
      status: { notIn: ["CANCELLED", "REJECTED"] },
    },
    select: { quantityAvailable: true },
  });

  const totalAvailable = allResponses.reduce(
    (sum, r) => sum + r.quantityAvailable,
    0
  );

  let updatedStatus = existingResponse.emergencyAlert.status;
  if (totalAvailable >= existingResponse.emergencyAlert.quantityRequired) {
    updatedStatus = "FULFILLED";
  } else if (totalAvailable > 0) {
    updatedStatus = "PARTIALLY_FULFILLED";
  } else if (totalAvailable === 0 && updatedStatus !== "CANCELLED") {
    updatedStatus = "ACTIVE";
  }

  if (updatedStatus !== existingResponse.emergencyAlert.status) {
    await prisma.emergencyAlert.update({
      where: { id: alertId },
      data: { status: updatedStatus },
    });
  }

  return {
    response: updatedResponse,
    totalAvailable,
    alertStatus: updatedStatus,
  };
};

module.exports = {
  findEligibleNgos,
  createEmergencyAlert,
  getHospitalAlerts,
  getAlertDetails,
  updateAlertStatus,
  getActiveAlertsForNgo,
  respondToAlert,
  updateNgoResponse,
};
