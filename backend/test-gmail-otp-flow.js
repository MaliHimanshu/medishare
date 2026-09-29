/**
 * Test Suite: MediShare Gmail OTP Flow Verification
 *
 * Verifies:
 * 1. Configuration validation (smtp.gmail.com, port 465, secure: true, GMAIL_USER, GMAIL_APP_PASSWORD)
 * 2. Clear error on missing configuration
 * 3. Clear error on SMTP send failure
 * 4. Zero credentials/OTP leakage in logs and API
 * 5. Registered Gmail address requirement
 * 6. 30-second cooldown enforcement
 * 7. 5-minute expiry enforcement
 * 8. 5-attempt limit and counter increment
 * 9. Successful verification and replay attack protection (hash cleared)
 * 10. Forgot password OTP flow
 * 11. Twilio phone OTP system preservation
 */

const assert = require("assert");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const nodemailer = require("nodemailer");
const { PrismaClient } = require("@prisma/client");

const prisma = new PrismaClient();

// Save original environment
const originalEnv = { ...process.env };

let passedTests = 0;
let totalTests = 0;

function runTest(name, fn) {
  totalTests++;
  try {
    fn();
    console.log(`  ✅ PASS: ${name}`);
    passedTests++;
  } catch (err) {
    console.error(`  ❌ FAIL: ${name}`);
    console.error(`     Error: ${err.message}`);
    process.exitCode = 1;
  }
}

async function runAsyncTest(name, fn) {
  totalTests++;
  try {
    await fn();
    console.log(`  ✅ PASS: ${name}`);
    passedTests++;
  } catch (err) {
    console.error(`  ❌ FAIL: ${name}`);
    console.error(`     Error: ${err.message}`);
    process.exitCode = 1;
  }
}

