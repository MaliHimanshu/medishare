const prisma = require("../config/prisma");

// Create Donation
const createDonation = async (userId, data) => {
  const { equipmentId } = data;

  // Check equipment exists
  const equipment = await prisma.equipment.findUnique({
    where: { id: equipmentId },
  });

  if (!equipment) {
    throw new Error("Equipment not found.");
  }

  // Equipment must be available
  if (equipment.status !== "AVAILABLE") {
    throw new Error("Equipment is not available for donation.");
  }

  // Create donation
  const donation = await prisma.donation.create({
    data: {
      donorId: userId,
      equipmentId,
    },
    include: {
      donor: {
        select: {
          id: true,
          name: true,
          email: true,
        },
      },
      equipment: true,
    },
  });

  // Update equipment status
  await prisma.equipment.update({
    where: { id: equipmentId },
    data: {
      status: "DONATED",
    },
  });

  return donation;
};

// Get All Donations (scoped by role)
const getAllDonations = async (user) => {
  let where = {};
  if (user && user.role !== "ADMIN") {
    if (user.role === "DONOR") {
      where = { donorId: user.id };
    } else if (user.role === "HOSPITAL") {
      where = {
        OR: [
          { donorId: user.id },
          { equipment: { ownerId: user.id } },
        ],
      };
    } else if (user.role === "RECIPIENT") {
      // Recipients only see donations for equipment linked to requests they made
      where = {
        equipment: {
          requests: {
            some: {
              requesterId: user.id,
            },
          },
        },
      };
    }
    // NGOs can see all donations to facilitate distribution
  }

  return prisma.donation.findMany({
    where,
    include: {
      donor: {
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

// Get Donation By ID
const getDonationById = async (id, user) => {
  const donation = await prisma.donation.findUnique({
    where: { id },
    include: {
      donor: {
        select: {
          id: true,
          name: true,
          email: true,
        },
      },
      equipment: true,
    },
  });

  if (!donation) {
    throw new Error("Donation not found.");
  }

  if (user && user.role !== "ADMIN" && user.role !== "NGO") {
    const isDonor = donation.donorId === user.id;
    const isEquipmentOwner = donation.equipment && donation.equipment.ownerId === user.id;
    if (!isDonor && !isEquipmentOwner) {
      if (user.role === "RECIPIENT") {
        const hasRequest = await prisma.request.findFirst({
          where: {
            equipmentId: donation.equipmentId,
            requesterId: user.id,
          },
        });
        if (!hasRequest) {
          throw new Error("You are not authorized to view this donation.");
        }
      } else {
        throw new Error("You are not authorized to view this donation.");
      }
    }
  }

  return donation;
};

// Update Donation Status
const updateDonationStatus = async (id, status, user) => {
  const donation = await prisma.donation.findUnique({
    where: { id },
    include: {
      equipment: true,
    },
  });

  if (!donation) {
    throw new Error("Donation not found.");
  }

  if (user && user.role !== "ADMIN" && user.role !== "NGO") {
    const isDonor = donation.donorId === user.id;
    const isEquipmentOwner = donation.equipment && donation.equipment.ownerId === user.id;
    if (!isDonor && !isEquipmentOwner) {
      throw new Error("You are not authorized to update this donation.");
    }
  }

  return prisma.donation.update({
    where: { id },
    data: { status },
  });
};

// Delete Donation
const deleteDonation = async (id, user) => {
  const donation = await prisma.donation.findUnique({
    where: { id },
  });

  if (!donation) {
    throw new Error("Donation not found.");
  }

  if (user && user.role !== "ADMIN") {
    const isDonor = donation.donorId === user.id;
    if (!isDonor) {
      throw new Error("You are not authorized to delete this donation.");
    }
  }

  await prisma.equipment.update({
    where: {
      id: donation.equipmentId,
    },
    data: {
      status: "AVAILABLE",
    },
  });

  await prisma.donation.delete({
    where: { id },
  });

  return {
    success: true,
    message: "Donation deleted successfully.",
  };
};

module.exports = {
  createDonation,
  getAllDonations,
  getDonationById,
  updateDonationStatus,
  deleteDonation,
};