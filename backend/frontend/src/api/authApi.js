// src/api/authApi.js
import axiosClient from './axiosClient';

/**
 * POST /api/auth/register
 * @param {{ name, email, password, phone?, address?, role }} data
 * @returns {{ success, message, data: user, token }}
 */
export const registerUser = async (data) => {
  const response = await axiosClient.post('/auth/register', data);
  return response.data;
};

/**
 * POST /api/auth/login
 * @param {string} email
 * @param {string} password
 * @returns {{ success, message, data: user, token }}
 */
export const loginUser = async (email, password) => {
  const response = await axiosClient.post('/auth/login', { email, password });
  return response.data;
};

/**
 * GET /api/auth/me
 * @returns {{ success, data: user }}
 */
export const getMe = async () => {
  const response = await axiosClient.get('/auth/me');
  return response.data;
};
