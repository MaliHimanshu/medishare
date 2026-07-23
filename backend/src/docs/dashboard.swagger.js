/**
 * @swagger
 * tags:
 *   - name: Dashboard
 *     description: Dashboard Management APIs
 */

/**
 * @swagger
 * /api/dashboard/summary:
 *   get:
 *     summary: Get Dashboard Summary
 *     description: Returns dashboard summary statistics.
 *     tags:
 *       - Dashboard
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Dashboard summary fetched successfully.
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   type: object
 *                   properties:
 *                     totalUsers:
 *                       type: integer
 *                       example: 15
 *                     totalEquipment:
 *                       type: integer
 *                       example: 45
 *                     availableEquipment:
 *                       type: integer
 *                       example: 32
 *                     totalRequests:
 *                       type: integer
 *                       example: 20
 *                     pendingRequests:
 *                       type: integer
 *                       example: 8
 *                     approvedRequests:
 *                       type: integer
 *                       example: 10
 *                     completedDonations:
 *                       type: integer
 *                       example: 7
 *                     totalHospitals:
 *                       type: integer
 *                       example: 5
 *                     totalNotifications:
 *                       type: integer
 *                       example: 18
 *       401:
 *         description: Unauthorized
 *       500:
 *         description: Internal Server Error
 */

/**
 * @swagger
 * /api/dashboard/recent-requests:
 *   get:
 *     summary: Get Recent Requests
 *     description: Returns the latest 5 equipment requests.
 *     tags:
 *       - Dashboard
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Recent requests fetched successfully.
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       id:
 *                         type: string
 *                         example: "cmrvrequest123"
 *                       status:
 *                         type: string
 *                         example: "PENDING"
 *                       createdAt:
 *                         type: string
 *                         format: date-time
 *                       requester:
 *                         type: object
 *                         properties:
 *                           id:
 *                             type: string
 *                             example: "cmrvuser123"
 *                           name:
 *                             type: string
 *                             example: "Himanshu"
 *                           email:
 *                             type: string
 *                             example: "himanshu@gmail.com"
 *                       equipment:
 *                         type: object
 *                         properties:
 *                           id:
 *                             type: string
 *                             example: "cmrvequip123"
 *                           name:
 *                             type: string
 *                             example: "Wheelchair"
 *                           status:
 *                             type: string
 *                             example: "AVAILABLE"
 *       401:
 *         description: Unauthorized
 *       500:
 *         description: Internal Server Error
 */

/**
 * @swagger
 * /api/dashboard/recent-donations:
 *   get:
 *     summary: Get Recent Donations
 *     description: Returns the latest 5 donations.
 *     tags:
 *       - Dashboard
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Recent donations fetched successfully.
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       id:
 *                         type: string
 *                         example: "cmrvdonation123"
 *                       status:
 *                         type: string
 *                         example: "COMPLETED"
 *                       createdAt:
 *                         type: string
 *                         format: date-time
 *                       donor:
 *                         type: object
 *                         properties:
 *                           id:
 *                             type: string
 *                             example: "cmrvuser123"
 *                           name:
 *                             type: string
 *                             example: "Himanshu"
 *                           email:
 *                             type: string
 *                             example: "himanshu@gmail.com"
 *                       equipment:
 *                         type: object
 *                         properties:
 *                           id:
 *                             type: string
 *                             example: "cmrvequip123"
 *                           name:
 *                             type: string
 *                             example: "Wheelchair"
 *       401:
 *         description: Unauthorized
 *       500:
 *         description: Internal Server Error
 */

/**
 * @swagger
 * /api/dashboard/recent-notifications:
 *   get:
 *     summary: Get Recent Notifications
 *     description: Returns the latest 5 notifications.
 *     tags:
 *       - Dashboard
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Recent notifications fetched successfully.
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       id:
 *                         type: string
 *                         example: "cmrvnotify123"
 *                       userId:
 *                         type: string
 *                         example: "cmrvuser123"
 *                       title:
 *                         type: string
 *                         example: "Equipment Request"
 *                       message:
 *                         type: string
 *                         example: "Your equipment request has been received."
 *                       type:
 *                         type: string
 *                         example: "REQUEST"
 *                       isRead:
 *                         type: boolean
 *                         example: false
 *                       createdAt:
 *                         type: string
 *                         format: date-time
 *                       user:
 *                         type: object
 *                         properties:
 *                           id:
 *                             type: string
 *                             example: "cmrvuser123"
 *                           name:
 *                             type: string
 *                             example: "Himanshu"
 *                           email:
 *                             type: string
 *                             example: "himanshu@gmail.com"
 *       401:
 *         description: Unauthorized
 *       500:
 *         description: Internal Server Error
 */