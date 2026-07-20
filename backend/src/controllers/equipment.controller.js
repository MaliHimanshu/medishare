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

/**
 * POST /api/equipment
 */
const create = async (req, res, next) => {
  try {
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
      data: equipment,
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
    const equipment = await getAllEquipment();

    return res.status(200).json({
      success: true,
      count: equipment.length,
      data: equipment,
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
      data: equipment,
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
      data: equipment,
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