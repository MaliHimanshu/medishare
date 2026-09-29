/**
 * Email Service
 * ----------------
 * File: src/services/email.service.js
 *
 * Handles sending emails and OTP verification codes via Nodemailer using Gmail SMTP.
 * Authenticates only with process.env.GMAIL_USER and process.env.GMAIL_APP_PASSWORD.
 */

const nodemailer = require("nodemailer");

/**
 * Get and validate Gmail configuration from environment variables
 */
const getEmailConfig = () => {
  const user = process.env.GMAIL_USER ? process.env.GMAIL_USER.trim() : "";
  const pass = process.env.GMAIL_APP_PASSWORD
    ? process.env.GMAIL_APP_PASSWORD.trim().replace(/\s+/g, "")
    : "";

  const missing = [];
  if (!user) missing.push("GMAIL_USER");
  if (!pass) missing.push("GMAIL_APP_PASSWORD");

  return {
    host: "smtp.gmail.com",
    port: 465,
    secure: true,
    user,
    pass,
    from: user ? `"MediShare" <${user}>` : '"MediShare"',
    missing,
    isConfigured: missing.length === 0,
  };
};

let transporterInstance = null;
let cachedUser = null;
let cachedPass = null;

/**
 * Get or create Nodemailer transporter configured for Gmail
 */
const getTransporter = () => {
  const config = getEmailConfig();
  if (!config.isConfigured) return null;

  if (!transporterInstance || cachedUser !== config.user || cachedPass !== config.pass) {
    transporterInstance = nodemailer.createTransport({
      host: "smtp.gmail.com",
      port: 465,
      secure: true,
      auth: {
        user: config.user,
        pass: config.pass,
      },
    });
    cachedUser = config.user;
    cachedPass = config.pass;
  }

  return transporterInstance;
};

/**
 * Send 6-digit OTP verification code to a Gmail address
 * @param {string} toEmail - Destination email
 * @param {string} otp - 6-digit OTP code
 * @param {object} [options] - Optional custom subject and message
 */
const sendEmailOtp = async (toEmail, otp, options = {}) => {
  const config = getEmailConfig();

  if (!config.isConfigured) {
    throw new Error(
      `Gmail service is not configured. Missing required environment variable(s): ${config.missing.join(", ")}`
    );
  }

  const transporter = getTransporter();
  if (!transporter) {
    throw new Error("Failed to initialize Gmail SMTP transporter");
  }

  const subject = options.subject || "MediShare Verification Code";
  const messageText =
    options.message ||
    "Use the verification code below to complete your MediShare verification:";

  const htmlContent = `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 24px; border: 1px solid #e2e8f0; border-radius: 12px; background-color: #ffffff;">
      <div style="text-align: center; margin-bottom: 24px;">
        <h2 style="color: #0077B6; margin: 0; font-size: 24px; font-weight: 800;">MediShare</h2>
        <p style="color: #64748b; font-size: 14px; margin-top: 4px;">Medical Equipment Sharing Platform</p>
      </div>
      <div style="padding: 20px; background-color: #f8fafc; border-radius: 8px;">
        <p style="color: #1e293b; font-size: 15px; margin: 0 0 16px;">Hello,</p>
        <p style="color: #334155; font-size: 14px; line-height: 1.6; margin: 0 0 20px;">
          ${messageText}
        </p>
        <div style="text-align: center; margin: 28px 0;">
          <span style="font-size: 32px; font-weight: 800; letter-spacing: 8px; color: #0077B6; background: #e0f2fe; padding: 12px 28px; border-radius: 10px; display: inline-block; font-family: monospace;">
            ${otp}
          </span>
        </div>
        <p style="color: #64748b; font-size: 13px; margin: 20px 0 0; text-align: center;">
          This verification code is valid for <strong>5 minutes</strong>.
        </p>
      </div>
      <p style="color: #94a3b8; font-size: 12px; margin-top: 24px; line-height: 1.5; text-align: center;">
        If you did not request this verification code, please ignore this email or contact support if you have concerns.
      </p>
    </div>
  `;

  try {
    await transporter.sendMail({
      from: config.from,
      to: toEmail,
      subject,
      text: `${messageText}\n\nYour MediShare verification code is: ${otp}\n\nThis verification code is valid for 5 minutes. If you did not request this, please ignore this email.`,
      html: htmlContent,
    });

    console.log(`[Email Service] OTP successfully sent to ${toEmail}`);
    return { success: true, method: "gmail_smtp" };
  } catch (err) {
    console.error(`[Email Service Error] Failed to send email to ${toEmail}:`, err.message);
    throw new Error(`Failed to send email OTP: ${err.message}`);
  }
};

module.exports = {
  getEmailConfig,
  getTransporter,
  sendEmailOtp,
};
