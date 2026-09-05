import { Router } from 'express';
import * as syncController from '../controllers/sync.controller.js';
import { authMiddleware } from '../middleware/auth.middleware.js';

const router = Router();

router.use(authMiddleware);

router.post('/', syncController.syncPush);
router.get('/pull/:patientId', syncController.syncPull);

export default router;
