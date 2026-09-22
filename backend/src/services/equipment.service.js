const prisma = require("../config/prisma");

/**
 * Create Equipment
 */
const createEquipment = async (userId, data) => {
  const { location, ...rest } = data;
  return await prisma.equipment.create({
    data: {
      ...rest,
      address: rest.address || location || null,
      ownerId: userId,
    },
    include: {
      owner: {
        select: {
          id: true,
          name: true,
          role: true,
        },
      },
    },
  });
};

/**
 * Get All Equipment
 */
const getAllEquipment = async (filters = {}) => {
  const { search, category, status, mode, condition, location } = filters;
  const where = {};

  if (status && status !== "ALL" && status !== "All") {
    where.status = status;
  }
  if (category && category !== "ALL" && category !== "All") {
    where.category = { equals: category, mode: "insensitive" };
  }
  if (mode && mode !== "ALL" && mode !== "All") {
    where.mode = mode;
  }
  if (condition && condition !== "ALL" && condition !== "All") {
    where.condition = condition;
  }
  if (location && location.trim()) {
    where.address = { contains: location.trim(), mode: "insensitive" };
  }
  if (search && search.trim()) {
    const s = search.trim();
    where.OR = [
      { name: { contains: s, mode: "insensitive" } },
      { category: { contains: s, mode: "insensitive" } },
      { description: { contains: s, mode: "insensitive" } },
      { address: { contains: s, mode: "insensitive" } },
      { manufacturer: { contains: s, mode: "insensitive" } },
    ];
  }

  return await prisma.equipment.findMany({
    where,
    include: {
      owner: {
        select: {
          id: true,
          name: true,
          role: true,
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
          role: true,
        },
      },
    },
  });
};

/**
 * Update Equipment
 */
const updateEquipment = async (id, data) => {
  const { location, ...rest } = data;
  return await prisma.equipment.update({
    where: {
      id,
    },
    data: {
      ...rest,
      ...(location !== undefined && { address: location }),
    },
    include: {
      owner: {
        select: {
          id: true,
          name: true,
          role: true,
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