const { z } = require("zod");

// Create Rental
const rentalSchema = z.object({
  equipmentId: z
    .string({
      required_error: "Equipment ID is required.",
    })
    .min(1, "Equipment ID cannot be empty."),

  startDate: z
    .string({
      required_error: "Start date is required.",
    })
    .refine((val) => !isNaN(Date.parse(val)), {
      message: "Invalid start date format.",
    }),

  endDate: z
    .string({
      required_error: "End date is required.",
    })
    .refine((val) => !isNaN(Date.parse(val)), {
      message: "Invalid end date format.",
    }),
});

// Update Rental Status
const rentalStatusUpdateSchema = z.object({
  status: z.enum(
    ["PENDING", "APPROVED", "ACTIVE", "RETURNED", "CANCELLED", "REJECTED"],
    {
      required_error: "Status is required.",
      invalid_type_error:
        "Status must be one of: PENDING, APPROVED, ACTIVE, RETURNED, CANCELLED, REJECTED",
    }
  ),
});

// Query Parameters
const rentalQuerySchema = z.object({
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
    .enum(["PENDING", "APPROVED", "ACTIVE", "RETURNED", "CANCELLED", "REJECTED"])
    .optional(),

  search: z.string().trim().optional(),
});

// Verify Razorpay Payment
const verifyPaymentSchema = z.object({
  razorpayOrderId: z
    .string({
      required_error: "Razorpay Order ID is required.",
    })
    .min(1, "Razorpay Order ID cannot be empty."),

  razorpayPaymentId: z
    .string({
      required_error: "Razorpay Payment ID is required.",
    })
    .min(1, "Razorpay Payment ID cannot be empty."),

  razorpaySignature: z
    .string({
      required_error: "Razorpay Signature is required.",
    })
    .min(1, "Razorpay Signature cannot be empty."),
});

module.exports = {
  rentalSchema,
  rentalStatusUpdateSchema,
  rentalQuerySchema,
  verifyPaymentSchema,
};
