/**
 * @swagger
 * tags:
 *   - name: Hospital
 *     description: Hospital Management APIs
 */

/**
 * @swagger
 * /api/hospital:
 *   post:
 *     summary: Create Hospital
 *     description: Register a new hospital.
 *     tags:
 *       - Hospital
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - hospitalName
 *               - email
 *               - phone
 *               - address
 *             properties:
 *               hospitalName:
 *                 type: string
 *                 example: Civil Hospital Ahmedabad
 *               email:
 *                 type: string
 *                 example: civil@gmail.com
 *               phone:
 *                 type: string
 *                 example: "9876543210"
 *               address:
 *                 type: string
 *                 example: Ahmedabad, Gujarat
 *     responses:
 *       201:
 *         description: Hospital created successfully.
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
 *                   example: Hospital created successfully.
 *                 data:
 *                   $ref: '#/components/schemas/Hospital'
 *       400:
 *         description: Validation Error
 *       401:
 *         description: Unauthorized
 */

/**
 * @swagger
 * /api/hospital:
 *   get:
 *     summary: Get All Hospitals
 *     description: Returns all registered hospitals.
 *     tags:
 *       - Hospital
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Hospital list fetched successfully.
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 total:
 *                   type: integer
 *                   example: 1
 *                 page:
 *                   type: integer
 *                   example: 1
 *                 limit:
 *                   type: integer
 *                   example: 10
 *                 hospitals:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/Hospital'
 *       401:
 *         description: Unauthorized
 */

/**
 * @swagger
 * /api/hospital/{id}:
 *   get:
 *     summary: Get Hospital By ID
 *     description: Returns hospital details by ID.
 *     tags:
 *       - Hospital
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         description: Hospital ID
 *         schema:
 *           type: string
 *           example: "cmrvhospital123456789"
 *     responses:
 *       200:
 *         description: Hospital fetched successfully.
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   $ref: '#/components/schemas/Hospital'
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Hospital not found
 */

/**
 * @swagger
 * /api/hospital/{id}:
 *   put:
 *     summary: Update Hospital
 *     description: Update hospital details.
 *     tags:
 *       - Hospital
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         description: Hospital ID
 *         schema:
 *           type: string
 *           example: "cmrvhospital123456789"
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               hospitalName:
 *                 type: string
 *                 example: Updated Civil Hospital
 *               email:
 *                 type: string
 *                 example: updated@gmail.com
 *               phone:
 *                 type: string
 *                 example: "9999999999"
 *               address:
 *                 type: string
 *                 example: Ahmedabad, Gujarat
 *     responses:
 *       200:
 *         description: Hospital updated successfully.
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
 *                   example: Hospital updated successfully.
 *                 data:
 *                   $ref: '#/components/schemas/Hospital'
 *       400:
 *         description: Validation Error
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Hospital not found
 */

/**
 * @swagger
 * /api/hospital/{id}:
 *   delete:
 *     summary: Delete Hospital
 *     description: Delete a hospital by ID.
 *     tags:
 *       - Hospital
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         description: Hospital ID
 *         schema:
 *           type: string
 *           example: "cmrvhospital123456789"
 *     responses:
 *       200:
 *         description: Hospital deleted successfully.
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
 *                   example: Hospital deleted successfully.
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Hospital not found
 */