const { z } = require("zod");

const equipmentCondition = [
  "NEW",
  "LIKE_NEW",
  "GOOD",
  "FAIR",
];

const equipmentStatus = [
  "AVAILABLE",
  "REQUESTED",
  "DONATED",
  "UNAVAILABLE",
];

const createEquipmentSchema = z.object({
  body: z.object({
    name: z
      .string()
      .min(3, "Equipment name must be at least 3 characters.")
      .max(100),

    category: z
      .string()
      .min(2, "Category is required.")
      .max(100),

    manufacturer: z
      .string()
      .max(100)
      .optional(),

    description: z
      .string()
      .max(500)
      .optional(),

    quantity: z
      .number()
      .int()
      .min(1, "Quantity must be at least 1."),

    condition: z.enum(equipmentCondition),

    status: z
      .enum(equipmentStatus)
      .optional(),

    image: z
      .string()
      .optional(),
  }),
});

const updateEquipmentSchema = z.object({
  body: z.object({
    name: z.string().min(3).max(100).optional(),

    category: z.string().max(100).optional(),

    manufacturer: z.string().max(100).optional(),

    description: z.string().max(500).optional(),

    quantity: z.number().int().min(1).optional(),

    condition: z
      .enum(equipmentCondition)
      .optional(),

    status: z
      .enum(equipmentStatus)
      .optional(),

    image: z
      .string()
      .optional(),
  }),
});

module.exports = {
  createEquipmentSchema,
  updateEquipmentSchema,
};