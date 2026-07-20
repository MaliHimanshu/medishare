const requestService = require("../services/request.service");
const {
  requestSchema,
  statusUpdateSchema,
  requestQuerySchema,
} = require("../validators/request.validator");

// Create Request
const createRequest = async (req, res) => {
  try {
    const data = requestSchema.parse(req.body);

    const request = await requestService.createRequest(req.user.id, data);

    return res.status(201).json({
      success: true,
      message: "Request created successfully.",
      data: request,
    });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

// Get All Requests
const getAllRequests = async (req, res) => {
  try {
    requestQuerySchema.parse(req.query);

    const requests = await requestService.getAllRequests();

    return res.status(200).json({
      success: true,
      count: requests.length,
      data: requests,
    });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

// Get Request By ID
const getRequestById = async (req, res) => {
  try {
    const request = await requestService.getRequestById(req.params.id);

    return res.status(200).json({
      success: true,
      data: request,
    });
  } catch (error) {
    return res.status(404).json({
      success: false,
      message: error.message,
    });
  }
};

// Update Request Status
const updateRequestStatus = async (req, res) => {
  try {
    const { status } = statusUpdateSchema.parse(req.body);

    const request = await requestService.updateRequestStatus(req.params.id, status);

    return res.status(200).json({
      success: true,
      message: "Request status updated successfully.",
      data: request,
    });
  } catch (error) {
    return res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

// Delete Request
const deleteRequest = async (req, res) => {
  try {
    const result = await requestService.deleteRequest(req.params.id);

    return res.status(200).json(result);
  } catch (error) {
    return res.status(404).json({
      success: false,
      message: error.message,
    });
  }
};

module.exports = {
  createRequest,
  getAllRequests,
  getRequestById,
  updateRequestStatus,
  deleteRequest,
};