import { Router } from 'express';
import * as analyticsController from '../controllers/analytics.controller.js';
import { authMiddleware } from '../middleware/auth.middleware.js';

const router = Router();

router.use(authMiddleware);

router.get('/dashboard/:patientId', analyticsController.getDashboardAnalytics);

export default router;
