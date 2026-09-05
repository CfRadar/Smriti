import { Router } from 'express';
import * as syncController from '../controllers/sync.controller.js';
import { authMiddleware } from '../middleware/auth.middleware.js';

const router = Router();

router.use(authMiddleware);

router.post('/', syncController.syncData);

export default router;
