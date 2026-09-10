import { Router } from 'express';
import * as gameController from '../controllers/game.controller.js';
import { authMiddleware } from '../middleware/auth.middleware.js';
import { roleMiddleware } from '../middleware/role.middleware.js';

const router = Router();

router.use(authMiddleware);

// All authenticated roles can view games; only patients submit sessions
router.get('/', roleMiddleware(['patient', 'caregiver', 'admin']), gameController.listGames);
router.post(['/session', '/sessions'], roleMiddleware(['patient']), gameController.submitGameSession);
router.get('/history/:patientId', roleMiddleware(['caregiver', 'admin']), gameController.getGameHistory);

export default router;
