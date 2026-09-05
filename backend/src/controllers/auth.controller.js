import * as authService from '../services/auth.service.js';
import { sendSuccess, sendError } from '../utils/response.js';

export const register = async (req, res, next) => {
  try {
    const result = await authService.registerUser(req.body);
    return sendSuccess(res, result, 'User registered successfully', 201);
  } catch (error) {
    return sendError(res, error.message, 400);
  }
};

export const login = async (req, res, next) => {
  try {
    const result = await authService.loginUser(req.body);
    return sendSuccess(res, result, 'Login successful');
  } catch (error) {
    return sendError(res, error.message, 401);
  }
};

export const getMe = async (req, res, next) => {
  return sendSuccess(res, { user: req.user }, 'Current user profile');
};
