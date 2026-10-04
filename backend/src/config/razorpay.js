const Razorpay = require("razorpay");

/**
 * Returns a configured Razorpay instance.
 * Throws an error if required environment variables are not set.
 */
const getRazorpayInstance = () => {
  const key_id = process.env.RAZORPAY_KEY_ID;
  const key_secret = process.env.RAZORPAY_KEY_SECRET;

  console.log("Razorpay configured:", {
    keyIdPresent: !!key_id,
    keySecretPresent: !!key_secret,
  });

  if (!key_id || !key_secret) {
    throw new Error(
      "Razorpay Key ID (RAZORPAY_KEY_ID) and Key Secret (RAZORPAY_KEY_SECRET) are missing in environment variables."
    );
  }

  return new Razorpay({
    key_id,
    key_secret,
  });
};

module.exports = { getRazorpayInstance };
