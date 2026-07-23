const { askAI } = require("../services/chatbot.service");

const chat = async (req, res) => {
  try {
    const { message } = req.body;

    if (!message || message.trim() === "") {
      return res.status(400).json({
        success: false,
        message: "Message is required.",
      });
    }

    // Pass both the user's message and the authenticated user
    const response = await askAI(message, req.user);

    return res.status(200).json({
      success: true,
      response,
    });
  } catch (error) {
    console.error("Chatbot Controller Error:", error);

    return res.status(500).json({
      success: false,
      message: error.message || "Internal Server Error",
    });
  }
};

module.exports = {
  chat,
};