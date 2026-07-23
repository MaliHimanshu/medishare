const swaggerJSDoc = require("swagger-jsdoc");

const options = {
  definition: {
    openapi: "3.0.0",

    info: {
      title: "MediShare API",
      version: "1.0.0",
      description:
        "Medical Equipment Donation and Request Management System API Documentation",

      contact: {
        name: "MediShare Team",
        email: "support@medishare.com",
      },
    },

    servers: [
      {
        url: process.env.RENDER_EXTERNAL_URL || process.env.BASE_URL || "http://localhost:5000",
        description: "API Server",
      },
    ],

    components: {
      securitySchemes: {
        bearerAuth: {
          type: "http",
          scheme: "bearer",
          bearerFormat: "JWT",
        },
      },

      schemas: {
        User: {
          type: "object",
          properties: {
            id: {
              type: "integer",
              example: 1,
            },

            name: {
              type: "string",
              example: "Rahul Sharma",
            },

            email: {
              type: "string",
              example: "rahul@gmail.com",
            },

            role: {
              type: "string",
              example: "DONOR",
            },
          },
        },

        Error: {
          type: "object",
          properties: {
            success: {
              type: "boolean",
              example: false,
            },

            message: {
              type: "string",
              example: "Something went wrong",
            },
          },
        },
      },
    },

    security: [
      {
        bearerAuth: [],
      },
    ],
  },

 apis: [
  "./src/docs/*.js",
],
};

const swaggerSpec = swaggerJSDoc(options);

console.log("Swagger Paths");
console.log(swaggerSpec.paths);

module.exports = swaggerSpec;