/**
 * SMS Service
 * ----------------
 * File: src/services/sms.service.js
 *
 * Handles sending live SMS messages using Twilio.
 * Bypassing or mocking SMS delivery is strictly disabled in both
 * development and production environments.
 */

const twilio = require("twilio");
const { normalizePhoneNumber } = require("../utils/phone.utils");

/**
 * Check and retrieve Twilio configuration from environment variables
 */
const getTwilioConfig = () => {
  const accountSid = process.env.TWILIO_ACCOUNT_SID;
  const authToken = process.env.TWILIO_AUTH_TOKEN;
  const fromPhone = process.env.TWILIO_PHONE_NUMBER;

  const missing = [];
  if (!accountSid || !accountSid.trim()) missing.push("TWILIO_ACCOUNT_SID");
  if (!authToken || !authToken.trim()) missing.push("TWILIO_AUTH_TOKEN");
  if (!fromPhone || !fromPhone.trim()) missing.push("TWILIO_PHONE_NUMBER");

  return {
    accountSid: accountSid ? accountSid.trim() : null,
    authToken: authToken ? authToken.trim() : null,
    fromPhone: fromPhone ? fromPhone.trim() : null,
    missing,
    isConfigured: missing.length === 0,
  };
};

/**
 * Get initialized Twilio client instance
 */
const getTwilioClient = () => {
  const config = getTwilioConfig();
  if (!config.isConfigured) {
    throw new Error(
      `SMS Gateway not configured. Missing required environment variable(s): ${config.missing.join(", ")}`
    );
  }
  return twilio(config.accountSid, config.authToken);
};

/**
 * Send an SMS message using Twilio
 * @param {string} to Destination phone number (normalized to E.164)
 * @param {string} body Message content
 * @returns {Promise<object>} Result containing message SID and status
 */
const sendSms = async (to, body) => {
  const config = getTwilioConfig();
  if (!config.isConfigured) {
    throw new Error(
      `SMS provider not configured. Missing required environment variable(s): ${config.missing.join(", ")}`
    );
  }

  // Ensure both sender and recipient are in strict E.164 format
  let normalizedTo;
  let normalizedFrom;
  try {
    normalizedTo = normalizePhoneNumber(to);
  } catch (err) {
    throw new Error(`Invalid destination phone number: ${err.message}`);
  }

  try {
    normalizedFrom = normalizePhoneNumber(config.fromPhone);
  } catch (err) {
    throw new Error(`Invalid Twilio sender phone number configured: ${err.message}`);
  }

  const client = getTwilioClient();

  try {
    const message = await client.messages.create({
      body,
      from: normalizedFrom,
      to: normalizedTo,
    });

    if (!message || !message.sid) {
      throw new Error("SMS provider did not return a valid message confirmation.");
    }

    // Check Twilio message status
    if (message.status === "failed" || message.status === "undelivered") {
      throw new Error(
        `SMS delivery failed with status '${message.status}': ${message.errorMessage || "Unknown provider error"}`
      );
    }

    return {
      success: true,
      messageSid: message.sid,
      status: message.status,
    };
  } catch (error) {
    // Map Twilio error codes to explicit, user-friendly error messages
    const twilioCode = error.code;
    let errorMessage = "Unable to send SMS: provider rejected the request.";

    if (twilioCode === 20003) {
      errorMessage = "Twilio authentication error: Invalid Account SID or Auth Token.";
    } else if (twilioCode === 21211) {
      errorMessage = `Invalid destination phone number format (${normalizedTo}).`;
    } else if (twilioCode === 21606 || twilioCode === 21659) {
      errorMessage = "Twilio sender phone number is invalid or not enabled for SMS.";
    } else if (twilioCode === 21608) {
      errorMessage = `Twilio Trial Account Restriction: Phone number ${normalizedTo} is not verified. Please verify it in the Twilio Console (Phone Numbers > Verified Caller IDs).`;
    } else if (twilioCode === 21614) {
      errorMessage = `Destination number ${normalizedTo} cannot receive SMS messages.`;
    } else if (twilioCode === 21408) {
      errorMessage = "Twilio geo-permission error: SMS to this country/region is not enabled in your Twilio account.";
    } else if (twilioCode === 20429) {
      errorMessage = "Twilio rate limit exceeded. Please wait a moment before trying again.";
    } else if (twilioCode === 21610) {
      errorMessage = "Recipient number has unsubscribed from receiving messages from this number.";
    } else if (error.status === 401) {
      errorMessage = "Twilio authentication failed: Check TWILIO_ACCOUNT_SID and TWILIO_AUTH_TOKEN.";
    } else if (error.status === 403) {
      errorMessage = `Twilio access denied: ${error.message || "Account restricted or insufficient balance."}`;
    } else if (error.status === 400 && error.message) {
      errorMessage = `Twilio request error: ${error.message}`;
    } else if (error.code === "ENOTFOUND" || error.code === "ECONNREFUSED" || error.code === "ETIMEDOUT") {
      errorMessage = "Network error: Unable to connect to Twilio SMS API.";
    } else if (error.message) {
      errorMessage = error.message;
    }

    console.error(`[SMS Service Error] Code: ${twilioCode || "N/A"} - ${errorMessage}`);
    throw new Error(errorMessage);
  }
};

module.exports = {
  sendSms,
  getTwilioConfig,
};
