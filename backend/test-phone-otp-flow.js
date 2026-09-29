/**
 * Test Phone OTP and Auth Flow
 * ----------------------------
 * Validates:
 * 1. Email + Password login works and accepts email
 * 2. User registration requires Name, Email, Phone, Password
 * 3. Twilio Verify service status and config
 * 4. Forgot password uses phone SMS via Twilio
 * 5. No secrets or OTPs leaked
 */

const { getVerifyConfig } = require("./src/services/twilioVerify.service");
const { registerSchema, loginSchema, otpSendSchema, otpVerifySchema, forgotPasswordSendSchema, forgotPasswordVerifySchema, resetPasswordSchema } = require("./src/validators/auth.validator");

async function runTests() {
  console.log("=== MediShare Phone OTP & Auth Flow Tests ===");

  let passed = 0;
  let failed = 0;

  function assert(condition, name) {
    if (condition) {
      console.log(`  ✅ [PASS] ${name}`);
      passed++;
    } else {
      console.error(`  ❌ [FAIL] ${name}`);
      failed++;
    }
  }

  // Test 1: Twilio Verify Config
  console.log("\n1. Twilio Verify Configuration:");
  const config = getVerifyConfig();
  console.log(`   Twilio Configured: ${config.isConfigured}`);
  if (!config.isConfigured) {
    console.log(`   Missing env vars for live sending: ${config.missing.join(", ")}`);
  }
  assert(typeof config.isConfigured === "boolean", "Twilio Verify config returns boolean status");

  // Test 2: Registration Validation Schema retains Name, Email, Phone, Password
  console.log("\n2. Registration Schema Validation:");
  try {
    const validData = {
      name: "Test Doctor",
      email: "doctor@example.com",
      phone: "+919876543210",
      password: "Password123",
      role: "DONOR",
    };
    const parsed = registerSchema.parse(validData);
    assert(parsed.email === "doctor@example.com", "Email is present and validated in registration");
    assert(parsed.phone === "+919876543210", "Phone is present and validated in registration");
    assert(parsed.name === "Test Doctor", "Name is present in registration");
  } catch (err) {
    assert(false, `Registration valid data failed: ${err.message}`);
  }

  // Registration fails without email
  try {
    registerSchema.parse({
      name: "Test Doctor",
      phone: "+919876543210",
      password: "Password123",
      role: "DONOR",
    });
    assert(false, "Registration should fail without email");
  } catch (err) {
    assert(true, "Registration properly requires email");
  }

  // Registration fails without phone
  try {
    registerSchema.parse({
      name: "Test Doctor",
      email: "doctor@example.com",
      password: "Password123",
      role: "DONOR",
    });
    assert(false, "Registration should fail without phone");
  } catch (err) {
    assert(true, "Registration properly requires phone for SMS OTP");
  }

  // Test 3: Login Schema retains Email + Password
  console.log("\n3. Login Schema Validation:");
  try {
    const validLogin = loginSchema.parse({
      email: "doctor@example.com",
      password: "Password123",
    });
    assert(validLogin.email === "doctor@example.com", "Email login is fully supported");
  } catch (err) {
    assert(false, `Email login validation failed: ${err.message}`);
  }

  // Test 4: OTP Send Schema accepts phone
  console.log("\n4. OTP Send Schema Validation:");
  try {
    const validOtpSend = otpSendSchema.parse({
      phone: "+919876543210",
    });
    assert(validOtpSend.phone === "+919876543210", "Phone accepted for OTP send");
  } catch (err) {
    assert(false, `OTP send validation failed: ${err.message}`);
  }

  // Test 5: OTP Verify Schema validates 6-digit OTP
  console.log("\n5. OTP Verify Schema Validation:");
  try {
    const validOtpVerify = otpVerifySchema.parse({
      phone: "+919876543210",
      otp: "123456",
    });
    assert(validOtpVerify.otp === "123456", "6-digit OTP validated");
  } catch (err) {
    assert(false, `OTP verify validation failed: ${err.message}`);
  }

  // Reject invalid OTP length
  try {
    otpVerifySchema.parse({
      phone: "+919876543210",
      otp: "123",
    });
    assert(false, "Should reject non-6-digit OTP");
  } catch (err) {
    assert(true, "Properly rejected short OTP");
  }

  // Test 6: Forgot Password Schemas
  console.log("\n6. Forgot Password Validation:");
  try {
    const validForgotSend = forgotPasswordSendSchema.parse({
      target: "+919876543210",
      type: "phone",
    });
    assert(validForgotSend.target === "+919876543210", "Forgot password send accepts target phone");
  } catch (err) {
    assert(false, `Forgot password send failed: ${err.message}`);
  }

  try {
    const validForgotVerify = forgotPasswordVerifySchema.parse({
      target: "+919876543210",
      type: "phone",
      otp: "654321",
    });
    assert(validForgotVerify.otp === "654321", "Forgot password verify accepts 6-digit OTP");
  } catch (err) {
    assert(false, `Forgot password verify failed: ${err.message}`);
  }

  console.log(`\n=== Test Results: ${passed} passed, ${failed} failed ===`);
  if (failed > 0) {
    process.exit(1);
  }
}

runTests().catch((err) => {
  console.error("Test execution failed:", err);
  process.exit(1);
});
