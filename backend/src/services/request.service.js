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

// Get All Requests (scoped by role)
const getAllRequests = async (user) => {
  let where = {};
  if (user && user.role !== "ADMIN") {
    if (user.role === "DONOR") {
      // Donors see requests for equipment they own
      where = { equipment: { ownerId: user.id } };
    } else if (user.role === "RECIPIENT") {
      // Recipients see requests they submitted
      where = { requesterId: user.id };
    } else if (user.role === "HOSPITAL") {
      // Hospitals see requests for their own equipment or requests they submitted
      where = {
        OR: [
          { equipment: { ownerId: user.id } },
          { requesterId: user.id },
        ],
      };
    } else if (user.role === "NGO") {
      // NGOs see requests they submitted or for equipment they coordinate
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
const getRequestById = async (id, user) => {
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

  if (user && user.role !== "ADMIN") {
    const isOwner = request.equipment.ownerId === user.id;
    const isRequester = request.requesterId === user.id;
    if (!isOwner && !isRequester) {
      throw new Error("You are not authorized to view this request.");
    }
  }

  return request;
};

// Update Request Status
const updateRequestStatus = async (id, status, user) => {
  const request = await prisma.request.findUnique({
    where: { id },
    include: {
      equipment: true,
      requester: true,
    },
  });

  if (!request) {
    throw new Error("Request not found.");
  }

  if (user && user.role !== "ADMIN") {
    const isOwner = request.equipment.ownerId === user.id;
    const isRequester = request.requesterId === user.id;

    if (!isOwner && !isRequester) {
      throw new Error("You are not authorized to update this request.");
    }

    // Only the equipment owner (or admin) can APPROVE or REJECT
    // The requester can only CANCEL
    if (isRequester && !isOwner) {
      if (status !== "CANCELLED") {
        throw new Error("Requesters can only cancel their pending requests.");
      }
    }
  }

  return prisma.request.update({
    where: { id },
    data: { status },
  });
};

// Delete Request
const deleteRequest = async (id, user) => {
  const request = await prisma.request.findUnique({
    where: { id },
  });

  if (!request) {
    throw new Error("Request not found.");
  }

  if (user && user.role !== "ADMIN") {
    if (request.requesterId !== user.id) {
      throw new Error("You are not authorized to delete this request.");
    }
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