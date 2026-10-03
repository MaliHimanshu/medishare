import { initializeApp } from "firebase/app";
import { getAuth, signInWithEmailAndPassword, createUserWithEmailAndPassword } from "firebase/auth";

const firebaseConfig = {
  apiKey: "AIzaSyBJc7fFvYH92IDKGLL25xQuGRIiuS7yiDg",
  authDomain: "medishare-e6b5c.firebaseapp.com",
  projectId: "medishare-e6b5c",
  storageBucket: "medishare-e6b5c.firebasestorage.app",
  messagingSenderId: "1070100510061",
  appId: "1:1070100510061:android:bcbeb691c11bcd475a5664"
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
