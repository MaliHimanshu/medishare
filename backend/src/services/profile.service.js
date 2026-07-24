/**
 * Profile Service
 * ----------------
 * File: src/services/profile.service.js
 *
 * Contains all business logic for profile management.
 * Controllers call these methods — keeping controllers thin.
 *
 * Methods:
 * - getUserProfile()
 * - updateProfile()
 * - changePassword()
 * - updateProfileImage()
 */

const bcrypt = require("bcrypt");
const prisma = require("../config/prisma");

// ─────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────

/** Number of salt rounds for bcrypt hashing */
const SALT_ROUNDS = 12;

/**
 * Fields to select when returning a user profile.
 * Explicitly excludes the password field for security.
 */
const SAFE_USER_SELECT = {
  id: true,
  name: true,
  email: true,
  phone: true,
  address: true,
  role: true,
  profileImage: true,
  createdAt: true,
  updatedAt: true,
};

// ─────────────────────────────────────────────
// Get User Profile
// ─────────────────────────────────────────────

/**
 * Retrieves the profile of the currently authenticated user.
 *
 * @param {string} userId - The ID of the authenticated user (from req.user)
 * @returns {Promise<Object>} - Safe user object (no password)
 * @throws {Error} - If user is not found
 */
const getUserProfile = async (userId) => {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: SAFE_USER_SELECT,
  });

  // Guard: user should always exist here (validated by auth middleware)
  // but we handle the edge case defensively
  if (!user) {
    const error = new Error("User not found");
    error.statusCode = 404;
    throw error;
  }

  return user;
};

// ─────────────────────────────────────────────
// Update Profile
// ─────────────────────────────────────────────

/**
 * Updates allowed profile fields (name, phone, address) for the user.
 * email, password, and role are intentionally not updatable here.
 *
 * @param {string} userId - The ID of the authenticated user
 * @param {Object} data   - Validated body: { name?, phone?, address? }
 * @returns {Promise<Object>} - Updated safe user object
 */
const updateProfile = async (userId, data) => {
  // Only pick the allowed fields — an extra safety layer beyond Zod
  const { name, phone, address, profileImage } = data;

  const updatedUser = await prisma.user.update({
    where: { id: userId },
    data: {
      // Only include fields that were actually sent in the request
      ...(name !== undefined && { name }),
      ...(phone !== undefined && { phone }),
      ...(address !== undefined && { address }),
      ...(profileImage !== undefined && { profileImage }),
    },
    select: SAFE_USER_SELECT,
  });

  return updatedUser;
};

// ─────────────────────────────────────────────
// Change Password
// ─────────────────────────────────────────────

/**
 * Verifies the old password and updates to the new hashed password.
 *
 * @param {string} userId      - The ID of the authenticated user
 * @param {string} oldPassword - The current plain-text password to verify
 * @param {string} newPassword - The new plain-text password to hash and save
 * @returns {Promise<void>}
 * @throws {Error} - If old password is incorrect or user not found
 */
const changePassword = async (userId, oldPassword, newPassword) => {
  // Fetch user including password for comparison
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { id: true, password: true },
  });

  if (!user) {
    const error = new Error("User not found");
    error.statusCode = 404;
    throw error;
  }

  // Verify old password against stored hash
  const isMatch = await bcrypt.compare(oldPassword, user.password);

  if (!isMatch) {
    const error = new Error("Old password is incorrect");
    error.statusCode = 400;
    throw error;
  }

  // Hash the new password before saving
  const hashedNewPassword = await bcrypt.hash(newPassword, SALT_ROUNDS);

  // Update password in database
  await prisma.user.update({
    where: { id: userId },
    data: { password: hashedNewPassword },
  });

  // No return value — controller will send generic success message
};

// ─────────────────────────────────────────────
// Update Profile Image
// ─────────────────────────────────────────────

/**
 * Saves the uploaded image file path to the user's profile.
 *
 * The actual file is already stored on disk by Multer middleware
 * before this service method is called.
 *
 * @param {string} userId    - The ID of the authenticated user
 * @param {string} imagePath - Relative path to the uploaded image (e.g. "uploads/profile/file.jpg")
 * @returns {Promise<Object>} - Updated safe user object with new profileImage
 */
const updateProfileImage = async (userId, imagePath) => {
  const updatedUser = await prisma.user.update({
    where: { id: userId },
    data: { profileImage: imagePath },
    select: SAFE_USER_SELECT,
  });

  return updatedUser;
};

// ─────────────────────────────────────────────
// Exports
// ─────────────────────────────────────────────

module.exports = {
  getUserProfile,
  updateProfile,
  changePassword,
  updateProfileImage,
};
