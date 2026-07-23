// src/api/hospitalApi.js
import axiosClient from './axiosClient';

/**
 * GET /api/hospital
 * @param {object} params - page, limit, city, state, search
 * @returns {{ success, hospitals, total, page, limit }}
 */
export const getAllHospitals = async (params = {}) => {
  const response = await axiosClient.get('/hospital', { params });
  return response.data;
};

/**
 * POST /api/hospital
 * @param {object} data
 */
export const createHospital = async (data) => {
  const response = await axiosClient.post('/hospital', data);
  return response.data;
};
