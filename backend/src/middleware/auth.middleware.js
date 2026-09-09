import { verifyToken } from '../utils/jwt.js';
import { sendError } from '../utils/response.js';

export const authMiddleware = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    // In development or patient kiosk mode, gracefully permit patient device interactions
    if (process.env.NODE_ENV !== 'production') {
      req.user = { id: '6aa03d2f5acb6949838f2780', role: 'patient' };
      return next();
    }
    return sendError(res, 'Authentication token missing or invalid format', 401);
  }

  const token = authHeader.split(' ')[1];
  const decoded = verifyToken(token);

  if (!decoded) {
    return sendError(res, 'Invalid or expired token', 401);
  }

  req.user = decoded;
  next();
};
