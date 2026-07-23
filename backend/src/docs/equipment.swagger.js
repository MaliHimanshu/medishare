/**
 * @swagger
 * tags:
 *   - name: Equipment
 *     description: Medical Equipment Management APIs
 */

/**
 * @swagger
 * /api/equipment:
 *   post:
 *     summary: Create Equipment
 *     description: Create a new medical equipment. Authentication required.
 *     tags:
 *       - Equipment
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Equipment'
 *           example:
 *             name: Wheelchair
 *             category: Mobility
 *             manufacturer: Sunrise Medical
 *             description: Foldable wheelchair in excellent condition.
 *             quantity: 5
 *             condition: NEW
 *             image: https://res.cloudinary.com/demo/image/upload/wheelchair.jpg
 *             status: AVAILABLE
 *     responses:
 *       201:
 *         description: Equipment created successfully.
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: Equipment created successfully.
 *                 data:
 *                   $ref: '#/components/schemas/Equipment'
 *       400:
 *         description: Validation Error
 *       401:
 *         description: Unauthorized
 *       500:
 *         description: Internal Server Error
 */

/**
 * @swagger
 * /api/equipment:
 *   get:
 *     summary: Get All Equipment
 *     description: Returns all available equipment.
 *     tags:
 *       - Equipment
 *     responses:
 *       200:
 *         description: Equipment list fetched successfully.
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 count:
 *                   type: integer
 *                   example: 5
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/Equipment'
 *       500:
 *         description: Internal Server Error
 */

/**
 * @swagger
 * /api/equipment/{id}:
 *   get:
 *     summary: Get Equipment By ID
 *     description: Returns a single equipment by its ID.
 *     tags:
 *       - Equipment
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         description: Equipment ID
 *         schema:
 *           type: string
 *           example: cmrvqwuei000cszio4vb1aemu
 *     responses:
 *       200:
 *         description: Equipment fetched successfully.
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   $ref: '#/components/schemas/Equipment'
 *       404:
 *         description: Equipment not found.
 *       500:
 *         description: Internal Server Error
 */

/**
 * @swagger
 * /api/equipment/{id}:
 *   put:
 *     summary: Update Equipment
 *     description: Update an existing equipment. Authentication required.
 *     tags:
 *       - Equipment
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         description: Equipment ID
 *         schema:
 *           type: string
 *           example: cmrvqwuei000cszio4vb1aemu
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Equipment'
 *           example:
 *             name: Wheelchair
 *             category: Mobility
 *             manufacturer: Sunrise Medical
 *             description: Updated wheelchair description.
 *             quantity: 10
 *             condition: GOOD
 *             image: https://res.cloudinary.com/demo/image/upload/wheelchair.jpg
 *             status: AVAILABLE
 *     responses:
 *       200:
 *         description: Equipment updated successfully.
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: Equipment updated successfully.
 *                 data:
 *                   $ref: '#/components/schemas/Equipment'
 *       400:
 *         description: Validation Error
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Equipment not found.
 *       500:
 *         description: Internal Server Error
 */

/**
 * @swagger
 * /api/equipment/{id}:
 *   delete:
 *     summary: Delete Equipment
 *     description: Delete equipment by ID. Authentication required.
 *     tags:
 *       - Equipment
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         description: Equipment ID
 *         schema:
 *           type: string
 *           example: cmrvqwuei000cszio4vb1aemu
 *     responses:
 *       200:
 *         description: Equipment deleted successfully.
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: Equipment deleted successfully.
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Equipment not found.
 *       500:
 *         description: Internal Server Error
 */