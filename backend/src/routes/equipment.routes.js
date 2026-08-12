const express = require("express");
const router = express.Router();

const {
  create,
  getAll,
  getById,
  update,
  remove,
} = require("../controllers/equipment.controller");

const {
  getNearbyEquipment,
} = require("../controllers/equipmentLocation.controller");

const protect = require("../middleware/auth.middleware");

// Public Routes
router.get("/", getAll);

// Location-based equipment
router.get("/nearby", getNearbyEquipment);

router.get("/:id", getById);

// Protected Routes
router.post("/", protect, create);
router.put("/:id", protect, update);
router.delete("/:id", protect, remove);

module.exports = router;