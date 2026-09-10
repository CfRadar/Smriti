import { Router } from 'express';
import * as familyController from '../controllers/family.controller.js';
import { authMiddleware } from '../middleware/auth.middleware.js';
import { roleMiddleware } from '../middleware/role.middleware.js';

const router = Router();

router.use(authMiddleware);

// Patients can view memories; only caregivers/admins can manage them
router.get(['/patient/:patientId', '/:patientId', '/memories/:patientId'], roleMiddleware(['patient', 'caregiver', 'admin']), familyController.getMemories);
router.post('/', roleMiddleware(['caregiver', 'admin']), familyController.addMemory);
router.delete('/:id', roleMiddleware(['caregiver', 'admin']), familyController.deleteMemory);

export default router;
