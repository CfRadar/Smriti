import { Router } from 'express';
import * as voiceController from '../controllers/voice.controller.js';
import { authMiddleware } from '../middleware/auth.middleware.js';

const router = Router();

router.use(authMiddleware);

router.post('/command', voiceController.handleVoiceCommand);
router.get('/prompt', voiceController.getPromptAudio);

export default router;
