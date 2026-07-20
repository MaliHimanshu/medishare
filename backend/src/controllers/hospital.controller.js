const {
  hospitalSchema,
  hospitalQuerySchema,
} = require("../validators/hospital.validator");

const hospitalService = require("../services/hospital.service");

// Create Hospital
const createHospital = async (req, res) => {
  try {
    const data = hospitalSchema.parse(req.body);

    const hospital = await hospitalService.createHospital(data);

    return res.status(201).json({
      success: true,
      message: "Hospital created successfully.",
      data: hospital,
    });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

// Get All Hospitals
const getAllHospitals = async (req, res) => {
  try {
    const query = hospitalQuerySchema.parse(req.query);

    const hospitals = await hospitalService.getAllHospitals(query);

    return res.status(200).json({
      success: true,
      ...hospitals,
    });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

// Get Hospital By ID
const getHospitalById = async (req, res) => {
  try {
    const hospital = await hospitalService.getHospitalById(req.params.id);

    return res.status(200).json({
      success: true,
      data: hospital,
    });
  } catch (error) {
    return res.status(404).json({
      success: false,
      message: error.message,
    });
  }
};

// Update Hospital
const updateHospital = async (req, res) => {
  try {
    const data = hospitalSchema.partial().parse(req.body);

    const hospital = await hospitalService.updateHospital(
      req.params.id,
      data
    );

    return res.status(200).json({
      success: true,
      message: "Hospital updated successfully.",
      data: hospital,
    });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

// Delete Hospital
const deleteHospital = async (req, res) => {
  try {
    const result = await hospitalService.deleteHospital(req.params.id);

    return res.status(200).json(result);
  } catch (error) {
    return res.status(404).json({
      success: false,
      message: error.message,
    });
  }
};

module.exports = {
  createHospital,
  getAllHospitals,
  getHospitalById,
  updateHospital,
  deleteHospital,
};