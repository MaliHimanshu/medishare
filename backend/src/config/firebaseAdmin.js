const { initializeApp, cert, getApps } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getMessaging } = require("firebase-admin/messaging");

let app = null;

try {
  if (getApps().length === 0) {
    const serviceAccountRaw = process.env.FIREBASE_SERVICE_ACCOUNT;
    if (serviceAccountRaw) {
      let serviceAccount;
      try {
        serviceAccount = JSON.parse(serviceAccountRaw);
      } catch (_) {
        // If it's a file path instead of a JSON string
        serviceAccount = require(serviceAccountRaw);
      }
      app = initializeApp({
        credential: cert(serviceAccount),
      });
      console.log("🔥 Firebase Admin initialized successfully from FIREBASE_SERVICE_ACCOUNT");
    } else {
      app = initializeApp();
      console.log("🔥 Firebase Admin initialized successfully using default credentials");
    }
  } else {
    app = getApps()[0];
  }
} catch (err) {
  console.warn("⚠️ Firebase Admin initialization error:", err.message);
}

module.exports = {
  app,
  getAuth: app ? getAuth : null,
  getMessaging: app ? getMessaging : null,
};
