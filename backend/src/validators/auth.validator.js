const { z } = require("zod");

const registerSchema = z.object({
  name: z
    .string({ required_error: "Name is required" })
    .min(2, "Name must be at least 2 characters")
    .max(100, "Name must be at most 100 characters")
    .trim(),

  email: z
    .string({ required_error: "Email is required" })
    .trim()
    .toLowerCase()
    .email("Invalid email address"),

  password: z
    .string({ required_error: "Password is required" })
    .min(8, "Password must be at least 8 characters")
    .max(128, "Password must be at most 128 characters"),

  phone: z
    .string({ required_error: "Phone is required" })
    .min(10, "Phone number must be at least 10 digits")
    .max(20, "Phone number must be at most 20 digits")
    .trim(),

  address: z
    .string()
    .min(5, "Address must be at least 5 characters")
    .max(255, "Address must be at most 255 characters")
    .trim()
    .optional(),

  role: z.enum(["ADMIN", "DONOR", "NGO", "RECIPIENT"], {
    required_error: "Role is required",
    invalid_type_error:
      "Role must be one of: ADMIN, DONOR, NGO, RECIPIENT",
  }),
});

const loginSchema = z.object({
  email: z
    .string({ required_error: "Email is required" })
    .trim()
    .toLowerCase()
    .email("Invalid email address"),

  password: z
    .string({ required_error: "Password is required" })
    .min(8, "Password must be at least 8 characters")
    .max(128, "Password must be at most 128 characters"),
});

const otpSendSchema = z.object({
  phone: z
    .string({ required_error: "Phone is required" })
    .trim(),
});

const otpVerifySchema = z.object({
  phone: z
    .string({ required_error: "Phone is required" })
    .trim(),
  otp: z
    .string({ required_error: "OTP is required" })
    .length(6, "OTP must be exactly 6 digits"),
});

module.exports = {
  registerSchema,
  loginSchema,
  otpSendSchema,
  otpVerifySchema,
};