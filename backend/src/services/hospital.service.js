const prisma = require("../config/prisma");

// Create Hospital
const createHospital = async (data) => {
  const existingHospital = await prisma.hospital.findUnique({
    where: {
      email: data.email || undefined,
    },
  });

  if (data.email && existingHospital) {
    throw new Error("Hospital with this email already exists.");
  }

  return prisma.hospital.create({
    data,
  });
};

// Get All Hospitals
const getAllHospitals = async (query) => {
  const {
    page = 1,
    limit = 10,
    city,
    state,
    search,
  } = query;

  const where = {};

  if (city) {
    where.city = {
      contains: city,
      mode: "insensitive",
    };
  }

  if (state) {
    where.state = {
      contains: state,
      mode: "insensitive",
    };
  }

  if (search) {
    where.OR = [
      {
        hospitalName: {
          contains: search,
          mode: "insensitive",
        },
      },
      {
        city: {
          contains: search,
          mode: "insensitive",
        },
      },
    ];
  }

  const hospitals = await prisma.hospital.findMany({
    where,
    skip: (page - 1) * limit,
    take: limit,
    orderBy: {
      createdAt: "desc",
    },
  });

  const total = await prisma.hospital.count({ where });

  return {
    total,
    page,
    limit,
    hospitals,
  };
};

// Get Hospital By ID
const getHospitalById = async (id) => {
  const hospital = await prisma.hospital.findUnique({
    where: { id },
  });

  if (!hospital) {
    throw new Error("Hospital not found.");
  }

  return hospital;
};

// Update Hospital
const updateHospital = async (id, data) => {
  const hospital = await prisma.hospital.findUnique({
    where: { id },
  });

  if (!hospital) {
    throw new Error("Hospital not found.");
  }

  return prisma.hospital.update({
    where: { id },
    data,
  });
};

// Delete Hospital
const deleteHospital = async (id) => {
  const hospital = await prisma.hospital.findUnique({
    where: { id },
  });

  if (!hospital) {
    throw new Error("Hospital not found.");
  }

  await prisma.hospital.delete({
    where: { id },
  });

  return {
    success: true,
    message: "Hospital deleted successfully.",
  };
};

module.exports = {
  createHospital,
  getAllHospitals,
  getHospitalById,
  updateHospital,
  deleteHospital,
};