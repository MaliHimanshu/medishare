require("dotenv").config();

const http = require("http");
const app = require("./src/app");
const { initSocket } = require("./src/socket");

const PORT = process.env.PORT || 5000;

// Create HTTP server
const server = http.createServer(app);

// Initialize Socket.io
const io = initSocket(server, app);
app.set("io", io);

server.listen(PORT, "0.0.0.0", () => {
  console.log("─────────────────────────────────────────");
  console.log("🏥 MediShare Backend Server Started");
  console.log("─────────────────────────────────────────");
  console.log(`🌍 Environment : ${process.env.NODE_ENV || "development"}`);
  console.log(`🚀 Server URL  : http://0.0.0.0:${PORT}`);
  console.log(`📋 API Base    : http://0.0.0.0:${PORT}/api`);
  console.log(`📖 API Docs    : http://0.0.0.0:${PORT}/api/docs`);
  console.log(`🔌 WebSockets  : Enabled`);
  console.log("─────────────────────────────────────────");
});