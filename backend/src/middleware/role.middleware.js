/**
 * Role Authorization Middleware
 * --------------------------------
 * File: src/middleware/role.middleware.js
 */

const authorize = (...allowedRoles) => {
  return (req, res, next) => {
    // Authentication middleware must run first
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: "Authentication required.",
      });
    }

    // Check if the user's role is allowed
    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: "You are not authorized to access this resource.",
      });
    }

    next();
  };
};

module.exports = authorize;