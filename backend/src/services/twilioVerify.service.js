/**
 * Twilio Verify Service
 * ---------------------
 * File: src/services/twilioVerify.service.js
 *
 * Handles sending and checking phone OTP verification using Twilio Verify API.
 * Never logs or prints auth tokens, OTP codes, or secrets.
 */

const twilio = require("twilio");
const { normalizePhoneNumber, maskPhoneNumber } = require("../utils/phone.utils");

/**
 * Read and validate Twilio Verify configuration from process.env
 */
const getVerifyConfig = () => {
  const accountSid = process.env.TWILIO_ACCOUNT_SID;
  const authToken = process.env.TWILIO_AUTH_TOKEN;
  const serviceSid = process.env.TWILIO_VERIFY_SERVICE_SID || process.env.TWILIO_SERVICE_SID;

  const missing = [];
  if (!accountSid || !accountSid.trim()) missing.push("TWILIO_ACCOUNT_SID");
  if (!authToken || !authToken.trim()) missing.push("TWILIO_AUTH_TOKEN");
  if (!serviceSid || !serviceSid.trim()) missing.push("TWILIO_VERIFY_SERVICE_SID");

  return {
    accountSid: accountSid ? accountSid.trim() : null,
    authToken: authToken ? authToken.trim() : null,
    serviceSid: serviceSid ? serviceSid.trim() : null,
    missing,
    isConfigured: missing.length === 0,
  };
};

/**
 * Initialize Twilio Client
 */
const getTwilioClient = () => {
  const config = getVerifyConfig();
  if (!config.isConfigured) {
    throw new Error(
      `Twilio Verify service not configured. Missing environment variable(s): ${config.missing.join(", ")}`
    );
  }
  return twilio(config.accountSid, config.authToken);
};

/**
 * Send an OTP using Twilio Verify API
 * @param {string} phone - Destination phone number (e.g. +918000917657)
 * @returns {Promise<{success: boolean, to: string, status: string}>}
 */
const sendVerifyOtp = async (phone) => {
  const normalizedPhone = normalizePhoneNumber(phone);
  const maskedPhone = maskPhoneNumber(normalizedPhone);
  const config = getVerifyConfig();

  console.log(`[Twilio Verify] Send OTP request received for ${maskedPhone}`);

  if (!config.isConfigured) {
    const errorMsg = `Twilio Verify service not configured. Missing environment variable(s): ${config.missing.join(", ")}`;
    console.error(`[Twilio Verify Config Error] Phone: ${maskedPhone} | ${errorMsg}`);
    throw new Error(errorMsg);
  }

  const client = getTwilioClient();

  try {
    const verification = await client.verify.v2
      .services(config.serviceSid)
      .verifications.create({
        to: normalizedPhone,
        channel: "sms",
      });

    console.log(`[Twilio Verify Success] OTP sent successfully to ${maskedPhone} (Status: ${verification.status})`);

    return {
      success: true,
      to: normalizedPhone,
      status: verification.status,
    };
  } catch (error) {
    const code = error.code;
    let friendlyMessage = "Unable to send verification OTP via SMS.";

    if (code === 21608) {
      friendlyMessage = `Twilio Trial Account Restriction: Phone ${maskedPhone} is not verified. Recipient phone numbers must be verified under 'Verified Caller IDs' in the Twilio Console on trial accounts.`;
    } else if (code === 60628) {
      friendlyMessage = "Twilio Trial Expired: Your Twilio trial account has expired (30-day limit reached) or trial units are depleted. Please upgrade your Twilio project or add balance in Twilio Console.";
    } else if (code === 21408) {
      friendlyMessage = "Twilio Geo-Permission Error: SMS to India (+91) is not enabled in your Twilio account. Please enable India under Twilio Console > Messaging > Settings > Geo-Permissions.";
    } else if (code === 60203) {
      friendlyMessage = "Maximum OTP send attempts reached for this phone number. Please wait before requesting another OTP.";
    } else if (code === 60200 || code === 21211) {
      friendlyMessage = `Invalid phone number format (${maskedPhone}). Please enter a valid 10-digit Indian mobile number.`;
    } else if (code === 20003 || error.status === 401) {
      friendlyMessage = "Twilio authentication error: Please verify TWILIO_ACCOUNT_SID and TWILIO_AUTH_TOKEN in Render environment variables.";
    } else if (code === 20404) {
      friendlyMessage = "Twilio Verify Service not found. Please verify TWILIO_VERIFY_SERVICE_SID in Render environment variables.";
    } else if (code === 20429) {
      friendlyMessage = "Rate limit reached. Please wait a moment before trying again.";
    } else if (error.message) {
      friendlyMessage = error.message;
    }

    console.error(`[Twilio Verify Send Error] Phone: ${maskedPhone} | Code: ${code || "N/A"} | Error: ${error.message}`);
    throw new Error(friendlyMessage);
  }
};

/**
 * Check an OTP using Twilio Verify API
 * @param {string} phone - Destination phone number (e.g. +918000917657)
 * @param {string} otp - 6-digit OTP string
 * @returns {Promise<{success: boolean, status?: string, message?: string}>}
 */
const checkVerifyOtp = async (phone, otp) => {
  const normalizedPhone = normalizePhoneNumber(phone);
  const maskedPhone = maskPhoneNumber(normalizedPhone);
  const config = getVerifyConfig();

  console.log(`[Twilio Verify] Verify OTP check received for ${maskedPhone}`);

  if (!config.isConfigured) {
    const errorMsg = `Twilio Verify service not configured. Missing environment variable(s): ${config.missing.join(", ")}`;
    console.error(`[Twilio Verify Config Error] Phone: ${maskedPhone} | ${errorMsg}`);
    throw new Error(errorMsg);
  }

  const client = getTwilioClient();

  try {
    const verificationCheck = await client.verify.v2
      .services(config.serviceSid)
      .verificationChecks.create({
        to: normalizedPhone,
        code: otp.trim(),
      });

    if (verificationCheck.status === "approved") {
      console.log(`[Twilio Verify Success] OTP verified and approved for ${maskedPhone}`);
      return {
        success: true,
        status: verificationCheck.status,
      };
    }

    console.warn(`[Twilio Verify Warning] OTP check not approved for ${maskedPhone} (Status: ${verificationCheck.status})`);
    return {
      success: false,
      message: "Invalid or expired OTP",
    };
  } catch (error) {
    const code = error.code;
    let failureMsg = "Invalid or expired OTP";

    if (code === 60202) {
      failureMsg = "Maximum OTP verification attempts reached. Please request a new OTP.";
    } else if (code === 20404) {
      failureMsg = "Verification code expired or not found. Please request a new OTP.";
    } else if (code === 60200 || code === 21211) {
      failureMsg = `Invalid phone number format (${maskedPhone}).`;
    } else if (error.message) {
      failureMsg = error.message;
    }

    console.error(`[Twilio Verify Check Error] Phone: ${maskedPhone} | Code: ${code || "N/A"} | Error: ${error.message}`);
    return {
      success: false,
      message: failureMsg,
    };
  }
};

module.exports = {
  sendVerifyOtp,
  checkVerifyOtp,
  getVerifyConfig,
};
