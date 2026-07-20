/**
 * MediShare Backend – Entry Point
 * --------------------------------
 * File: server.js
 *
 * Bootstraps the Express application and starts the HTTP server.
 * All app configuration (middleware, routes) lives in src/app.js.
 *
 * This file is intentionally kept minimal — it only:
 * 1. Loads environment variables
 * 2. Imports the configured Express app
 * 3. Starts the HTTP listener
 * 4. Handles uncaught exceptions and unhandled rejections
 */

// Load environment variables FIRST — before any other imports
require("dotenv").config();

const app = require("./src/app");

// ─────────────────────────────────────────────
// Configuration
// ─────────────────────────────────────────────

const PORT = process.env.PORT || 5000;
const NODE_ENV = process.env.NODE_ENV || "development";

// ─────────────────────────────────────────────
// Start Server
// ─────────────────────────────────────────────

const server = app.listen(PORT, () => {
  console.log("─────────────────────────────────────────");
  console.log("  🏥 MediShare Backend Server Started");
  console.log("─────────────────────────────────────────");
  console.log(`  🌍 Environment : ${NODE_ENV}`);
  console.log(`  🚀 Server URL  : http://localhost:${PORT}`);
  console.log(`  📋 API Base    : http://localhost:${PORT}/api`);
  console.log(`  📖 API Docs    : http://localhost:${PORT}/api/docs`);
  console.log("─────────────────────────────────────────");
});

// ─────────────────────────────────────────────
// Global Error Handlers
// ─────────────────────────────────────────────

/**
 * Handle unhandled promise rejections.
 * These are async errors that were not caught with try/catch.
 * Log and shut down gracefully.
 */
process.on("unhandledRejection", (reason, promise) => {
  console.error("❌ Unhandled Promise Rejection:", reason);
  // Give the server time to finish current requests before exiting
  server.close(() => {
    console.error("💀 Server shut down due to unhandled rejection.");
    process.exit(1);
  });
});

/**
 * Handle uncaught synchronous exceptions.
 * These are bugs that crash the process immediately.
 * Log and exit — let process manager (nodemon/PM2) restart.
 */
process.on("uncaughtException", (error) => {
  console.error("❌ Uncaught Exception:", error.message);
  console.error(error.stack);
  process.exit(1);
});

/**
 * Handle graceful shutdown on SIGTERM (e.g., Docker stop, Render deploy).
 */
process.on("SIGTERM", () => {
  console.log("🛑 SIGTERM received. Shutting down gracefully...");
  server.close(() => {
    console.log("✅ Server closed.");
    process.exit(0);
  });
});

module.exports = server;