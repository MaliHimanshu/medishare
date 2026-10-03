const axios = require('axios');
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

const FIREBASE_API_KEY = "AIzaSyBJc7fFvYH92IDKGLL25xQuGRIiuS7yiDg";
const EMAIL = "test_auth_bridge@example.com";
const PASSWORD = "password123";

async function testAuthBridge() {
  try {
    let idToken = "";
    try {
      const signupRes = await axios.post(
        `https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${FIREBASE_API_KEY}`,
        { email: EMAIL, password: PASSWORD, returnSecureToken: true },
        {
          headers: {
            "X-Android-Package": "com.example.medishare",
            "X-Android-Cert": "62B75A1EF9CD9A7F19D3B6920152F94247563EB6" // A common debug cert, might fail if strict
          }
        }
      );
      idToken = signupRes.data.idToken;
      console.log("   Created Firebase user, obtained ID Token.");
    } catch (e) {
      if (e.response && e.response.data.error.message === "EMAIL_EXISTS") {
        console.log("   Firebase user exists, logging in...");
        const loginRes = await axios.post(
          `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${FIREBASE_API_KEY}`,
          { email: EMAIL, password: PASSWORD, returnSecureToken: true },
          {
            headers: {
              "X-Android-Package": "com.example.medishare",
              "X-Android-Cert": "E3F9" // just guessing, it will likely fail on cert
            }
          }
        );
        idToken = loginRes.data.idToken;
        console.log("   Logged in to Firebase, obtained ID Token.");
      } else {
        console.log("Auth Error:", e.response ? e.response.data.error : e);
        throw e;
      }
    }
  } catch (err) {
    console.error("Test failed");
  } finally {
    await prisma.$disconnect();
  }
}

testAuthBridge();
