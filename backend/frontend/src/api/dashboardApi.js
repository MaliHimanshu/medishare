// src/api/dashboardApi.js
import axiosClient from './axiosClient';

/**
 * GET /api/dashboard/summary
 * @returns {{ success, data }}
 */
export const getDashboardSummary = async () => {
  const response = await axiosClient.get('/dashboard/summary');
  return response.data;
};

/**
 * GET /api/dashboard/recent-requests
 * @returns {{ success, data }}
 */
export const getRecentRequests = async () => {
  const response = await axiosClient.get('/dashboard/recent-requests');
  return response.data;
};

/**
 * GET /api/dashboard/recent-donations
 * @returns {{ success, data }}
 */
export const getRecentDonations = async () => {
  const response = await axiosClient.get('/dashboard/recent-donations');
  return response.data;
};

/**
 * GET /api/dashboard/recent-notifications
 * @returns {{ success, data }}
 */
export const getRecentNotifications = async () => {
  const response = await axiosClient.get('/dashboard/recent-notifications');
  return response.data;
};
