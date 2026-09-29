/**
 * Emergency Alert Validator
 * -------------------------
 * File: src/validators/emergencyAlert.validator.js
 *
 * Validates payloads for emergency equipment alerts and NGO responses.
 */

const { z } = require("zod");

const createEmergencyAlertSchema = z.object({
  equipmentName: z
    .string({ required_error: "Equipment name is required" })
    .trim()
    .min(2, "Equipment name must be at least 2 characters")
    .max(100, "Equipment name must be at most 100 characters"),

  equipmentCategory: z.string().trim().max(100).optional().nullable(),

  quantityRequired: z
    .number({ required_error: "Quantity required is required" })
    .int("Quantity must be an integer")
    .positive("Quantity must be greater than 0"),

  priority: z
    .enum(["NORMAL", "HIGH", "CRITICAL"], {
      invalid_type_error: "Priority must be NORMAL, HIGH, or CRITICAL",
    })
    .default("HIGH"),

  description: z.string().trim().max(1000).optional().nullable(),

  address: z.string().trim().max(255).optional().nullable(),

  latitude: z.number().min(-90).max(90).optional().nullable(),

  longitude: z.number().min(-180).max(180).optional().nullable(),

  expiresAt: z
    .string()
    .datetime({ message: "Invalid ISO date string for expiresAt" })
    .optional()
    .nullable(),
});

const updateAlertStatusSchema = z.object({
  status: z.enum(
    ["ACTIVE", "PARTIALLY_FULFILLED", "FULFILLED", "CANCELLED", "EXPIRED"],
    {
      required_error: "Status is required",
      invalid_type_error:
        "Status must be ACTIVE, PARTIALLY_FULFILLED, FULFILLED, CANCELLED, or EXPIRED",
    }
  ),
});

const respondEmergencyAlertSchema = z.object({
  quantityAvailable: z
    .number({ required_error: "Quantity available is required" })
    .int("Quantity must be an integer")
    .positive("Quantity available must be greater than 0"),

  message: z.string().trim().max(500).optional().nullable(),
});

const updateEmergencyResponseSchema = z.object({
  quantityAvailable: z
    .number()
    .int("Quantity must be an integer")
    .positive("Quantity available must be greater than 0")
    .optional(),

  message: z.string().trim().max(500).optional().nullable(),

  status: z
    .enum(["OFFERED", "ACCEPTED", "REJECTED", "CANCELLED"], {
      invalid_type_error: "Status must be OFFERED, ACCEPTED, REJECTED, or CANCELLED",
    })
    .optional(),
});

module.exports = {
  createEmergencyAlertSchema,
  updateAlertStatusSchema,
  respondEmergencyAlertSchema,
  updateEmergencyResponseSchema,
};
