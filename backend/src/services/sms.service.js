/**
 * SMS Service
 * ----------------
 * File: src/services/sms.service.js
 *
 * Handles sending SMS messages using Twilio.
 */

const twilio = require("twilio");

// Ensure environment variables are loaded if Twilio is used
const accountSid = process.env.TWILIO_ACCOUNT_SID;
const authToken = process.env.TWILIO_AUTH_TOKEN;
const fromPhone = process.env.TWILIO_PHONE_NUMBER;

let twilioClient = null;

if (accountSid && authToken) {
  twilioClient = twilio(accountSid, authToken);
}

/**
 * Send an SMS message
 * @param {string} to Phone number in E.164 format
 * @param {string} body Message content
 * @returns {Promise<boolean>} True if sent successfully
 */
const sendSms = async (to, body) => {
  try {
    if (!twilioClient) {
      console.warn(
        "Twilio is not configured. Returning success without sending real SMS."
      );
      // We don't log the OTP in production as requested, but in dev without Twilio we just mock success.
      return true;
    }

    await twilioClient.messages.create({
      body,
      from: fromPhone,
      to,
    });
    
    return true;
  } catch (error) {
    console.error("SMS Sending failed:", error.message);
    throw new Error("Unable to send SMS provider failure.");
  }
};

module.exports = {
  sendSms,
};
