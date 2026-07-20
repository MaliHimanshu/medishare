const express = require("express");

const router = express.Router();

router.post("/", async (req, res, next) => {
  try {
    const message = req.body?.message || "";

    return res.status(200).json({
      success: true,
      message: "Chatbot route is active.",
      data: {
        reply: message
          ? `You asked: "${message}". The chatbot endpoint is now connected and ready for AI integration.`
          : "Please send a message to the chatbot endpoint.",
      },
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
