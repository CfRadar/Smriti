import { sendError } from '../utils/response.js';

export const roleMiddleware = (allowedRoles = []) => {
  return (req, res, next) => {
    if (!req.user || !req.user.role) {
      return sendError(res, 'Access denied. No role found for user.', 403);
    }

    if (!allowedRoles.includes(req.user.role)) {
      return sendError(res, `Access forbidden. Required roles: ${allowedRoles.join(', ')}`, 403);
    }

    next();
  };
};
