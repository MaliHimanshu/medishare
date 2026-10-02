const { getAuth } = require("../config/firebaseAdmin");
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

    if (!decodedToken.email) {
      return res.status(401).json({
        success: false,
        message: "Firebase token does not contain an email.",
      });
    }

    const user = await prisma.user.findUnique({
      where: {
        email: decodedToken.email,
      },
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        phoneVerified: true,
        address: true,
        profileImage: true,
        role: true,
        organizationName: true,
        registrationNumber: true,
        contactPerson: true,
        equipmentPreference: true,
        verificationStatus: true,
        createdAt: true,
      },
    });

    if (!user) {
      return res.status(401).json({
        success: false,
        message: "User not found.",
      });
    }

    req.user = user;

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