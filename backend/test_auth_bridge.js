const axios = require('axios');
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

const FIREBASE_API_KEY = "AIzaSyAuP5T_lAHYd4MYBcUXJc9cntwlNPL5Pak";
const EMAIL = "test_auth_bridge@example.com";
const PASSWORD = "password123";

async function testAuthBridge() {
  try {
    console.log("1. Creating user in Prisma...");
    let dbUser = await prisma.user.findUnique({ where: { email: EMAIL } });
    if (!dbUser) {
      dbUser = await prisma.user.create({
        data: {
          name: "Test Auth Bridge",
          email: EMAIL,
          password: "hash",
          role: "NGO",
          verificationStatus: "VERIFIED"
        }
      });
      console.log("   Created Prisma user:", dbUser.id);
    } else {
      console.log("   Prisma user already exists:", dbUser.id);
    }

    console.log("2. Creating user in Firebase...");
    let idToken = "";
    try {
      const signupRes = await axios.post(`https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${FIREBASE_API_KEY}`, {
        email: EMAIL,
        password: PASSWORD,
        returnSecureToken: true
      });
      idToken = signupRes.data.idToken;
      console.log("   Created Firebase user, obtained ID Token.");
    } catch (e) {
      if (e.response && e.response.data.error.message === "EMAIL_EXISTS") {
        console.log("   Firebase user exists, logging in...");
        const loginRes = await axios.post(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${FIREBASE_API_KEY}`, {
          email: EMAIL,
          password: PASSWORD,
          returnSecureToken: true
        });
        idToken = loginRes.data.idToken;
        console.log("   Logged in to Firebase, obtained ID Token.");
      } else {
        throw e;
      }
    }

    console.log("3. Testing Node.js API with Firebase ID Token...");
    try {
      const apiRes = await axios.get('http://localhost:5000/api/auth/me', {
        headers: {
          Authorization: `Bearer ${idToken}`
        }
      });
      console.log("   API SUCCESS!");
      console.log("   Response Data:", apiRes.data);
    } catch (e) {
      console.error("   API FAILED!");
      console.error(e.response ? e.response.data : e.message);
      process.exit(1);
    }

    console.log("4. Testing invalid token...");
    try {
      await axios.get('http://localhost:5000/api/auth/me', {
        headers: {
          Authorization: `Bearer invalid_token`
        }
      });
      console.error("   FAILED: API accepted invalid token!");
      process.exit(1);
    } catch (e) {
      if (e.response && e.response.status === 401) {
        console.log("   SUCCESS: API rejected invalid token (401).");
      } else {
        console.error("   FAILED: Unexpected status code", e.response ? e.response.status : e.message);
        process.exit(1);
      }
    }

    console.log("5. Testing Socket.io authentication...");
    const { io } = require("socket.io-client");
    const socket = io("http://localhost:5000", {
      auth: { token: idToken },
      transports: ["websocket"]
    });

    socket.on("connect", () => {
      console.log("   Socket.io SUCCESS!");
      socket.disconnect();
      console.log("ALL TESTS PASSED!");
      process.exit(0);
    });

    socket.on("connect_error", (err) => {
      console.error("   Socket.io FAILED!");
      console.error("   Error:", err.message);
      process.exit(1);
    });

  } catch (err) {
    console.error("Test failed:", err.response ? err.response.data : err.message);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

testAuthBridge();
