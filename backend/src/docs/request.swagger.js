/**
 * @swagger
 * tags:
 *   - name: Request
 *     description: Equipment Request Management APIs
 */

/**
 * @swagger
 * /api/request:
 *   post:
 *     summary: Create Equipment Request
 *     description: Create a new equipment request.
 *     tags:
 *       - Request
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - equipmentId
 *             properties:
 *               equipmentId:
 *                 type: string
 *                 example: "cmrvrljf10001szkk7i5iall2"
 *     responses:
 *       201:
 *         description: Request created successfully.
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
 *                   example: Request created successfully.
 *                 data:
 *                   $ref: '#/components/schemas/Request'
 *       400:
 *         description: Validation Error
 *       401:
 *         description: Unauthorized
 */

/**
 * @swagger
 * /api/request:
 *   get:
 *     summary: Get All Requests
 *     description: Returns all equipment requests.
 *     tags:
 *       - Request
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Request list fetched successfully.
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
 *                     $ref: '#/components/schemas/Request'
 *       401:
 *         description: Unauthorized
 */

/**
 * @swagger
 * /api/request/{id}:
 *   get:
 *     summary: Get Request By ID
 *     description: Returns a request by ID.
 *     tags:
 *       - Request
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         description: Request ID
 *         schema:
 *           type: string
 *           example: "cmrvrequest123456789"
 *     responses:
 *       200:
 *         description: Request fetched successfully.
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   $ref: '#/components/schemas/Request'
 *       404:
 *         description: Request not found
 */

/**
 * @swagger
 * /api/request/{id}/status:
 *   patch:
 *     summary: Update Request Status
 *     description: Update the status of a request.
 *     tags:
 *       - Request
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         description: Request ID
 *         schema:
 *           type: string
 *           example: "cmrvrequest123456789"
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
 *         description: Request status updated successfully.
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
 *                   example: Request status updated successfully.
 *                 data:
 *                   $ref: '#/components/schemas/Request'
 *       400:
 *         description: Validation Error
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Request not found
 */

/**
 * @swagger
 * /api/request/{id}:
 *   delete:
 *     summary: Delete Request
 *     description: Delete a request by ID.
 *     tags:
 *       - Request
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         description: Request ID
 *         schema:
 *           type: string
 *           example: "cmrvrequest123456789"
 *     responses:
 *       200:
 *         description: Request deleted successfully.
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
 *                   example: Request deleted successfully.
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Request not found
 */