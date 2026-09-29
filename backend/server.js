require("dotenv").config();

const app = require("./src/app");
const { initSocket } = require("./src/socket");
const { getEmailConfig } = require("./src/services/email.service");

const PORT = process.env.PORT || 5000;

const server = app.listen(PORT, "0.0.0.0", () => {
  const emailConfig = getEmailConfig();
  console.log(`Server running on port ${PORT}`);
  console.log("─────────────────────────────────────────");
  console.log("🏥 MediShare Backend Server Started");
  console.log("─────────────────────────────────────────");
  console.log(`🌍 Environment     : ${process.env.NODE_ENV || "development"}`);
  console.log(`🚀 Server URL      : http://0.0.0.0:${PORT}`);
  console.log(`📋 API Base        : http://0.0.0.0:${PORT}/api`);
  console.log(`📖 API Docs        : http://0.0.0.0:${PORT}/api/docs`);
  console.log(`🔌 WebSockets      : Enabled`);
  console.log(`📧 Gmail configured: ${emailConfig.isConfigured}`);
  console.log("─────────────────────────────────────────");
});

// Initialize Socket.io
const io = initSocket(server, app);
app.set("io", io);