const express = require("express");
const cors = require("cors");
const morgan = require("morgan");

const swaggerUi = require("swagger-ui-express");
const swaggerSpec = require("./config/swagger");

// Routes
const authRoutes = require("./routes/auth.routes");
const profileRoutes = require("./routes/profile.routes");
const equipmentRoutes = require("./routes/equipment.routes");
const donationRoutes = require("./routes/donation.routes");
const requestRoutes = require("./routes/request.routes");
const hospitalRoutes = require("./routes/hospital.routes");
const notificationRoutes = require("./routes/notification.routes");
const dashboardRoutes = require("./routes/dashboard.routes");
const chatbotRoutes = require("./routes/chatbot.routes");

const app = express();

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan("dev"));

/*
=====================================
Swagger
=====================================
*/

app.use(
  "/api/docs",
  swaggerUi.serve,
  swaggerUi.setup(swaggerSpec, {
    explorer: true,
  })
);

/*
=====================================
Routes
=====================================
*/

app.use("/api/auth", authRoutes);
app.use("/api/profile", profileRoutes);
app.use("/api/equipment", equipmentRoutes);
app.use("/api/donation", donationRoutes);
app.use("/api/request", requestRoutes);
app.use("/api/hospital", hospitalRoutes);
app.use("/api/notification", notificationRoutes);
app.use("/api/dashboard", dashboardRoutes);
app.use("/api/chatbot", chatbotRoutes);

// ── Health Check (for Railway / Docker) ────────────────────────────
app.get("/api/health", (req, res) => {
  res.status(200).json({ status: "ok", service: "MediShare API", timestamp: new Date().toISOString() });
});

module.exports = app;