const express = require("express");

const router = express.Router();

const protect = require("../middleware/auth.middleware");

const {
  createHospital,
  getAllHospitals,
  getHospitalById,
  updateHospital,
  deleteHospital,
} = require("../controllers/hospital.controller");

// Create Hospital
router.post("/", protect, createHospital);

// Get All Hospitals
router.get("/", protect, getAllHospitals);

// Get Hospital By ID
router.get("/:id", protect, getHospitalById);

// Update Hospital
router.put("/:id", protect, updateHospital);

// Delete Hospital
router.delete("/:id", protect, deleteHospital);

module.exports = router;