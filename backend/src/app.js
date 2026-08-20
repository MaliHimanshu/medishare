const express = require("express");
const cors = require("cors");
const morgan = require("morgan");

const swaggerUi = require("swagger-ui-express");
const swaggerSpec = require("./config/swagger");

// Routes
const authRoutes = require("./routes/auth.routes");
const profileRoutes = require("./routes/profile.routes");
const equipmentRoutes = require("./routes/equipment.routes");
const equipmentLocationRoutes = require("./routes/equipmentLocation.routes");
const donationRoutes = require("./routes/donation.routes");
const requestRoutes = require("./routes/request.routes");
const hospitalRoutes = require("./routes/hospital.routes");
const notificationRoutes = require("./routes/notification.routes");
const dashboardRoutes = require("./routes/dashboard.routes");
const chatbotRoutes = require("./routes/chatbot.routes");
const uploadRoutes = require("./routes/upload.routes");
const rentalRoutes = require("./routes/rental.routes");
const trackingRoutes = require("./routes/tracking.routes");

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

const SWAGGER_CSS_URL =
  "https://cdnjs.cloudflare.com/ajax/libs/swagger-ui/5.11.8/swagger-ui.min.css";
const SWAGGER_JS_URLS = [
  "https://cdnjs.cloudflare.com/ajax/libs/swagger-ui/5.11.8/swagger-ui-bundle.js",
  "https://cdnjs.cloudflare.com/ajax/libs/swagger-ui/5.11.8/swagger-ui-standalone-preset.js",
];

app.use(
  "/api/docs",
  swaggerUi.serve,
  swaggerUi.setup(swaggerSpec, {
    explorer: true,
    customCssUrl: SWAGGER_CSS_URL,
    customJs: SWAGGER_JS_URLS,
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
app.use("/api/equipment", equipmentLocationRoutes);
app.use("/api/donation", donationRoutes);
app.use("/api/request", requestRoutes);
app.use("/api/hospital", hospitalRoutes);
app.use("/api/notification", notificationRoutes);
app.use("/api/dashboard", dashboardRoutes);
app.use("/api/chatbot", chatbotRoutes);
app.use("/api/upload", uploadRoutes);
app.use("/api/rental", rentalRoutes);
app.use("/api/tracking", trackingRoutes);

// ── Health Check (for Railway / Docker) ────────────────────────────
app.get("/api/health", (req, res) => {
  res.status(200).json({ status: "ok", service: "MediShare API", timestamp: new Date().toISOString() });
});

module.exports = app;