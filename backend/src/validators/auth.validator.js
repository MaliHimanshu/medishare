const { z } = require("zod");

const registerSchema = z.object({
  name: z
    .string({ required_error: "Name is required" })
    .min(2, "Name must be at least 2 characters")
    .max(100, "Name must be at most 100 characters")
    .trim(),

  email: z
    .string({ required_error: "Email is required" })
    .email("Invalid email address")
    .toLowerCase()
    .trim(),

  password: z
    .string({ required_error: "Password is required" })
    .min(8, "Password must be at least 8 characters")
    .max(128, "Password must be at most 128 characters"),

  phone: z
    .string({ required_error: "Phone number is required" })
    .min(7, "Phone number must be at least 7 digits")
    .max(20, "Phone number must be at most 20 digits")
    .trim(),

  address: z
    .string({ required_error: "Address is required" })
    .min(5, "Address must be at least 5 characters")
    .max(255, "Address must be at most 255 characters")
    .trim(),

  role: z.enum(["ADMIN", "DONOR", "NGO", "RECIPIENT"], {
    required_error: "Role is required",
    invalid_type_error:
      "Role must be one of: ADMIN, DONOR, NGO, RECIPIENT",
  }),
});

const loginSchema = z.object({
  email: z
    .string({ required_error: "Email is required" })
    .email("Invalid email address")
    .toLowerCase()
    .trim(),

  password: z
    .string({ required_error: "Password is required" })
    .min(8, "Password must be at least 8 characters")
    .max(128, "Password must be at most 128 characters"),
});

module.exports = {
  registerSchema,
  loginSchema,
};