// ======================================================
// MediShare
// Equipment Location Routes
// ======================================================

const express = require("express");

const {
    getNearbyEquipment,
} = require("../controllers/equipmentLocation.controller");

const router = express.Router();

// GET /api/equipment/nearby
router.get("/nearby", getNearbyEquipment);

module.exports = router;