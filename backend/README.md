# 🏥 MediShare Backend

> **Medical Equipment Donation and Request System**
> A production-ready Node.js REST API built for the MediShare Final Year Project.

---

## 📋 Table of Contents

- [Project Overview](#-project-overview)
- [Tech Stack](#-tech-stack)
- [Folder Structure](#-folder-structure)
- [Getting Started](#-getting-started)
- [Environment Variables](#-environment-variables)
- [Prisma Commands](#-prisma-commands)
- [API Modules](#-api-modules)
- [Running the Server](#-running-the-server)
- [API Documentation](#-api-documentation)
- [Flutter Connection](#-flutter-connection)

---

## 🎯 Project Overview

MediShare is a platform that connects medical equipment donors with recipients in need.

| Feature | Description |
|---------|-------------|
| 🔐 Authentication | JWT-based register, login, logout |
| 👤 Profile | Update profile, change password, upload image |
| 🏥 Equipment | List, search, filter medical equipment |
| 🎁 Donations | Donate equipment with full status tracking |
| 📋 Requests | Request equipment with approval workflow |
| 🏨 Hospitals | Hospital directory with geo-location search |
| 🔔 Notifications | Real-time event-based notification system |
| 🤖 Chatbot | AI assistant powered by Google Gemini |
| 📊 Dashboard | Analytics and statistics for all modules |

---

## 🛠 Tech Stack

| Layer | Technology |
|-------|-----------|
| Runtime | Node.js 18+ |
| Framework | Express.js |
| Database | PostgreSQL |
| ORM | Prisma |
| Auth | JWT + bcrypt |
| Validation | Zod |
| File Upload | Multer |
| AI | Google Gemini |
| Security | Helmet + express-rate-limit |
| Docs | Swagger UI |

---

## 📁 Folder Structure

```
backend/
├── prisma/
│   └── schema.prisma          # Database schema & models
├── src/
│   ├── app.js                 # Express app (middleware + routes)
│   ├── config/
│   │   ├── prisma.js          # Prisma client singleton
│   │   ├── gemini.js          # Google Gemini AI config
│   │   └── swagger.js         # Swagger documentation config
│   ├── controllers/           # Route handlers (thin layer)
│   │   ├── auth.controller.js
│   │   ├── profile.controller.js
│   │   ├── equipment.controller.js
│   │   ├── donation.controller.js
│   │   ├── request.controller.js
│   │   ├── hospital.controller.js
│   │   ├── notification.controller.js
│   │   ├── chatbot.controller.js
│   │   └── dashboard.controller.js
│   ├── services/              # Business logic layer
│   │   ├── auth.service.js
│   │   ├── profile.service.js
│   │   ├── equipment.service.js
│   │   ├── donation.service.js
│   │   ├── request.service.js
│   │   ├── hospital.service.js
│   │   ├── notification.service.js
│   │   ├── chatbot.service.js
│   │   └── dashboard.service.js
│   ├── routes/                # Express routers
│   │   ├── auth.routes.js
│   │   ├── profile.routes.js
│   │   ├── equipment.routes.js
│   │   ├── donation.routes.js
│   │   ├── request.routes.js
│   │   ├── hospital.routes.js
│   │   ├── notification.routes.js
│   │   ├── chatbot.routes.js
│   │   └── dashboard.routes.js
│   ├── middleware/
│   │   └── auth.middleware.js  # JWT verification
│   ├── validators/             # Zod schemas
│   │   ├── auth.validator.js
│   │   ├── profile.validator.js
│   │   ├── equipment.validator.js
│   │   ├── donation.validator.js
│   │   ├── request.validator.js
│   │   ├── hospital.validator.js
│   │   ├── notification.validator.js
│   │   └── chatbot.validator.js
│   └── utils/
│       └── apiResponse.js      # Standardized response helpers
├── uploads/                    # Uploaded image files
│   ├── profile/
│   ├── equipment/
│   └── hospitals/
├── server.js                   # HTTP server entry point
├── package.json
├── .env                        # Your local environment (gitignored)
├── .env.example                # Template for environment variables
└── prisma.config.ts            # Prisma configuration
```

---

## 🚀 Getting Started

### Prerequisites

- Node.js 18+
- PostgreSQL 14+
- npm

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/yourusername/medishare.git
cd medishare/backend

# 2. Install dependencies
npm install

# 3. Set up environment variables
cp .env.example .env
# Edit .env with your values

# 4. Generate Prisma client
npm run prisma:generate

# 5. Run database migrations
npm run prisma:migrate

# 6. Start the development server
npm run dev
```

---

## 🔑 Environment Variables

Copy `.env.example` to `.env` and fill in:

| Variable | Description | Example |
|----------|-------------|---------|
| `PORT` | Server port | `5000` |
| `NODE_ENV` | Environment | `development` |
| `DATABASE_URL` | PostgreSQL connection URL | `postgresql://user:pass@localhost:5432/medishare` |
| `JWT_SECRET` | JWT signing secret (min 32 chars) | `your_super_secret_key` |
| `GEMINI_API_KEY` | Google Gemini AI key | `AIza...` |
| `BASE_URL` | Server base URL | `http://localhost:5000` |

---

## 🗄 Prisma Commands

```bash
# Generate Prisma Client (run after schema changes)
npm run prisma:generate

# Create and apply a new migration
npm run prisma:migrate

# Push schema to DB without migration history (dev only)
npm run prisma:push

# Open Prisma Studio (visual DB browser)
npm run prisma:studio
```

---

## 📡 API Modules

| Module | Base Path | Description |
|--------|-----------|-------------|
| Auth | `/api/auth` | Register, login, logout, me |
| Profile | `/api/profile` | Get, update, change password, upload image |
| Equipment | `/api/equipment` | CRUD for medical equipment |
| Donations | `/api/donations` | Donate and track equipment |
| Requests | `/api/requests` | Request and approve equipment |
| Hospitals | `/api/hospitals` | Hospital directory + nearby search |
| Notifications | `/api/notifications` | User notification feed |
| Chatbot | `/api/chatbot` | AI assistant powered by Gemini |
| Dashboard | `/api/dashboard` | Analytics and statistics |

---

## ▶️ Running the Server

```bash
# Development (with auto-reload)
npm run dev

# Production
npm start
```

Server starts at: **http://localhost:5000**

---

## 📖 API Documentation

Swagger UI is available at:

```
http://localhost:5000/api/docs
```

---

## 📱 Flutter Connection

In your Flutter app, set the base URL:

```dart
// lib/core/constants/api_constants.dart

class ApiConstants {
  // For Android Emulator → use 10.0.2.2 (maps to host machine localhost)
  static const String baseUrl = 'http://10.0.2.2:5000/api';

  // For iOS Simulator → use localhost
  // static const String baseUrl = 'http://localhost:5000/api';

  // For physical device → use your machine's local IP
  // static const String baseUrl = 'http://192.168.x.x:5000/api';
}
```

> **Note:** The Android emulator uses `10.0.2.2` to reach the host machine's `localhost`.
