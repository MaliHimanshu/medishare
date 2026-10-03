const { initializeApp } = require("firebase/app");
const { getAuth, signInWithEmailAndPassword, createUserWithEmailAndPassword } = require("firebase/auth");

const firebaseConfig = {
  apiKey: "AIzaSyAuP5T_lAHYd4MYBcUXJc9cntwlNPL5Pak",
  authDomain: "medishare-e6b5c.firebaseapp.com",
  projectId: "medishare-e6b5c",
  storageBucket: "medishare-e6b5c.firebasestorage.app",
  messagingSenderId: "1070100510061",
  appId: "1:1070100510061:web:f8576334ab04d6865a5664"
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);

const EMAIL = "test_firebase_auth@example.com";
const PASSWORD = "password123";

async function test() {
  try {
    const userCredential = await createUserWithEmailAndPassword(auth, EMAIL, PASSWORD);
    console.log("SUCCESS CREATE", await userCredential.user.getIdToken());
  } catch (error) {
    console.error("CREATE ERROR:", error.code, error.message);
    if (error.code === 'auth/email-already-in-use') {
      try {
        const userCredential = await signInWithEmailAndPassword(auth, EMAIL, PASSWORD);
        console.log("SUCCESS LOGIN", await userCredential.user.getIdToken());
      } catch (loginError) {
        console.error("LOGIN ERROR:", loginError.code, loginError.message);
      }
    }
  }
}

test();
