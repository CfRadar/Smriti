import { sendError } from '../utils/response.js';
import { ENV } from '../config/env.js';

export const errorMiddleware = (err, req, res, next) => {
  console.error(`[Error Handler]: ${err.stack || err.message}`);

  const statusCode = err.statusCode || 500;
  const message = err.message || 'Internal Server Error';

  return sendError(
    res,
    message,
    statusCode,
    ENV.NODE_ENV === 'development' ? { stack: err.stack } : null
  );
};
