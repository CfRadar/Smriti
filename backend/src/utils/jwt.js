import jwt from 'jsonwebtoken';
import { ENV } from '../config/env.js';

export const generateToken = (payload, expiresIn = ENV.JWT_EXPIRES_IN) => {
  return jwt.sign(payload, ENV.JWT_SECRET, { expiresIn });
};

export const verifyToken = (token) => {
  try {
    return jwt.verify(token, ENV.JWT_SECRET);
  } catch (error) {
    return null;
  }
};
