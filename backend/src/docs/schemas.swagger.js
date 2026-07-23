/**
 * @swagger
 * components:
 *   securitySchemes:
 *     bearerAuth:
 *       type: http
 *       scheme: bearer
 *       bearerFormat: JWT
 *
 *   schemas:
 *
 *     User:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *           example: "cmrvqjm0v0000szio5pfc5ehe"
 *         name:
 *           type: string
 *           example: Himanshu
 *         email:
 *           type: string
 *           format: email
 *           example: himanshu@gmail.com
 *         phone:
 *           type: string
 *           example: "9876543210"
 *         address:
 *           type: string
 *           example: Ahmedabad, Gujarat
 *         role:
 *           type: string
 *           enum:
 *             - DONOR
 *             - HOSPITAL
 *             - ADMIN
 *         createdAt:
 *           type: string
 *           format: date-time
 *         updatedAt:
 *           type: string
 *           format: date-time
 *
 *     Register:
 *       type: object
 *       required:
 *         - name
 *         - email
 *         - password
 *         - phone
 *         - address
 *       properties:
 *         name:
 *           type: string
 *           example: Himanshu
 *         email:
 *           type: string
 *           example: himanshu@gmail.com
 *         password:
 *           type: string
 *           example: Password@123
 *         phone:
 *           type: string
 *           example: "9876543210"
 *         address:
 *           type: string
 *           example: Ahmedabad, Gujarat
 *         role:
 *           type: string
 *           enum:
 *             - DONOR
 *             - HOSPITAL
 *             - ADMIN
 *           example: DONOR
 *
 *     Login:
 *       type: object
 *       required:
 *         - email
 *         - password
 *       properties:
 *         email:
 *           type: string
 *           example: himanshu@gmail.com
 *         password:
 *           type: string
 *           example: Password@123
 *
 *     Equipment:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *           example: "cmrvrljf10001szkk7i5iall2"
 *         name:
 *           type: string
 *           example: Wheelchair
 *         category:
 *           type: string
 *           example: Mobility
 *         manufacturer:
 *           type: string
 *           example: Sunrise Medical
 *         description:
 *           type: string
 *           example: Foldable wheelchair in excellent condition.
 *         quantity:
 *           type: integer
 *           example: 5
 *         condition:
 *           type: string
 *           enum:
 *             - NEW
 *             - GOOD
 *             - FAIR
 *         status:
 *           type: string
 *           enum:
 *             - AVAILABLE
 *             - RESERVED
 *             - DONATED
 *         image:
 *           type: string
 *           example: https://res.cloudinary.com/demo/image/upload/wheelchair.jpg
 *         ownerId:
 *           type: string
 *           example: "cmrvqjm0v0000szio5pfc5ehe"
 *         createdAt:
 *           type: string
 *           format: date-time
 *         updatedAt:
 *           type: string
 *           format: date-time
 *
 *     Donation:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *           example: "cmrvrmwz70003szkky4e5n639"
 *         equipmentId:
 *           type: string
 *           example: "cmrvrljf10001szkk7i5iall2"
 *         donorId:
 *           type: string
 *           example: "cmrvqjm0v0000szio5pfc5ehe"
 *         status:
 *           type: string
 *           enum:
 *             - PENDING
 *             - APPROVED
 *             - COMPLETED
 *             - CANCELLED
 *         createdAt:
 *           type: string
 *           format: date-time
 *         updatedAt:
 *           type: string
 *           format: date-time
 *
 *     Request:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *           example: "cmrvxyz123request"
 *         equipmentId:
 *           type: string
 *           example: "cmrvrljf10001szkk7i5iall2"
 *         requesterId:
 *           type: string
 *           example: "cmrvhospital123"
 *         status:
 *           type: string
 *           enum:
 *             - PENDING
 *             - APPROVED
 *             - REJECTED
 *             - COMPLETED
 *         createdAt:
 *           type: string
 *           format: date-time
 *         updatedAt:
 *           type: string
 *           format: date-time
 *
 *     Hospital:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *           example: "cmrvhospital123"
 *         hospitalName:
 *           type: string
 *           example: Civil Hospital Ahmedabad
 *         email:
 *           type: string
 *           example: civil@gmail.com
 *         phone:
 *           type: string
 *           example: "9876543210"
 *         address:
 *           type: string
 *           example: Ahmedabad, Gujarat
 *
 *     Notification:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *           example: "cmrvnotify123"
 *         userId:
 *           type: string
 *           example: "cmrvqjm0v0000szio5pfc5ehe"
 *         title:
 *           type: string
 *           example: Donation Approved
 *         message:
 *           type: string
 *           example: Your donation has been approved.
 *         isRead:
 *           type: boolean
 *           example: false
 *         createdAt:
 *           type: string
 *           format: date-time
 *
 *     DashboardStats:
 *       type: object
 *       properties:
 *         totalUsers:
 *           type: integer
 *           example: 50
 *         totalEquipment:
 *           type: integer
 *           example: 120
 *         totalDonations:
 *           type: integer
 *           example: 35
 *         totalRequests:
 *           type: integer
 *           example: 22
 *         totalHospitals:
 *           type: integer
 *           example: 8
 *
 *     ChatRequest:
 *       type: object
 *       required:
 *         - message
 *       properties:
 *         message:
 *           type: string
 *           example: I need a wheelchair.
 *
 *     ChatResponse:
 *       type: object
 *       properties:
 *         reply:
 *           type: string
 *           example: We found available wheelchairs near your location.
 */