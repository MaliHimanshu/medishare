const { Server } = require("socket.io");
const jwt = require("jsonwebtoken");
const prisma = require("./config/prisma");

let io;

const initSocket = (server, app) => {
  io = new Server(server, {
    cors: {
      origin: "*", // allow flutter client
      methods: ["GET", "POST"]
    }
  });

  // Make io available to controllers (already done via app.set('io', io) in server.js)
  
  // Middleware for auth
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth.token;
      if (!token) return next(new Error("Authentication error"));

      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      
      const user = await prisma.user.findUnique({ where: { id: decoded.id } });
      if (!user) return next(new Error("User not found"));

      socket.user = user;
      next();
    } catch (err) {
      next(new Error("Authentication error"));
    }
  });

  io.on("connection", (socket) => {
    console.log(`🔌 Socket connected: ${socket.user.name} (${socket.id})`);
    
    // Join a personal room for user-specific events
    socket.join(`user_${socket.user.id}`);
    
    // Broadcast online status to others
    socket.broadcast.emit("user:online", { userId: socket.user.id });

    // Join conversation rooms
    socket.on("conversation:join", (conversationId) => {
      socket.join(`conversation_${conversationId}`);
      console.log(`User ${socket.user.name} joined conversation ${conversationId}`);
    });

    socket.on("conversation:leave", (conversationId) => {
      socket.leave(`conversation_${conversationId}`);
    });

    // Typing indicators
    socket.on("typing:start", ({ conversationId }) => {
      socket.to(`conversation_${conversationId}`).emit("typing:start", { conversationId, userId: socket.user.id });
    });

    socket.on("typing:stop", ({ conversationId }) => {
      socket.to(`conversation_${conversationId}`).emit("typing:stop", { conversationId, userId: socket.user.id });
    });

    socket.on("disconnect", () => {
      console.log(`🔌 Socket disconnected: ${socket.user.name} (${socket.id})`);
      socket.broadcast.emit("user:offline", { userId: socket.user.id, lastSeen: new Date() });
    });
  });

  return io;
};

module.exports = { initSocket };
