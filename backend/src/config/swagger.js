const swaggerJSDoc = require("swagger-jsdoc");

const swaggerSpec = swaggerJSDoc({
  definition: {
    openapi: "3.0.0",
    info: {
      title: "MediShare API",
      version: "1.0.0",
      description: "Medical Equipment Donation and Request System API",
    },
    servers: [
      {
        url: `http://localhost:${process.env.PORT || 5000}`,
      },
    ],
  },
  apis: [],
});

module.exports = {
  swaggerSpec,
};
