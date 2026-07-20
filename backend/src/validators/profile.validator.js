/**
 * Profile Validator
 * ------------------
 * File: src/validators/profile.validator.js
 *
 * Defines Zod validation schemas for all profile-related routes.
 * - Update Profile Schema
 * - Change Password Schema
 */

const { z } = require("zod");

// ─────────────────────────────────────────────
// Update Profile Schema
// ─────────────────────────────────────────────

/**
 * Validates the request body for PUT /api/profile
 *
 * NOTE: email, password, and role updates are intentionally
 * excluded here to prevent unauthorized field changes.
 * All fields are optional so partial updates are supported.
 */
const updateProfileSchema = z.object({
  name: z
    .string()
    .min(2, "Name must be at least 2 characters")
    .max(100, "Name must be at most 100 characters")
    .trim()
    .optional(),

  phone: z
    .string()
    .min(7, "Phone number must be at least 7 digits")
    .max(20, "Phone number must be at most 20 digits")
    .trim()
    .optional(),

  address: z
    .string()
    .min(5, "Address must be at least 5 characters")
    .max(255, "Address must be at most 255 characters")
    .trim()
    .optional(),
});

// ─────────────────────────────────────────────
// Change Password Schema
// ─────────────────────────────────────────────

/**
 * Validates the request body for PUT /api/profile/change-password
 *
 * Enforces:
 * - oldPassword must be provided
 * - newPassword minimum 8 characters
 * - newPassword and confirmPassword must match
 * - newPassword must differ from oldPassword
 */
const changePasswordSchema = z
  .object({
    oldPassword: z
      .string({ required_error: "Old password is required" })
      .min(1, "Old password is required"),

    newPassword: z
      .string({ required_error: "New password is required" })
      .min(8, "New password must be at least 8 characters")
      .max(128, "New password must be at most 128 characters"),

    confirmPassword: z
      .string({ required_error: "Confirm password is required" })
      .min(1, "Confirm password is required"),
  })
  // Ensure newPassword and confirmPassword match
  .refine((data) => data.newPassword === data.confirmPassword, {
    message: "Passwords do not match",
    path: ["confirmPassword"],
  })
  // Ensure new password is different from old password
  .refine((data) => data.oldPassword !== data.newPassword, {
    message: "New password must be different from old password",
    path: ["newPassword"],
  });

// ─────────────────────────────────────────────
// Exports
// ─────────────────────────────────────────────

module.exports = {
  updateProfileSchema,
  changePasswordSchema,
};
