import * as authService from '../services/auth.service.js';
import { User } from '../models/User.js';
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

/**
 * PATCH /api/auth/device-token
 * Called by Flutter app after login to register/update the FCM push token.
 * Body: { fcmToken: string }
 */
export const registerDeviceToken = async (req, res, next) => {
  try {
    const { fcmToken } = req.body;
    if (!fcmToken) return sendError(res, 'fcmToken is required', 400);
    await User.findByIdAndUpdate(req.user.id, { fcmToken });
    return sendSuccess(res, null, 'Device token registered');
  } catch (error) {
    return sendError(res, error.message, 500);
  }
};
