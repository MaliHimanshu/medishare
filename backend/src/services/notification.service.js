const prisma = require("../config/prisma");

// Create Notification
const createNotification = async (data) => {
  return prisma.notification.create({
    data,
  });
};

// Get Notifications of Logged-in User
const getMyNotifications = async (userId, query) => {
  const { page = 1, limit = 10 } = query;

  const notifications = await prisma.notification.findMany({
    where: {
      userId,
    },
    skip: (page - 1) * limit,
    take: limit,
    orderBy: {
      createdAt: "desc",
    },
  });

  const total = await prisma.notification.count({
    where: {
      userId,
    },
  });

  return {
    total,
    page,
    limit,
    notifications,
  };
};

// Mark as Read
const markAsRead = async (id, userId) => {
  const notification = await prisma.notification.findFirst({
    where: {
      id,
      userId,
    },
  });

  if (!notification) {
    throw new Error("Notification not found.");
  }

  return prisma.notification.update({
    where: {
      id,
    },
    data: {
      isRead: true,
    },
  });
};

// Delete Notification
const deleteNotification = async (id, userId) => {
  const notification = await prisma.notification.findFirst({
    where: {
      id,
      userId,
    },
  });

  if (!notification) {
    throw new Error("Notification not found.");
  }

  await prisma.notification.delete({
    where: {
      id,
    },
  });

  return {
    success: true,
    message: "Notification deleted successfully.",
  };
};

module.exports = {
  createNotification,
  getMyNotifications,
  markAsRead,
  deleteNotification,
};