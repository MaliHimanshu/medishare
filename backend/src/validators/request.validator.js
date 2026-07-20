const { z } = require("zod");

// Create Request
const requestSchema = z.object({
  equipmentId: z
    .string({
      required_error: "Equipment ID is required.",
    })
    .min(1, "Equipment ID cannot be empty."),

  reason: z
    .string()
    .trim()
    .min(5, "Reason must be at least 5 characters.")
    .max(500, "Reason cannot exceed 500 characters.")
    .optional(),
});

// Update Status
const statusUpdateSchema = z.object({
  status: z.enum([
    "PENDING",
    "APPROVED",
    "REJECTED",
    "COMPLETED",
    "CANCELLED",
  ]),
});

// Query Parameters
const requestQuerySchema = z.object({
  page: z
    .string()
    .optional()
    .transform((val) => (val ? parseInt(val, 10) : 1))
    .pipe(z.number().min(1)),

  limit: z
    .string()
    .optional()
    .transform((val) => (val ? parseInt(val, 10) : 10))
    .pipe(z.number().min(1).max(100)),

  status: z
    .enum([
      "PENDING",
      "APPROVED",
      "REJECTED",
      "COMPLETED",
      "CANCELLED",
    ])
    .optional(),

  search: z.string().trim().optional(),
});

module.exports = {
  requestSchema,
  statusUpdateSchema,
  requestQuerySchema,
};