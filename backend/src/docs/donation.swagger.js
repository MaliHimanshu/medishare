/**
 * @swagger
 * tags:
 *   - name: Donation
 *     description: Donation Management APIs
 */

/**
 * @swagger
 * /api/donation:
 *   post:
 *     summary: Create Donation
 *     description: Create a new donation.
 *     tags:
 *       - Donation
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Donation'
 *     responses:
 *       201:
 *         description: Donation created successfully.
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
 *                   example: Donation created successfully.
 *                 data:
 *                   $ref: '#/components/schemas/Donation'
 *       400:
 *         description: Validation Error
 *       401:
 *         description: Unauthorized
 */

/**
 * @swagger
 * /api/donation:
 *   get:
 *     summary: Get All Donations
 *     description: Returns all donations.
 *     tags:
 *       - Donation
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Donation list fetched successfully.
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
 *                     $ref: '#/components/schemas/Donation'
 *       401:
 *         description: Unauthorized
 */

/**
 * @swagger
 * /api/donation/{id}:
 *   get:
 *     summary: Get Donation By ID
 *     description: Returns a donation by ID.
 *     tags:
 *       - Donation
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         description: Donation ID
 *         schema:
 *           type: integer
 *           example: 1
 *     responses:
 *       200:
 *         description: Donation fetched successfully.
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   $ref: '#/components/schemas/Donation'
 *       404:
 *         description: Donation not found
 */

/**
 * @swagger
 * /api/donation/{id}/status:
 *   patch:
 *     summary: Update Donation Status
 *     description: Update the status of a donation.
 *     tags:
 *       - Donation
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         description: Donation ID
 *         schema:
 *           type: integer
 *           example: 1
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - status
 *             properties:
 *               status:
 *                 type: string
 *                 enum:
 *                   - PENDING
 *                   - APPROVED
 *                   - REJECTED
 *                   - COMPLETED
 *                 example: APPROVED
 *     responses:
 *       200:
 *         description: Donation status updated successfully.
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
 *                   example: Donation status updated successfully.
 *                 data:
 *                   $ref: '#/components/schemas/Donation'
 *       400:
 *         description: Validation Error
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Donation not found
 */

/**
 * @swagger
 * /api/donation/{id}:
 *   delete:
 *     summary: Delete Donation
 *     description: Delete a donation by ID.
 *     tags:
 *       - Donation
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         description: Donation ID
 *         schema:
 *           type: integer
 *           example: 1
 *     responses:
 *       200:
 *         description: Donation deleted successfully.
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
 *                   example: Donation deleted successfully.
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Donation not found
 */