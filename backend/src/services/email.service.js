/**
 * Email Service
 * ----------------
 * File: src/services/email.service.js
 *
 * Handles sending emails and OTP verification codes via Nodemailer.
 * Reads SMTP credentials from environment variables.
 */

const nodemailer = require("nodemailer");

/**
 * Get and validate email configuration from environment variables
 */
const getEmailConfig = () => {
  const host = process.env.SMTP_HOST || process.env.EMAIL_HOST;
  const port = parseInt(process.env.SMTP_PORT || process.env.EMAIL_PORT || "587", 10);
  const user = process.env.SMTP_USER || process.env.EMAIL_USER;
  const pass = process.env.SMTP_PASS || process.env.EMAIL_PASS || process.env.EMAIL_PASSWORD;
  const from = process.env.SMTP_FROM || process.env.EMAIL_FROM || (user ? `"MediShare" <${user}>` : '"MediShare" <noreply@medishare.org>');

  const missing = [];
  if (!host) missing.push("SMTP_HOST");
  if (!user) missing.push("SMTP_USER");
  if (!pass) missing.push("SMTP_PASS");

  return {
    host,
    port,
    user,
    pass,
    from,
    missing,
    isConfigured: missing.length === 0,
  };
};

let transporterInstance = null;

const getTransporter = () => {
  const config = getEmailConfig();
  if (!config.isConfigured) return null;

  if (!transporterInstance) {
    transporterInstance = nodemailer.createTransport({
      host: config.host,
      port: config.port,
      secure: config.port === 465,
      auth: {
        user: config.user,
        pass: config.pass,
      },
    });
  }
  return transporterInstance;
};

/**
 * Send 6-digit OTP verification code to an email address
 * @param {string} toEmail - Destination email
 * @param {string} otp - 6-digit OTP code
 */
const sendEmailOtp = async (toEmail, otp) => {
  const config = getEmailConfig();
  const transporter = getTransporter();

  // If live SMTP is configured, send the real email
  if (transporter && config.isConfigured) {
    const htmlContent = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 24px; border: 1px solid #e2e8f0; border-radius: 12px; background-color: #ffffff;">
        <div style="text-align: center; margin-bottom: 24px;">
          <h2 style="color: #0077B6; margin: 0; font-size: 24px; font-weight: 800;">MediShare</h2>
          <p style="color: #64748b; font-size: 14px; margin-top: 4px;">Medical Equipment Sharing Platform</p>
        </div>
        <div style="padding: 20px; background-color: #f8fafc; border-radius: 8px;">
          <p style="color: #1e293b; font-size: 15px; margin: 0 0 16px;">Hello,</p>
          <p style="color: #334155; font-size: 14px; line-height: 1.6; margin: 0 0 20px;">
            We received a request to reset the password for your MediShare account. Use the verification code below to complete your password reset:
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
          If you did not request a password reset, please ignore this email or contact support if you have concerns.
        </p>
      </div>
    `;

    try {
      await transporter.sendMail({
        from: config.from,
        to: toEmail,
        subject: `MediShare Password Reset Code: ${otp}`,
        text: `Your MediShare password reset verification code is: ${otp}. It will expire in 5 minutes.`,
        html: htmlContent,
      });
      console.log(`[Email Service] Password reset OTP sent to ${toEmail}`);
      return { success: true, method: "smtp" };
    } catch (err) {
      console.error(`[Email Service Error] Failed to send email to ${toEmail}:`, err.message);
      throw new Error(`Failed to send email OTP: ${err.message}`);
    }
  }

  // If SMTP is NOT configured
  if (process.env.NODE_ENV === "production") {
    throw new Error(
      `Email service not configured. Missing required environment variable(s): ${config.missing.join(", ")}`
    );
  }

  // Development mode fallback: log OTP to console
  console.log(`\n==================================================`);
  console.log(`[Email Service - DEV MODE]`);
  console.log(`Recipient: ${toEmail}`);
  console.log(`OTP Code : ${otp}`);
  console.log(`Expires in: 5 minutes`);
  console.log(`==================================================\n`);

  return { success: true, method: "dev_console", otp };
};

module.exports = {
  getEmailConfig,
  sendEmailOtp,
};
