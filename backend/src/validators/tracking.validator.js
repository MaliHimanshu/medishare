const { z } = require("zod");

const pingSchema = z.object({
  latitude: z
    .number()
    .min(-90, "Latitude must be between -90 and 90.")
    .max(90, "Latitude must be between -90 and 90."),
  longitude: z
    .number()
    .min(-180, "Longitude must be between -180 and 180.")
    .max(180, "Longitude must be between -180 and 180."),
  accuracy: z.number().nonnegative().optional(),
  speed: z.number().optional(),
  heading: z.number().min(0).max(360).optional(),
});

const historyQuerySchema = z.object({
  limit: z
    .string()
    .optional()
    .transform((val) => (val ? Number(val) : 50))
    .pipe(z.number().int().min(1).max(200)),
  since: z.string().datetime().optional(),
});

module.exports = {
  pingSchema,
  historyQuerySchema,
};
