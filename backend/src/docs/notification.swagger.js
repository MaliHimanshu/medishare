/**
 * @swagger
 * tags:
 *   - name: Notification
 *     description: Notification Management APIs
 */

/**
 * @swagger
 * /api/notification:
 *   post:
 *     summary: Create Notification
 *     description: Create a new notification.
 *     tags:
 *       - Notification
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - userId
 *               - title
 *               - message
 *               - type
 *             properties:
 *               userId:
 *                 type: string
 *                 example: "cmrvshow90004szk8g82qo1co"
 *               title:
 *                 type: string
 *                 example: Equipment Request
 *               message:
 *                 type: string
 *                 example: Your equipment request has been received.
 *               type:
 *                 type: string
 *                 enum:
 *                   - REQUEST
 *                   - DONATION
 *                   - APPROVAL
 *                   - REJECTION
 *                   - GENERAL
 *                 example: REQUEST
 *     responses:
 *       201:
 *         description: Notification created successfully.
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
 *                   example: Notification created successfully.
 *                 data:
 *                   $ref: '#/components/schemas/Notification'
 *       400:
 *         description: Validation Error
 *       401:
 *         description: Unauthorized
 */

/**
 * @swagger
 * /api/notification:
 *   get:
 *     summary: Get My Notifications
 *     description: Returns notifications of the logged-in user.
 *     tags:
 *       - Notification
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Notifications fetched successfully.
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
 *                   example: 5
 *                 page:
 *                   type: integer
 *                   example: 1
 *                 limit:
 *                   type: integer
 *                   example: 10
 *                 notifications:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/Notification'
 *       401:
 *         description: Unauthorized
 */

/**
 * @swagger
 * /api/notification/{id}/read:
 *   patch:
 *     summary: Mark Notification as Read
 *     description: Marks a notification as read.
 *     tags:
 *       - Notification
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           example: "cmrvnotify123456789"
 *     responses:
 *       200:
 *         description: Notification marked as read.
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
 *                   example: Notification marked as read.
 *                 data:
 *                   $ref: '#/components/schemas/Notification'
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Notification not found
 */

/**
 * @swagger
 * /api/notification/{id}:
 *   delete:
 *     summary: Delete Notification
 *     description: Delete a notification.
 *     tags:
 *       - Notification
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           example: "cmrvnotify123456789"
 *     responses:
 *       200:
 *         description: Notification deleted successfully.
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
 *                   example: Notification deleted successfully.
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: Notification not found
 */