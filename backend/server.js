require("dotenv").config();

const app = require("./src/app");

const PORT = process.env.PORT || 5000;

app.listen(PORT, "0.0.0.0", () => {
  console.log("─────────────────────────────────────────");
  console.log("🏥 MediShare Backend Server Started");
  console.log("─────────────────────────────────────────");
  console.log(`🌍 Environment : ${process.env.NODE_ENV || "development"}`);
  console.log(`🚀 Server URL  : http://0.0.0.0:${PORT}`);
  console.log(`📋 API Base    : http://0.0.0.0:${PORT}/api`);
  console.log(`📖 API Docs    : http://0.0.0.0:${PORT}/api/docs`);
  console.log("─────────────────────────────────────────");
});