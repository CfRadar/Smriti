import app from './app.js';
import { ENV } from './config/env.js';
import { connectDB } from './config/db.js';

const startServer = async () => {
  // Connect to Database
  await connectDB();

  const server = app.listen(ENV.PORT, () => {
    console.log(`[Smriti Backend] Server running on port ${ENV.PORT} in ${ENV.NODE_ENV} mode`);
  });

  process.on('unhandledRejection', (err) => {
    console.error(`[Unhandled Rejection]: ${err.message}`);
    server.close(() => process.exit(1));
  });
};

startServer();
