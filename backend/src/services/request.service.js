const prisma = require("../config/prisma");

// Create Request
const createRequest = async (userId, data) => {
  const { equipmentId, reason } = data;

  // Check equipment exists
  const equipment = await prisma.equipment.findUnique({
    where: { id: equipmentId },
  });

  if (!equipment) {
    throw new Error("Equipment not found.");
  }

  // Equipment must be available
  if (equipment.status !== "AVAILABLE") {
    throw new Error("Equipment is not available.");
  }

  // Prevent owner from requesting own equipment
  if (equipment.ownerId === userId) {
    throw new Error("You cannot request your own equipment.");
  }

  // Prevent duplicate pending request
  const existingRequest = await prisma.request.findFirst({
    where: {
      equipmentId,
      requesterId: userId,
      status: "PENDING",
    },
  });

  if (existingRequest) {
    throw new Error("You already have a pending request for this equipment.");
  }

  // Create request
  const request = await prisma.request.create({
    data: {
      equipmentId,
      requesterId: userId,
      reason,
    },
    include: {
      requester: {
        select: {
          id: true,
          name: true,
          email: true,
        },
      },
      equipment: true,
    },
  });

  return request;
};

// Get All Requests
const getAllRequests = async () => {
  return prisma.request.findMany({
    include: {
      requester: {
        select: {
          id: true,
          name: true,
          email: true,
        },
      },
      equipment: true,
    },
    orderBy: {
      createdAt: "desc",
    },
  });
};

// Get Request By ID
const getRequestById = async (id) => {
  const request = await prisma.request.findUnique({
    where: { id },
    include: {
      requester: {
        select: {
          id: true,
          name: true,
          email: true,
        },
      },
      equipment: true,
    },
  });

  if (!request) {
    throw new Error("Request not found.");
  }

  return request;
};

// Update Request Status
const updateRequestStatus = async (id, status) => {
  const request = await prisma.request.findUnique({
    where: { id },
  });

  if (!request) {
    throw new Error("Request not found.");
  }

  return prisma.request.update({
    where: { id },
    data: { status },
  });
};

// Delete Request
const deleteRequest = async (id) => {
  const request = await prisma.request.findUnique({
    where: { id },
  });

  if (!request) {
    throw new Error("Request not found.");
  }

  await prisma.request.delete({
    where: { id },
  });

  return {
    success: true,
    message: "Request deleted successfully.",
  };
};

module.exports = {
  createRequest,
  getAllRequests,
  getRequestById,
  updateRequestStatus,
  deleteRequest,
};