import { Router } from 'express';
import * as familyController from '../controllers/family.controller.js';
import { authMiddleware } from '../middleware/auth.middleware.js';

const router = Router();

router.use(authMiddleware);

router.get('/patient/:patientId', familyController.getMemories);
router.post('/', familyController.addMemory);
router.delete('/:id', familyController.deleteMemory);

export default router;
