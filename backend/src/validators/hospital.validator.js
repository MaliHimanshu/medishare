const { z } = require("zod");

const hospitalSchema = z.object({
  hospitalName: z
    .string()
    .trim()
    .min(3, "Hospital name must be at least 3 characters.")
    .max(100),

  address: z
    .string()
    .trim()
    .min(5, "Address is required."),

  city: z
    .string()
    .trim()
    .min(2),

  state: z
    .string()
    .trim()
    .min(2),

  pincode: z
    .string()
    .regex(/^[0-9]{6}$/, "Invalid pincode."),

  phone: z
    .string()
    .regex(/^[0-9]{10}$/, "Invalid phone number.")
    .optional(),

  email: z
    .string()
    .email("Invalid email.")
    .optional(),

  website: z
    .string()
    .url("Invalid website URL.")
    .optional(),

  description: z
    .string()
    .max(500)
    .optional(),

  latitude: z
    .number()
    .optional(),

  longitude: z
    .number()
    .optional(),

  image: z
    .string()
    .url()
    .optional(),
});

const hospitalQuerySchema = z.object({
  page: z
    .string()
    .optional()
    .transform((v) => (v ? parseInt(v) : 1))
    .pipe(z.number().min(1)),

  limit: z
    .string()
    .optional()
    .transform((v) => (v ? parseInt(v) : 10))
    .pipe(z.number().min(1).max(100)),

  city: z.string().optional(),

  state: z.string().optional(),

  search: z.string().optional(),
});

module.exports = {
  hospitalSchema,
  hospitalQuerySchema,
};