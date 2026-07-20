const { z } = require("zod");

// Create Donation
const donationSchema = z.object({
  equipmentId: z
    .string({ required_error: "Equipment ID is required" })
    .min(1, "Equipment ID cannot be empty"),
});

// Update Donation Status
const statusUpdateSchema = z.object({
  status: z.enum(
    ["PENDING", "APPROVED", "COMPLETED", "CANCELLED"],
    {
      required_error: "Status is required",
      invalid_type_error:
        "Status must be one of: PENDING, APPROVED, COMPLETED, CANCELLED",
    }
  ),
});

// Query Parameters
const donationQuerySchema = z.object({
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

  search: z
    .string()
    .trim()
    .max(100)
    .optional(),

  status: z
    .enum(["PENDING", "APPROVED", "COMPLETED", "CANCELLED"])
    .optional(),
});

module.exports = {
  donationSchema,
  statusUpdateSchema,
  donationQuerySchema,
};