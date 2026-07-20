const { PrismaClient } = require("@prisma/client");

const prisma = new PrismaClient();

/**
 * Create Equipment
 */
const createEquipment = async (userId, data) => {
  return await prisma.equipment.create({
    data: {
      ...data,
      ownerId: userId,
    },
    include: {
      owner: {
        select: {
          id: true,
          name: true,
          email: true,
          role: true,
        },
      },
    },
  });
};

/**
 * Get All Equipment
 */
const getAllEquipment = async () => {
  return await prisma.equipment.findMany({
    include: {
      owner: {
        select: {
          id: true,
          name: true,
          email: true,
        },
      },
    },
    orderBy: {
      createdAt: "desc",
    },
  });
};

/**
 * Get Equipment By ID
 */
const getEquipmentById = async (id) => {
  return await prisma.equipment.findUnique({
    where: {
      id,
    },
    include: {
      owner: {
        select: {
          id: true,
          name: true,
          email: true,
        },
      },
    },
  });
};

/**
 * Update Equipment
 */
const updateEquipment = async (id, data) => {
  return await prisma.equipment.update({
    where: {
      id,
    },
    data,
    include: {
      owner: {
        select: {
          id: true,
          name: true,
          email: true,
        },
      },
    },
  });
};

/**
 * Delete Equipment
 */
const deleteEquipment = async (id) => {
  return await prisma.equipment.delete({
    where: {
      id,
    },
  });
};

module.exports = {
  createEquipment,
  getAllEquipment,
  getEquipmentById,
  updateEquipment,
  deleteEquipment,
};