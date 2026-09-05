import { Router } from 'express';
import * as progressController from '../controllers/progress.controller.js';
import { authMiddleware } from '../middleware/auth.middleware.js';

const router = Router();

router.use(authMiddleware);

router.get('/patient/:patientId', progressController.getPatientProgress);
router.post('/', progressController.recordProgress);

export default router;