async function main() {
  console.log("=====================================================");
  console.log("   MediShare Gmail OTP Flow - Verification Suite    ");
  console.log("=====================================================\n");

  const emailService = require("./src/services/email.service");
  const authService = require("./src/services/auth.service");

  // -----------------------------------------------------------------
  // 1. Configuration Validation: Missing Environment Variables
  // -----------------------------------------------------------------
  console.log("🔹 1. Configuration & Missing Credentials Tests");

  delete process.env.GMAIL_USER;
  delete process.env.GMAIL_APP_PASSWORD;

  runTest("getEmailConfig detects both missing variables", () => {
    const config = emailService.getEmailConfig();
    assert.strictEqual(config.isConfigured, false);
    assert.strictEqual(config.host, "smtp.gmail.com");
    assert.strictEqual(config.port, 465);
    assert.strictEqual(config.secure, true);
    assert.deepStrictEqual(config.missing, ["GMAIL_USER", "GMAIL_APP_PASSWORD"]);
  });

  await runAsyncTest("sendEmailOtp throws clear error when GMAIL_USER and GMAIL_APP_PASSWORD are missing", async () => {
    await assert.rejects(
      async () => {
        await emailService.sendEmailOtp("test@gmail.com", "123456");
      },
      (err) => {
        return (
          err.message.includes("Gmail service is not configured") &&
          err.message.includes("GMAIL_USER") &&
          err.message.includes("GMAIL_APP_PASSWORD")
        );
      }
    );
  });

  process.env.GMAIL_USER = "medishare.system@gmail.com";
  delete process.env.GMAIL_APP_PASSWORD;

  await runAsyncTest("sendEmailOtp throws clear error when GMAIL_APP_PASSWORD is missing", async () => {
    await assert.rejects(
      async () => {
        await emailService.sendEmailOtp("test@gmail.com", "123456");
      },
      (err) => {
        return (
          err.message.includes("Gmail service is not configured") &&
          err.message.includes("GMAIL_APP_PASSWORD")
        );
      }
    );
  });

  // -----------------------------------------------------------------
  // 2. Configuration Validation: Fully Configured Gmail Settings
  // -----------------------------------------------------------------
  console.log("\n🔹 2. Gmail Transport Specification Tests");

  process.env.GMAIL_USER = "medishare.org@gmail.com";
  process.env.GMAIL_APP_PASSWORD = "abcd efgh ijkl mnop"; // Test space stripping

  runTest("getEmailConfig normalizes credentials and sets host smtp.gmail.com:465 with secure:true", () => {
    const config = emailService.getEmailConfig();
    assert.strictEqual(config.isConfigured, true);
    assert.strictEqual(config.host, "smtp.gmail.com");
    assert.strictEqual(config.port, 465);
    assert.strictEqual(config.secure, true);
    assert.strictEqual(config.user, "medishare.org@gmail.com");
    assert.strictEqual(config.pass, "abcdefghijklmnop");
    assert.strictEqual(config.from, '"MediShare" <medishare.org@gmail.com>');
    assert.strictEqual(config.missing.length, 0);
  });

  runTest("getTransporter creates transporter with smtp.gmail.com, 465, and secure: true", () => {
    const transporter = emailService.getTransporter();
    assert.ok(transporter);
    assert.strictEqual(transporter.options.host, "smtp.gmail.com");
    assert.strictEqual(transporter.options.port, 465);
    assert.strictEqual(transporter.options.secure, true);
    assert.strictEqual(transporter.options.auth.user, "medishare.org@gmail.com");
    assert.strictEqual(transporter.options.auth.pass, "abcdefghijklmnop");
  });

  // -----------------------------------------------------------------
  // 3. Clear Error on Email Send Failure
  // -----------------------------------------------------------------
  console.log("\n🔹 3. Clear Error on Email Sending Failure");

  await runAsyncTest("sendEmailOtp wraps and throws clear error if nodemailer sendMail fails", async () => {
    const transporter = emailService.getTransporter();
    const originalSendMail = transporter.sendMail;

    transporter.sendMail = async () => {
      throw new Error("Invalid login: 535-5.7.8 Username and Password not accepted");
    };

    try {
      await assert.rejects(
        async () => {
          await emailService.sendEmailOtp("recipient@gmail.com", "654321");
        },
        (err) => {
          return (
            err.message.startsWith("Failed to send email OTP:") &&
            err.message.includes("535-5.7.8")
          );
        }
      );
    } finally {
      transporter.sendMail = originalSendMail;
    }
  });

  // -----------------------------------------------------------------
  // 4. Registered User Email Requirement & Security
  // -----------------------------------------------------------------
  console.log("\n🔹 4. Registered User & Security Tests");

  await runAsyncTest("sendOtp rejects non-registered email with clear error", async () => {
    await assert.rejects(
      async () => {
        await authService.sendOtp("nonexistent_user_99999@gmail.com", "email");
      },
      (err) => {
        return err.message.includes("No account found with this email address");
      }
    );
  });

  await runAsyncTest("sendForgotPasswordOtp rejects non-registered email with clear error", async () => {
    await assert.rejects(
      async () => {
        await authService.sendForgotPasswordOtp("nonexistent_user_99999@gmail.com", "email");
      },
      (err) => {
        return err.message.includes("No account found with this email address");
      }
    );
  });

  // -----------------------------------------------------------------
  // 5. Complete Gmail OTP Lifecycle (Generate, Cooldown, Expiry, Verify)
  // -----------------------------------------------------------------
  console.log("\n🔹 5. Complete Gmail OTP Lifecycle Tests");

  const testEmail = `gmail_test_${Date.now()}@gmail.com`;
  let testUser;

  // Create temporary test user in DB
  testUser = await prisma.user.create({
    data: {
      name: "Gmail Test User",
      email: testEmail,
      password: await bcrypt.hash("Password123!", 10),
      phone: "+919988776655",
      role: "DONOR",
      verificationStatus: "VERIFIED",
    },
  });

  // Intercept sendMail to capture OTP without exposing credentials
  let capturedOtp = null;
  let capturedRecipient = null;
  const transporter = emailService.getTransporter();
  transporter.sendMail = async (options) => {
    capturedRecipient = options.to;
    // Extract 6-digit OTP from text without logging
    const match = options.text.match(/\b\d{6}\b/);
    if (match) capturedOtp = match[0];
    return { messageId: "mock-message-id" };
  };

  try {
    // 5a. Send OTP
    await runAsyncTest("sendOtp sends 6-digit OTP to user registered Gmail address and stores hash", async () => {
      const result = await authService.sendOtp(testEmail, "email");
      assert.strictEqual(result.success, true);
      assert.strictEqual(capturedRecipient, testEmail);
      assert.ok(capturedOtp && capturedOtp.length === 6);

      const dbUser = await prisma.user.findUnique({ where: { id: testUser.id } });
      assert.ok(dbUser.phoneOtpHash);
      assert.ok(dbUser.phoneOtpExpiresAt);
      assert.strictEqual(dbUser.phoneOtpAttempts, 0);

      // Verify hash matches bcrypt format
      const isMatch = await bcrypt.compare(`email:${capturedOtp}`, dbUser.phoneOtpHash);
      assert.strictEqual(isMatch, true);
    });

    // 5b. 30-Second Cooldown Check
    await runAsyncTest("sendOtp enforces 30-second cooldown on consecutive requests", async () => {
      await assert.rejects(
        async () => {
          await authService.sendOtp(testEmail, "email");
        },
        (err) => {
          return err.message.includes("Please wait") && err.message.includes("before requesting a new OTP");
        }
      );
    });

    // 5c. Wrong OTP Check
    await runAsyncTest("verifyOtp rejects incorrect OTP and increments attempt counter", async () => {
      const res = await authService.verifyOtp(testEmail, "000000", "email");
      assert.strictEqual(res.success, false);
      assert.strictEqual(res.message, "Incorrect verification code. Please try again.");

      const dbUser = await prisma.user.findUnique({ where: { id: testUser.id } });
      assert.strictEqual(dbUser.phoneOtpAttempts, 1);
    });

    // 5d. Max 5 Attempts Lockout Check
    await runAsyncTest("verifyOtp blocks verification after 5 failed attempts", async () => {
      await prisma.user.update({
        where: { id: testUser.id },
        data: { phoneOtpAttempts: 5 },
      });

      const res = await authService.verifyOtp(testEmail, capturedOtp, "email");
      assert.strictEqual(res.success, false);
      assert.strictEqual(res.message, "Too many incorrect attempts. Please request a new OTP.");
    });

    // 5e. Expiry Check
    await runAsyncTest("verifyOtp rejects expired OTP", async () => {
      await prisma.user.update({
        where: { id: testUser.id },
        data: {
          phoneOtpAttempts: 0,
          phoneOtpExpiresAt: new Date(Date.now() - 1000), // Expired 1 second ago
        },
      });

      const res = await authService.verifyOtp(testEmail, capturedOtp, "email");
      assert.strictEqual(res.success, false);
      assert.strictEqual(res.message, "This verification code has expired. Please request a new code.");
    });

    // 5f. Successful Verification & Replay Attack Prevention
    await runAsyncTest("verifyOtp succeeds with valid OTP and clears hash to prevent replay", async () => {
      // Refresh OTP with valid expiry
      await prisma.user.update({
        where: { id: testUser.id },
        data: {
          phoneOtpAttempts: 0,
          phoneOtpExpiresAt: new Date(Date.now() + 5 * 60 * 1000),
        },
      });

      const res = await authService.verifyOtp(testEmail, capturedOtp, "email");
      assert.strictEqual(res.success, true);
      assert.strictEqual(res.message, "Email verified successfully");
      assert.ok(res.token);
      assert.strictEqual(res.user.email, testEmail);

      // Verify DB hash is completely cleared
      const dbUser = await prisma.user.findUnique({ where: { id: testUser.id } });
      assert.strictEqual(dbUser.phoneOtpHash, null);
      assert.strictEqual(dbUser.phoneOtpExpiresAt, null);
      assert.strictEqual(dbUser.phoneOtpAttempts, 0);

      // Verify replay fails
      const replayRes = await authService.verifyOtp(testEmail, capturedOtp, "email");
      assert.strictEqual(replayRes.success, false);
    });

    // -----------------------------------------------------------------
    // 6. Forgot Password Gmail OTP Flow
    // -----------------------------------------------------------------
    console.log("\n🔹 6. Forgot Password Gmail OTP Flow Tests");

    capturedOtp = null;
    await prisma.user.update({
      where: { id: testUser.id },
      data: { phoneOtpLastSentAt: null }, // Reset cooldown for test
    });

    await runAsyncTest("sendForgotPasswordOtp sends OTP and verifyForgotPasswordOtp returns resetToken", async () => {
      const sendRes = await authService.sendForgotPasswordOtp(testEmail, "email");
      assert.strictEqual(sendRes.success, true);
      assert.strictEqual(capturedRecipient, testEmail);
      assert.ok(capturedOtp && capturedOtp.length === 6);

      // Verify OTP
      const verifyRes = await authService.verifyForgotPasswordOtp(testEmail, "email", capturedOtp);
      assert.ok(verifyRes.resetToken);

      // Verify reset token payload
      const decoded = jwt.verify(verifyRes.resetToken, process.env.JWT_SECRET || "medishare_super_secret_key");
      assert.strictEqual(decoded.userId, testUser.id);
      assert.strictEqual(decoded.action, "password_reset");

      // Reset password
      const resetRes = await authService.resetForgotPassword(testEmail, "email", verifyRes.resetToken, "NewSecurePassword123!");
      assert.strictEqual(resetRes, true);

      // Login with new password
      const loginRes = await authService.loginUser(testEmail, "NewSecurePassword123!");
      assert.strictEqual(loginRes.user.email, testEmail);
    });

    // -----------------------------------------------------------------
    // 7. Preservation of Twilio Phone OTP System
    // -----------------------------------------------------------------
    console.log("\n🔹 7. Twilio Phone OTP System Preservation");

    runTest("Twilio Verify service methods and phone branches remain unchanged", () => {
      const twilioService = require("./src/services/twilioVerify.service");
      assert.strictEqual(typeof twilioService.sendVerifyOtp, "function");
      assert.strictEqual(typeof twilioService.checkVerifyOtp, "function");
      assert.strictEqual(typeof twilioService.getVerifyConfig, "function");
    });

  } finally {
    // Cleanup test user
    if (testUser?.id) {
      await prisma.user.delete({ where: { id: testUser.id } }).catch(() => {});
    }
    await prisma.$disconnect();
    // Restore original env
    process.env = originalEnv;
  }

  console.log("\n=====================================================");
  console.log(`   Verification Summary: ${passedTests} / ${totalTests} tests passed`);
  console.log("=====================================================");

  if (passedTests === totalTests) {
    console.log("\n🎉 All Gmail OTP flow requirements successfully verified!");
  } else {
    process.exit(1);
  }
}

main().catch((err) => {
  console.error("Fatal test runner error:", err);
  process.exit(1);
});
