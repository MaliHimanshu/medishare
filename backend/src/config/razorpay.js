const Razorpay = require("razorpay");

const getRazorpayInstance = () => {
  const key_id = process.env.RAZORPAY_KEY_ID;
  const key_secret = process.env.RAZORPAY_KEY_SECRET;

  if (!key_id || !key_secret) {
    console.warn(
      "⚠️ Razorpay Key ID or Key Secret is not set in environment variables."
    );
  }

  return new Razorpay({
    key_id: key_id || "rzp_test_dummy",
    key_secret: key_secret || "dummy_secret",
  });
};

module.exports = {
  getRazorpayInstance,
};
