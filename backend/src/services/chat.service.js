const prisma = require("../config/prisma");

// Create or get an existing 1-to-1 conversation
const getOrCreateConversation = async (userId1, userId2) => {
  if (userId1 === userId2) throw new Error("Cannot chat with yourself");

  // Try to find an existing conversation containing both users
  const existing = await prisma.conversation.findFirst({
    where: {
      AND: [
        { participants: { some: { userId: userId1 } } },
        { participants: { some: { userId: userId2 } } },
      ],
    },
    include: {
      participants: {
        include: {
          user: { select: { id: true, name: true, email: true, profileImage: true, role: true } }
        }
      }
    }
  });

  if (existing) {
    return existing;
  }

  // Create a new conversation
  const newConversation = await prisma.conversation.create({
    data: {
      participants: {
        create: [
          { userId: userId1 },
          { userId: userId2 },
        ]
      }
    },
    include: {
      participants: {
        include: {
          user: { select: { id: true, name: true, email: true, profileImage: true, role: true } }
        }
      }
    }
  });

  return newConversation;
};

// Get all conversations for a user
const getUserConversations = async (userId) => {
  return await prisma.conversation.findMany({
    where: {
      participants: {
        some: { userId: userId }
      }
    },
    include: {
      participants: {
        include: {
          user: {
            select: { id: true, name: true, email: true, profileImage: true, role: true }
          }
        }
      },
      messages: {
        orderBy: { createdAt: 'desc' },
        take: 1,
      }
    },
    orderBy: {
      updatedAt: 'desc'
    }
  });
};

// Get a specific conversation
const getConversationById = async (conversationId, userId) => {
  return await prisma.conversation.findFirst({
    where: {
      id: conversationId,
      participants: { some: { userId: userId } }
    },
    include: {
      participants: {
        include: {
          user: {
            select: { id: true, name: true, email: true, profileImage: true, role: true }
          }
        }
      }
    }
  });
};

// Get messages for a conversation
const getMessages = async (conversationId, userId, limit = 50, cursor) => {
  // Ensure user is participant
  const isParticipant = await prisma.conversationParticipant.findUnique({
    where: {
      conversationId_userId: { conversationId, userId }
    }
  });

  if (!isParticipant) {
    throw new Error("Unauthorized");
  }

  const query = {
    where: { conversationId },
    take: limit,
    orderBy: { createdAt: 'desc' },
  };

  if (cursor) {
    query.cursor = { id: cursor };
    query.skip = 1; // Skip the cursor itself
  }

  return await prisma.message.findMany(query);
};

// Send a message
const sendMessage = async (conversationId, senderId, content, messageType = "TEXT") => {
  // Verify participant
  const isParticipant = await prisma.conversationParticipant.findUnique({
    where: {
      conversationId_userId: { conversationId, userId: senderId }
    }
  });

  if (!isParticipant) {
    throw new Error("Unauthorized");
  }

  const message = await prisma.message.create({
    data: {
      conversationId,
      senderId,
      content,
      messageType,
    }
  });

  // Update conversation updatedAt
  await prisma.conversation.update({
    where: { id: conversationId },
    data: { updatedAt: new Date() }
  });

  return message;
};

// Mark conversation as read
const markAsRead = async (conversationId, userId) => {
  // 1. Update Participant lastReadAt
  await prisma.conversationParticipant.update({
    where: {
      conversationId_userId: { conversationId, userId }
    },
    data: {
      lastReadAt: new Date()
    }
  });

  // 2. Mark messages sent by OTHERS as read
  await prisma.message.updateMany({
    where: {
      conversationId,
      senderId: { not: userId },
      isRead: false
    },
    data: {
      isRead: true
    }
  });

  return { success: true };
};

// Search users
const searchUsers = async (query, currentUserId) => {
  const where = {
    id: { not: currentUserId },
  };

  if (query && query.trim().length > 0) {
    const q = query.trim();
    where.OR = [
      { name: { contains: q, mode: 'insensitive' } },
      { email: { contains: q, mode: 'insensitive' } },
      { role: { contains: q, mode: 'insensitive' } },
      { phone: { contains: q, mode: 'insensitive' } },
    ];
  }

  return await prisma.user.findMany({
    where,
    select: {
      id: true,
      name: true,
      email: true,
      phone: true,
      role: true,
      profileImage: true,
      verificationStatus: true,
      createdAt: true,
    },
    take: 50,
    orderBy: { createdAt: 'desc' },
  });
};

module.exports = {
  getOrCreateConversation,
  getUserConversations,
  getConversationById,
  getMessages,
  sendMessage,
  markAsRead,
  searchUsers
};
