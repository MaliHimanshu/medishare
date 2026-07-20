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

// Get All Donations
const getAllDonations = async () => {
  return prisma.donation.findMany({
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
const getDonationById = async (id) => {
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

  return donation;
};

// Update Donation Status
const updateDonationStatus = async (id, status) => {
  const donation = await prisma.donation.findUnique({
    where: { id },
  });

  if (!donation) {
    throw new Error("Donation not found.");
  }

  return prisma.donation.update({
    where: { id },
    data: { status },
  });
};

// Delete Donation
const deleteDonation = async (id) => {
  const donation = await prisma.donation.findUnique({
    where: { id },
  });

  if (!donation) {
    throw new Error("Donation not found.");
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