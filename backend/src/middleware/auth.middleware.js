const { getAuth, getFirestore } = require("../config/firebaseAdmin");
const prisma = require("../config/prisma");

const protect = async (req, res, next) => {
  try {
    let token;

    if (
      req.headers.authorization &&
      req.headers.authorization.startsWith("Bearer ")
    ) {
      token = req.headers.authorization.split(" ")[1];
    }

    if (!token) {
      return res.status(401).json({
        success: false,
        message: "Access denied. No token provided.",
      });
    }
    
    if (!getAuth) {
      return res.status(500).json({
        success: false,
        message: "Server configuration error: Firebase Admin not initialized.",
      });
    }

    const decodedToken = await getAuth().verifyIdToken(token);

    let user = null;
    
    // 1. Try finding by email (legacy mapping)
    if (decodedToken.email) {
      user = await prisma.user.findUnique({
        where: { email: decodedToken.email },
        select: {
          id: true, name: true, email: true, phone: true, phoneVerified: true,
          address: true, profileImage: true, role: true, organizationName: true,
          registrationNumber: true, contactPerson: true, equipmentPreference: true,
          verificationStatus: true, createdAt: true,
        },
      });
    }

    // 2. Try finding by ID if email didn't match or didn't exist
    if (!user) {
      user = await prisma.user.findUnique({
        where: { id: decodedToken.uid },
        select: {
          id: true, name: true, email: true, phone: true, phoneVerified: true,
          address: true, profileImage: true, role: true, organizationName: true,
          registrationNumber: true, contactPerson: true, equipmentPreference: true,
          verificationStatus: true, createdAt: true,
        },
      });
    }

    // 3. Resolve role from Firestore if available
    let firestoreRole = null;
    if (getFirestore) {
      try {
        const userDoc = await getFirestore().collection("users").doc(decodedToken.uid).get();
        if (userDoc.exists) {
          const data = userDoc.data();
          if (data.role && data.role !== "UNKNOWN") {
            firestoreRole = data.role;
          }
        }
      } catch (err) {
        console.warn("[AuthMiddleware] Could not fetch role from Firestore:", err.message);
      }
    }

    // 4. Create or update user in PostgreSQL
    if (!user) {
      const roleToAssign = firestoreRole || "DONOR";
      user = await prisma.user.create({
        data: {
          id: decodedToken.uid, // Map Firebase UID exactly
          email: decodedToken.email || `${decodedToken.uid}@firebase.local`,
          name: decodedToken.name || "MediShare User",
          password: "firebase_authenticated", // Placeholder
          role: roleToAssign,
          phone: decodedToken.phone_number || null,
        },
        select: {
          id: true, name: true, email: true, phone: true, phoneVerified: true,
          address: true, profileImage: true, role: true, organizationName: true,
          registrationNumber: true, contactPerson: true, equipmentPreference: true,
          verificationStatus: true, createdAt: true,
        },
      });
    } else if (firestoreRole && user.role !== firestoreRole) {
      console.log(`[AuthMiddleware] Syncing role for user ${user.id} (${user.email}): ${user.role} -> ${firestoreRole}`);
      user = await prisma.user.update({
        where: { id: user.id },
        data: { role: firestoreRole },
        select: {
          id: true, name: true, email: true, phone: true, phoneVerified: true,
          address: true, profileImage: true, role: true, organizationName: true,
          registrationNumber: true, contactPerson: true, equipmentPreference: true,
          verificationStatus: true, createdAt: true,
        },
      });
    }

    req.user = user;
    req.firebaseUid = decodedToken.uid;

    next();
  } catch (error) {
    // Log the real Firebase Admin error for debugging
    console.error("[AuthMiddleware] verifyIdToken error:", error?.code, error?.message);
    
    const code = error?.code || "unknown";
    let message = "Authentication failed.";
    
    if (code === "auth/id-token-expired") {
      message = "Firebase ID token has expired. Please refresh and try again.";
    } else if (code === "auth/id-token-revoked") {
      message = "Firebase ID token has been revoked.";
    } else if (code === "auth/invalid-id-token") {
      message = "Firebase ID token is invalid.";
    } else if (code === "auth/user-disabled") {
      message = "This user account has been disabled.";
    } else if (code === "auth/project-not-found") {
      message = "Firebase project configuration error on server.";
    } else if (code === "auth/certificate-fetch-failed") {
      message = "Server could not fetch Firebase certificates. Check server network.";
    }

    return res.status(401).json({
      success: false,
      code,
      message,
    });
  }
};

module.exports = protect;