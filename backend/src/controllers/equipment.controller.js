const {
  createEquipment,
  getAllEquipment,
  getEquipmentById,
  updateEquipment,
  deleteEquipment,
} = require("../services/equipment.service");

const {
  createEquipmentSchema,
  updateEquipmentSchema,
} = require("../validators/equipment.validator");

const mapEquipmentPrices = (eq) => {
  if (!eq) return eq;
  return {
    ...eq,
    rentalPricePerDay: eq.rentalPricePerDay != null ? Number(eq.rentalPricePerDay) : null,
    securityDeposit: eq.securityDeposit != null ? Number(eq.securityDeposit) : null,
  };
};

/**
 * POST /api/equipment
 */
const create = async (req, res, next) => {
  try {
    if (req.user.role === "RECIPIENT") {
      return res.status(403).json({
        success: false,
        message: "Recipients are not authorized to create equipment listings.",
      });
    }

    const validatedData = createEquipmentSchema.parse({
      body: req.body,
    });

    const equipment = await createEquipment(
      req.user.id,
      validatedData.body
    );

    return res.status(201).json({
      success: true,
      message: "Equipment created successfully.",
      data: mapEquipmentPrices(equipment),
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/equipment
 */
const getAll = async (req, res, next) => {
  try {
    const equipment = await getAllEquipment(req.query);

    return res.status(200).json({
      success: true,
      count: equipment.length,
      data: equipment.map(mapEquipmentPrices),
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/equipment/:id
 */
const getById = async (req, res, next) => {
  try {
    const equipment = await getEquipmentById(req.params.id);

    if (!equipment) {
      return res.status(404).json({
        success: false,
        message: "Equipment not found.",
      });
    }

    return res.status(200).json({
      success: true,
      data: mapEquipmentPrices(equipment),
    });
  } catch (error) {
    next(error);
  }
};

/**
 * PUT /api/equipment/:id
 */
const update = async (req, res, next) => {
  try {
    const existing = await getEquipmentById(req.params.id);
    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Equipment not found.",
      });
    }

    if (existing.ownerId !== req.user.id && req.user.role !== "ADMIN") {
      return res.status(403).json({
        success: false,
        message: "You are not authorized to edit this equipment.",
      });
    }

    const validatedData = updateEquipmentSchema.parse({
      body: req.body,
    });

    const equipment = await updateEquipment(
      req.params.id,
      validatedData.body
    );

    return res.status(200).json({
      success: true,
      message: "Equipment updated successfully.",
      data: mapEquipmentPrices(equipment),
    });
  } catch (error) {
    next(error);
  }
};

/**
 * DELETE /api/equipment/:id
 */
const remove = async (req, res, next) => {
  try {
    const existing = await getEquipmentById(req.params.id);
    if (!existing) {
      return res.status(404).json({
        success: false,
        message: "Equipment not found.",
      });
    }

    if (existing.ownerId !== req.user.id && req.user.role !== "ADMIN") {
      return res.status(403).json({
        success: false,
        message: "You are not authorized to delete this equipment.",
      });
    }

    await deleteEquipment(req.params.id);

    return res.status(200).json({
      success: true,
      message: "Equipment deleted successfully.",
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  create,
  getAll,
  getById,
  update,
  remove,
};