const { z } = require("zod");

const notificationSchema = z.object({
  userId: z
    .string()
    .min(1, "User ID is required."),

  title: z
    .string()
    .trim()
    .min(3, "Title must be at least 3 characters.")
    .max(100),

  message: z
    .string()
    .trim()
    .min(5, "Message must be at least 5 characters.")
    .max(500),

  type: z.enum([
    "REQUEST",
    "DONATION",
    "APPROVAL",
    "REJECTION",
    "GENERAL",
  ]),

  isRead: z.boolean().optional().default(false),
});

const notificationQuerySchema = z.object({
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
});

module.exports = {
  notificationSchema,
  notificationQuerySchema,
};