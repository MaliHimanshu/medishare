/**
 * API Response Utility
 * ---------------------
 * File: src/utils/apiResponse.js
 *
 * Provides standardized helper functions for sending consistent
 * HTTP responses across all controllers.
 *
 * All responses follow this contract:
 *
 * Success:
 * {
 *   "success": true,
 *   "message": "...",
 *   "data": {}
 * }
 *
 * Error:
 * {
 *   "success": false,
 *   "message": "...",
 *   "errors": []
 * }
 *
 * Pagination (optional):
 * {
 *   "success": true,
 *   "message": "...",
 *   "data": [],
 *   "pagination": {
 *     "total": 100,
 *     "page": 1,
 *     "limit": 10,
 *     "totalPages": 10
 *   }
 * }
 */

// ─────────────────────────────────────────────
// Success Response
// ─────────────────────────────────────────────

/**
 * Sends a standardized success response.
 *
 * @param {import('express').Response} res      - Express response object
 * @param {string}                    message   - Human-readable success message
 * @param {*}                         [data={}] - Response payload (object or array)
 * @param {number}                    [status=200] - HTTP status code
 */
const sendSuccess = (res, message, data = {}, status = 200) => {
  return res.status(status).json({
    success: true,
    message,
    data,
  });
};

// ─────────────────────────────────────────────
// Error Response
// ─────────────────────────────────────────────

/**
 * Sends a standardized error response.
 *
 * @param {import('express').Response} res         - Express response object
 * @param {string}                     message     - Human-readable error message
 * @param {number}                     [status=500] - HTTP status code
 * @param {Array}                      [errors=[]] - Detailed error list (e.g. Zod validation errors)
 */
const sendError = (res, message, status = 500, errors = []) => {
  return res.status(status).json({
    success: false,
    message,
    errors,
  });
};

// ─────────────────────────────────────────────
// Paginated Response
// ─────────────────────────────────────────────

/**
 * Sends a standardized paginated success response.
 *
 * @param {import('express').Response} res       - Express response object
 * @param {string}                     message   - Human-readable success message
 * @param {Array}                      data      - Array of result items
 * @param {Object}                     pagination - Pagination metadata
 * @param {number}                     pagination.total      - Total number of records
 * @param {number}                     pagination.page       - Current page number
 * @param {number}                     pagination.limit      - Items per page
 * @param {number}                     [status=200]          - HTTP status code
 */
const sendPaginated = (res, message, data, pagination, status = 200) => {
  const { total, page, limit } = pagination;

  return res.status(status).json({
    success: true,
    message,
    data,
    pagination: {
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
      hasNextPage: page < Math.ceil(total / limit),
      hasPrevPage: page > 1,
    },
  });
};

// ─────────────────────────────────────────────
// Created Response (201)
// ─────────────────────────────────────────────

/**
 * Sends a 201 Created success response.
 * Use this for POST routes that create new resources.
 *
 * @param {import('express').Response} res     - Express response object
 * @param {string}                     message - Success message
 * @param {*}                          [data={}] - Created resource data
 */
const sendCreated = (res, message, data = {}) => {
  return sendSuccess(res, message, data, 201);
};

// ─────────────────────────────────────────────
// No Content Response (204)
// ─────────────────────────────────────────────

/**
 * Sends a 204 No Content response.
 * Use this for DELETE routes where no body is needed.
 *
 * @param {import('express').Response} res - Express response object
 */
const sendNoContent = (res) => {
  return res.status(204).send();
};

// ─────────────────────────────────────────────
// Unauthorized Response (401)
// ─────────────────────────────────────────────

/**
 * Sends a 401 Unauthorized response.
 *
 * @param {import('express').Response} res       - Express response object
 * @param {string}                     [message] - Custom message
 */
const sendUnauthorized = (res, message = "Unauthorized. Please log in.") => {
  return sendError(res, message, 401);
};

// ─────────────────────────────────────────────
// Forbidden Response (403)
// ─────────────────────────────────────────────

/**
 * Sends a 403 Forbidden response.
 *
 * @param {import('express').Response} res       - Express response object
 * @param {string}                     [message] - Custom message
 */
const sendForbidden = (
  res,
  message = "Forbidden. You do not have permission to perform this action."
) => {
  return sendError(res, message, 403);
};

// ─────────────────────────────────────────────
// Not Found Response (404)
// ─────────────────────────────────────────────

/**
 * Sends a 404 Not Found response.
 *
 * @param {import('express').Response} res       - Express response object
 * @param {string}                     [message] - Custom message
 */
const sendNotFound = (res, message = "Resource not found.") => {
  return sendError(res, message, 404);
};

// ─────────────────────────────────────────────
// Validation Error Response (422)
// ─────────────────────────────────────────────

/**
 * Sends a 422 Unprocessable Entity response for validation errors.
 *
 * @param {import('express').Response} res    - Express response object
 * @param {string}                     message - Validation error summary
 * @param {Array}                      errors  - Array of field-level errors
 */
const sendValidationError = (res, message = "Validation failed.", errors = []) => {
  return sendError(res, message, 422, errors);
};

// ─────────────────────────────────────────────
// Exports
// ─────────────────────────────────────────────

module.exports = {
  sendSuccess,
  sendError,
  sendPaginated,
  sendCreated,
  sendNoContent,
  sendUnauthorized,
  sendForbidden,
  sendNotFound,
  sendValidationError,
};
