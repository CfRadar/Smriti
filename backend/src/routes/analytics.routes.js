import { Router } from 'express';
import * as analyticsController from '../controllers/analytics.controller.js';
import { authMiddleware } from '../middleware/auth.middleware.js';
import { roleMiddleware } from '../middleware/role.middleware.js';

const router = Router();

router.use(authMiddleware);
router.use(roleMiddleware(['caregiver', 'admin']));

router.get('/dashboard/:patientId', analyticsController.getDashboardAnalytics);

export default router;
