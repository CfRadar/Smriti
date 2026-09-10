import { Router } from 'express';
import * as caregiverController from '../controllers/caregiver.controller.js';
import { authMiddleware } from '../middleware/auth.middleware.js';
import { roleMiddleware } from '../middleware/role.middleware.js';

const router = Router();

router.use(authMiddleware);
router.use(roleMiddleware(['caregiver', 'admin']));

router.get('/profile', caregiverController.getCaregiverProfile);
router.put('/profile', caregiverController.updateCaregiver);

export default router;
