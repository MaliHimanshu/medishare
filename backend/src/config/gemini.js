/**
 * Gemini AI Configuration
 * ------------------------
 * File: src/config/gemini.js
 *
 * Initializes and exports the Google Gemini AI client.
 *
 * Design Decision:
 * - All AI provider logic is isolated in this file.
 * - If the provider changes (e.g., OpenAI, Claude), only
 *   this file and the service need to change — controllers
 *   and routes remain untouched.
 *
 * Required Environment Variables:
 * - GEMINI_API_KEY → Your Google Gemini API key
 *
 * @see https://ai.google.dev/gemini-api/docs
 */

const { GoogleGenerativeAI } = require("@google/generative-ai");

// ─────────────────────────────────────────────
// Validate API Key at Startup
// ─────────────────────────────────────────────

/**
 * Fail fast if the API key is missing.
 * Prevents silent failures at runtime when the first chat is sent.
 */
if (!process.env.GEMINI_API_KEY) {
  throw new Error(
    "[Gemini Config] GEMINI_API_KEY is missing from environment variables. " +
      "Please add it to your .env file."
  );
}

// ─────────────────────────────────────────────
// Initialize Gemini Client
// ─────────────────────────────────────────────

/** Main Gemini client instance — initialized once, reused across requests */
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

// ─────────────────────────────────────────────
// Model Configuration
// ─────────────────────────────────────────────

/**
 * The Gemini model to use for chat completions.
 *
 * gemini-1.5-flash → Fast, cost-efficient, ideal for chatbots.
 * gemini-1.5-pro   → More capable, better for complex reasoning.
 *
 * Change this value here to switch models globally.
 */
const GEMINI_MODEL = "gemini-1.5-flash";

// ─────────────────────────────────────────────
// System Prompt (MediShare Context)
// ─────────────────────────────────────────────

/**
 * The system instruction that defines the chatbot's personality,
 * scope, and behavior for MediShare.
 *
 * This is injected into every conversation to keep the AI
 * focused on the project domain.
 */
const MEDISHARE_SYSTEM_PROMPT = `
You are MediBot, the friendly AI assistant for MediShare — a Medical Equipment Donation and Request System.

Your role is to help users with:
1. Medical equipment information (types, uses, care instructions)
2. How to donate medical equipment through MediShare
3. How to request medical equipment through MediShare
4. Finding hospitals and medical centers on the platform
5. Managing user profiles and account settings
6. Understanding donation and request statuses
7. Frequently asked questions about MediShare
8. General healthcare equipment guidance

Guidelines:
- Always be helpful, empathetic, and professional.
- Keep responses clear, concise, and easy to understand.
- If a user asks about the donation process, explain: Register → List Equipment → Submit → Approval → Completion.
- If a user asks about the request process, explain: Register → Browse Equipment → Submit Request → Owner Approval → Completion.
- If a user asks for personal medical advice, diagnosis, or treatment recommendations, politely decline and say:
  "I'm not able to provide personal medical advice. Please consult a qualified healthcare professional for medical concerns."
- If a question is completely unrelated to MediShare or healthcare equipment, politely redirect:
  "That's outside my area of expertise. I'm here to help with MediShare and medical equipment questions."
- Never make up information about specific hospitals, users, or equipment in the system.
- Always encourage users to contact support for account-specific issues.

Tone: Warm, professional, and supportive.
`.trim();

// ─────────────────────────────────────────────
// Factory Function
// ─────────────────────────────────────────────

/**
 * Creates and returns a configured Gemini generative model instance.
 *
 * Uses systemInstruction to lock the model to MediShare's context.
 * Called once per chat request in the service layer.
 *
 * @returns {GenerativeModel} Configured Gemini model instance
 */
const getGeminiModel = () => {
  return genAI.getGenerativeModel({
    model: GEMINI_MODEL,
    systemInstruction: MEDISHARE_SYSTEM_PROMPT,
  });
};

// ─────────────────────────────────────────────
// Exports
// ─────────────────────────────────────────────

module.exports = {
  getGeminiModel,
  GEMINI_MODEL,
};
