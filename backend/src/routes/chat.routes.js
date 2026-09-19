const express = require("express");
const router = express.Router();
const chatController = require("../controllers/chat.controller");
const protect = require("../middleware/auth.middleware");

// All chat routes require authentication
router.use(protect);

// Get conversations & create conversation
router.get("/conversations", chatController.getConversations);
router.post("/conversations", chatController.getOrCreateConversation);

// Specific conversation details
router.get("/conversations/:id", chatController.getConversationDetails);

// Messages in a conversation
router.get("/conversations/:id/messages", chatController.getMessages);
router.post("/conversations/:id/messages", chatController.sendMessage);
router.patch("/conversations/:id/read", chatController.markAsRead);

// Search users
router.get("/users/search", chatController.searchUsers);

module.exports = router;
