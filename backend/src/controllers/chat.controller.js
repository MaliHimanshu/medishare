const chatService = require("../services/chat.service");

// Create or get conversation
const getOrCreateConversation = async (req, res) => {
  try {
    const userId = req.body.userId || req.body.recipientId; // The user they want to chat with
    const currentUserId = req.user.id;

    if (!userId) {
      return res.status(400).json({ success: false, message: "Target userId is required" });
    }

    const conversation = await chatService.getOrCreateConversation(currentUserId, userId);
    return res.status(200).json({ success: true, data: conversation });
  } catch (error) {
    return res.status(400).json({ success: false, message: error.message });
  }
};

// Get all conversations
const getConversations = async (req, res) => {
  try {
    const currentUserId = req.user.id;
    const conversations = await chatService.getUserConversations(currentUserId);
    return res.status(200).json({ success: true, data: conversations });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// Get specific conversation
const getConversationDetails = async (req, res) => {
  try {
    const conversationId = req.params.id;
    const currentUserId = req.user.id;
    
    const conversation = await chatService.getConversationById(conversationId, currentUserId);
    if (!conversation) {
      return res.status(404).json({ success: false, message: "Conversation not found" });
    }

    return res.status(200).json({ success: true, data: conversation });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// Get messages
const getMessages = async (req, res) => {
  try {
    const conversationId = req.params.id;
    const currentUserId = req.user.id;
    const limit = parseInt(req.query.limit) || 50;
    const cursor = req.query.cursor;

    const messages = await chatService.getMessages(conversationId, currentUserId, limit, cursor);
    return res.status(200).json({ success: true, data: messages });
  } catch (error) {
    if (error.message === "Unauthorized") {
      return res.status(403).json({ success: false, message: "Not a participant" });
    }
    return res.status(500).json({ success: false, message: error.message });
  }
};

// Send message
const sendMessage = async (req, res) => {
  try {
    const conversationId = req.params.id;
    const senderId = req.user.id;
    const { content, messageType } = req.body;

    if (!content || content.trim().length === 0) {
      return res.status(400).json({ success: false, message: "Message content cannot be empty" });
    }

    const message = await chatService.sendMessage(conversationId, senderId, content.trim(), messageType);
    
    // Get the socket.io instance from req.app (set in server.js)
    const io = req.app.get("io");
    if (io) {
      // Emit to specific conversation room
      io.to(`conversation_${conversationId}`).emit("message:new", message);
      
      // Also emit to all participants' personal rooms so the chat list updates
      const conversation = await chatService.getConversationById(conversationId, senderId);
      if (conversation && conversation.participants) {
        conversation.participants.forEach(p => {
          io.to(`user_${p.userId}`).emit("message:new", message);
        });
      }
    }

    return res.status(201).json({ success: true, data: message });
  } catch (error) {
    if (error.message === "Unauthorized") {
      return res.status(403).json({ success: false, message: "Not a participant" });
    }
    return res.status(500).json({ success: false, message: error.message });
  }
};

// Mark as read
const markAsRead = async (req, res) => {
  try {
    const conversationId = req.params.id;
    const currentUserId = req.user.id;

    await chatService.markAsRead(conversationId, currentUserId);
    
    // Notify via socket
    const io = req.app.get("io");
    if (io) {
      io.to(`conversation_${conversationId}`).emit("message:read", { conversationId, readBy: currentUserId });
    }

    return res.status(200).json({ success: true, message: "Marked as read" });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// Search users
const searchUsers = async (req, res) => {
  try {
    const query = req.query.q || "";
    const currentUserId = req.user.id;

    if (query.trim().length === 0) {
      return res.status(200).json({ success: true, data: [] });
    }

    const users = await chatService.searchUsers(query.trim(), currentUserId);
    return res.status(200).json({ success: true, data: users });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  getOrCreateConversation,
  getConversations,
  getConversationDetails,
  getMessages,
  sendMessage,
  markAsRead,
  searchUsers
};
