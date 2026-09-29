/**
 * Push Notification Service
 * -------------------------
 * File: src/services/pushNotification.service.js
 *
 * Dispatches emergency equipment notifications through:
 * 1. Persistent in-app database notifications (Notification table)
 * 2. High-priority real-time Socket.io events
 * 3. Firebase Cloud Messaging (FCM) when configured
 *
 * Never logs credentials, private tokens, or sensitive user data.
 */

const prisma = require("../config/prisma");

let firebaseAdmin = null;
let isFcmConfigured = false;

// Attempt optional Firebase Admin initialization
try {
  const serviceAccountRaw = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (serviceAccountRaw) {
    const admin = require("firebase-admin");
    let serviceAccount;
    try {
      serviceAccount = JSON.parse(serviceAccountRaw);
    } catch (_) {
      serviceAccount = require(serviceAccountRaw);
    }
    if (!admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
    }
    firebaseAdmin = admin;
    isFcmConfigured = true;
    console.log("🔥 Firebase Admin (FCM) initialized successfully");
  } else {
    console.log("ℹ️ [Push Notification] FCM credentials not set. Using in-app DB + WebSocket notifications.");
  }
} catch (err) {
  console.warn("⚠️ [Push Notification] Firebase initialization skipped:", err.message);
  isFcmConfigured = false;
}

/**
 * Dispatches emergency equipment alert to targeted NGOs
 * @param {Object} params
 * @param {Object} params.alert - The created EmergencyAlert record
 * @param {string} params.hospitalName - Name of the requesting hospital
 * @param {Array<Object>} params.targetNgos - Array of eligible NGO user objects
 * @param {Object} [params.io] - Socket.io server instance
 */
const notifyNgosOfEmergency = async ({ alert, hospitalName, targetNgos, io }) => {
  if (!targetNgos || targetNgos.length === 0) return;

  const title = "🚨 Emergency Equipment Required";
  const body = `${hospitalName} urgently requires ${alert.quantityRequired} ${alert.equipmentName}.`;

  // 1. Create In-App Notifications in bulk
  try {
    const notificationRecords = targetNgos.map((ngo) => ({
      userId: ngo.id,
      title,
      message: body,
      type: "EMERGENCY_ALERT",
      isRead: false,
    }));

    await prisma.notification.createMany({
      data: notificationRecords,
    });
  } catch (dbErr) {
    console.error("[Notification Service] Error creating in-app notifications:", dbErr.message);
  }

  // 2. Real-time WebSocket delivery
  if (io) {
    console.log(`[Notification Service] IO is present. Broadcasting emergency:new_alert to ${targetNgos.length} NGOs.`);
    const payload = {
      type: "EMERGENCY_ALERT",
      alertId: alert.id,
      equipmentName: alert.equipmentName,
      equipmentCategory: alert.equipmentCategory,
      quantityRequired: alert.quantityRequired,
      priority: alert.priority,
      hospitalName,
      address: alert.address,
      createdAt: alert.createdAt,
    };

    targetNgos.forEach((ngo) => {
      console.log(`[Notification Service] Emitting to user_${ngo.id}`);
      io.to(`user_${ngo.id}`).emit("emergency:new_alert", payload);
    });
  } else {
    console.warn("[Notification Service] WARNING: io object is undefined. Cannot broadcast WebSocket event.");
  }

  // 3. FCM Push Notifications (if configured and tokens available)
  if (isFcmConfigured && firebaseAdmin) {
    const fcmTokens = targetNgos
      .map((ngo) => ngo.fcmToken)
      .filter((token) => Boolean(token && token.trim()));

    if (fcmTokens.length > 0) {
      try {
        const message = {
          notification: {
            title,
            body,
          },
          data: {
            emergencyAlertId: alert.id,
            notificationType: "EMERGENCY_ALERT",
            priority: alert.priority,
            equipmentName: alert.equipmentName,
            quantityRequired: String(alert.quantityRequired),
          },
          android: {
            priority: "high",
            notification: {
              channelId: "emergency_alerts_channel",
              sound: "emergency_alert",
              priority: "high",
              defaultSound: false,
              defaultVibrateTimings: true,
            },
          },
          tokens: fcmTokens,
        };

        const response = await firebaseAdmin.messaging().sendEachForMulticast(message);
        console.log(`[FCM] Sent emergency notification: ${response.successCount} succeeded, ${response.failureCount} failed`);
      } catch (fcmErr) {
        console.error("[FCM] Error dispatching multicast notification:", fcmErr.message);
      }
    }
  }
};

/**
 * Dispatches emergency equipment response alert to the requesting Hospital
 * @param {Object} params
 * @param {Object} params.alert - The EmergencyAlert record
 * @param {Object} params.response - The EmergencyAlertResponse record
 * @param {string} params.ngoName - Name of the responding NGO
 * @param {number} params.totalAvailable - Cumulative available quantity across all responses
 * @param {Object} [params.io] - Socket.io instance
 */
const notifyHospitalOfResponse = async ({ alert, response, ngoName, totalAvailable, io }) => {
  const title = "📦 NGO Responded to Emergency Alert";
  const body = `${ngoName} offered ${response.quantityAvailable} ${alert.equipmentName}. Total available: ${totalAvailable}/${alert.quantityRequired}.`;

  // 1. Create In-App Notification for Hospital
  try {
    await prisma.notification.create({
      data: {
        userId: alert.hospitalId,
        title,
        message: body,
        type: "EMERGENCY_RESPONSE",
        isRead: false,
      },
    });
  } catch (dbErr) {
    console.error("[Notification Service] Error creating hospital response notification:", dbErr.message);
  }

  // 2. Real-time WebSocket delivery to Hospital
  if (io) {
    io.to(`user_${alert.hospitalId}`).emit("emergency:response_received", {
      type: "EMERGENCY_RESPONSE",
      alertId: alert.id,
      responseId: response.id,
      ngoName,
      quantityAvailable: response.quantityAvailable,
      totalAvailable,
      quantityRequired: alert.quantityRequired,
      message: response.message,
      createdAt: response.createdAt,
    });
  }

  // 3. FCM Push to Hospital (if configured)
  if (isFcmConfigured && firebaseAdmin) {
    try {
      const hospitalUser = await prisma.user.findUnique({
        where: { id: alert.hospitalId },
        select: { fcmToken: true },
      });

      if (hospitalUser && hospitalUser.fcmToken) {
        await firebaseAdmin.messaging().send({
          token: hospitalUser.fcmToken,
          notification: {
            title,
            body,
          },
          data: {
            emergencyAlertId: alert.id,
            notificationType: "EMERGENCY_RESPONSE",
            totalAvailable: String(totalAvailable),
          },
          android: {
            priority: "high",
            notification: {
              channelId: "emergency_alerts_channel",
              sound: "emergency_alert",
            },
          },
        });
      }
    } catch (fcmErr) {
      console.error("[FCM] Error notifying hospital:", fcmErr.message);
    }
  }
};

module.exports = {
  notifyNgosOfEmergency,
  notifyHospitalOfResponse,
};
