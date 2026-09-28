/**
 * Twilio Verify Service
 * ---------------------
 * File: src/services/twilioVerify.service.js
 *
 * Handles sending and checking phone OTP verification using Twilio Verify API.
 * Never logs or prints auth tokens, OTP codes, or secrets.
 */

const twilio = require("twilio");
const { normalizePhoneNumber } = require("../utils/phone.utils");

/**
 * Read and validate Twilio Verify configuration from process.env
 */
const getVerifyConfig = () => {
  const accountSid = process.env.TWILIO_ACCOUNT_SID;
  const authToken = process.env.TWILIO_AUTH_TOKEN;
  const serviceSid = process.env.TWILIO_VERIFY_SERVICE_SID;

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
  const config = getVerifyConfig();

  if (!config.isConfigured) {
    throw new Error(
      `Twilio Verify is not configured. Missing: ${config.missing.join(", ")}`
    );
  }

  const client = getTwilioClient();

  try {
    const verification = await client.verify.v2
      .services(config.serviceSid)
      .verifications.create({
        to: normalizedPhone,
        channel: "sms",
      });

    return {
      success: true,
      to: normalizedPhone,
      status: verification.status,
    };
  } catch (error) {
    const code = error.code;
    let friendlyMessage = "Unable to send verification OTP.";

    if (code === 60200 || code === 21211) {
      friendlyMessage = `Invalid phone number format (${normalizedPhone}). Please enter a valid 10-digit mobile number.`;
    } else if (code === 60203) {
      friendlyMessage = "Max OTP send attempts reached for this phone number. Please try again later.";
    } else if (code === 21608) {
      friendlyMessage = `Twilio Trial Account: The number ${normalizedPhone} must be verified in your Twilio Console (Verified Caller IDs).`;
    } else if (code === 21408) {
      friendlyMessage = "Twilio geo-permission error: SMS to India is not enabled in your Twilio Verify settings.";
    } else if (code === 20003 || error.status === 401) {
      friendlyMessage = "Twilio authentication error: Please verify your TWILIO_ACCOUNT_SID and TWILIO_AUTH_TOKEN.";
    } else if (code === 20404) {
      friendlyMessage = "Twilio Verify service not found. Please verify your TWILIO_VERIFY_SERVICE_SID.";
    } else if (code === 20429) {
      friendlyMessage = "Rate limit reached. Please wait a moment before trying again.";
    } else if (error.message) {
      friendlyMessage = error.message;
    }

    console.error(`[Twilio Verify Send Error] Code: ${code || "N/A"} - ${friendlyMessage}`);
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
  const config = getVerifyConfig();

  if (!config.isConfigured) {
    throw new Error(
      `Twilio Verify is not configured. Missing: ${config.missing.join(", ")}`
    );
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
      return {
        success: true,
        status: verificationCheck.status,
      };
    }

    return {
      success: false,
      message: "Invalid or expired OTP",
    };
  } catch (error) {
    const code = error.code;

    // Twilio error 20404 = Verification expired or not found
    if (code === 20404) {
      return {
        success: false,
        message: "Invalid or expired OTP",
      };
    }

    // Twilio error 60202 = Max check attempts reached
    if (code === 60202) {
      return {
        success: false,
        message: "Too many incorrect attempts. Please request a new OTP.",
      };
    }

    console.error(`[Twilio Verify Check Error] Code: ${code || "N/A"}`);
    return {
      success: false,
      message: "Invalid or expired OTP",
    };
  }
};

module.exports = {
  sendVerifyOtp,
  checkVerifyOtp,
  getVerifyConfig,
};
