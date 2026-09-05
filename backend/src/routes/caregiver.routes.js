import { Router } from 'express';
import * as caregiverController from '../controllers/caregiver.controller.js';
import { authMiddleware } from '../middleware/auth.middleware.js';

const router = Router();

router.use(authMiddleware);

router.get('/profile', caregiverController.getCaregiverProfile);
router.put('/profile', caregiverController.updateCaregiver);

export default router;
