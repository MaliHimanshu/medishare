const Razorpay = require("razorpay");

/**
 * Returns a configured Razorpay instance.
 * Throws an error if required environment variables are not set.
 */
const getRazorpayInstance = () => {
  let key_id = process.env.RAZORPAY_KEY_ID ? process.env.RAZORPAY_KEY_ID.trim().replace(/^["']|["']$/g, "") : "";
  let key_secret = process.env.RAZORPAY_KEY_SECRET ? process.env.RAZORPAY_KEY_SECRET.trim().replace(/^["']|["']$/g, "") : "";

  console.log("[Razorpay Config]", {
    keyIdConfigured: !!key_id,
    keySecretConfigured: !!key_secret,
    keyPrefix: key_id ? key_id.substring(0, 9) : "none",
    keyLength: key_id ? key_id.length : 0,
    secretLength: key_secret ? key_secret.length : 0,
  });

  if (!key_id || !key_secret) {
    throw new Error(
      "Razorpay Key ID (RAZORPAY_KEY_ID) and Key Secret (RAZORPAY_KEY_SECRET) are missing or empty in environment variables."
    );
  }

  return new Razorpay({
    key_id,
    key_secret,
  });
};

module.exports = { getRazorpayInstance };
