const express = require("express");
const router = express.Router();

const {
  createRequest,
  getAllRequests,
  getRequestById,
  updateRequestStatus,
  deleteRequest,
} = require("../controllers/request.controller");

const protect = require("../middleware/auth.middleware");

// Create Request
router.post("/", protect, createRequest);

// Get All Requests
router.get("/", protect, getAllRequests);

// Get Request By ID
router.get("/:id", protect, getRequestById);

// Update Request Status
router.patch("/:id/status", protect, updateRequestStatus);

// Delete Request
router.delete("/:id", protect, deleteRequest);

module.exports = router;