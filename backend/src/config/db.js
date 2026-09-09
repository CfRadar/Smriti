import mongoose from 'mongoose';
import { ENV } from './env.js';

export const connectDB = async () => {
  try {
    const conn = await mongoose.connect(ENV.MONGO_URI);
    console.log(`[MongoDB Connected]: ${conn.connection.host}`);
    try {
      await conn.connection.collection('users').dropIndex('username_1');
    } catch {
      // index does not exist or already dropped
    }
  } catch (error) {
    console.error(`[MongoDB Connection Error]: ${error.message}`);
    // Non-fatal in dev mode to allow running without local mongo
    if (ENV.NODE_ENV === 'production') {
      process.exit(1);
    }
  }
};
