import { Router } from 'express';
import * as gameController from '../controllers/game.controller.js';
import { authMiddleware } from '../middleware/auth.middleware.js';

const router = Router();

router.use(authMiddleware);

router.get('/', gameController.listGames);
router.post(['/session', '/sessions'], gameController.submitGameSession);
router.get('/history/:patientId', gameController.getGameHistory);

export default router;
