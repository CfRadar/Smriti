import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';

import authRoutes from './routes/auth.routes.js';
import patientRoutes from './routes/patient.routes.js';
import caregiverRoutes from './routes/caregiver.routes.js';
import gameRoutes from './routes/game.routes.js';
import reminderRoutes from './routes/reminder.routes.js';
import progressRoutes from './routes/progress.routes.js';
import familyRoutes from './routes/family.routes.js';
import analyticsRoutes from './routes/analytics.routes.js';
import voiceRoutes from './routes/voice.routes.js';
import syncRoutes from './routes/sync.routes.js';

import { errorMiddleware } from './middleware/error.middleware.js';

const app = express();

// Security & Logging Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health Check
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', service: 'smriti-backend', uptime: process.uptime() });
});

// Mount Routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/patients', patientRoutes);
app.use('/api/v1/caregivers', caregiverRoutes);
app.use('/api/v1/games', gameRoutes);
app.use('/api/v1/reminders', reminderRoutes);
app.use('/api/v1/progress', progressRoutes);
app.use('/api/v1/family', familyRoutes);
app.use('/api/v1/analytics', analyticsRoutes);
app.use('/api/v1/voice', voiceRoutes);
app.use('/api/v1/sync', syncRoutes);

// Global Error Handler
app.use(errorMiddleware);

export default app;
