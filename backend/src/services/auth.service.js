/**
 * Auth Service
 * ----------------
 * File: src/services/auth.service.js
 *
 * Handles authentication business logic.
 */

const bcrypt = require("bcryptjs");
const generateToken = require("../utils/generateToken");
const prisma = require("../config/prisma");

/**
 * Register User
 */
const registerUser = async (data) => {
  // Check if email already exists
  const existingUser = await prisma.user.findUnique({
    where: {
      email: data.email,
    },
  });

  if (existingUser) {
    throw new Error("Email already exists");
  }

  // Hash password
  const hashedPassword = await bcrypt.hash(data.password, 10);

  // Create user
  const user = await prisma.user.create({
    data: {
      name: data.name,
      email: data.email,
      password: hashedPassword,
      phone: data.phone,
      address: data.address,
      role: data.role,
    },
  });

  // Remove password before returning
  const { password, ...userWithoutPassword } = user;

  return {
    user: userWithoutPassword,
    token: generateToken(user),
  };
};

/**
 * Login User
 */
const loginUser = async (email, password) => {
  const user = await prisma.user.findUnique({
    where: {
      email,
    },
  });

  if (!user) {
    throw new Error("Invalid email or password");
  }

  const isMatch = await bcrypt.compare(password, user.password);

  if (!isMatch) {
    throw new Error("Invalid email or password");
  }

  const { password: pwd, ...userWithoutPassword } = user;

  return {
    user: userWithoutPassword,
    token: generateToken(user),
  };
};

module.exports = {
  registerUser,
  loginUser,
};