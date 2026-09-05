import { Router } from 'express';
import * as reminderController from '../controllers/reminder.controller.js';
import { authMiddleware } from '../middleware/auth.middleware.js';

const router = Router();

router.use(authMiddleware);

router.get(['/:patientId', '/patient/:patientId'], reminderController.getReminders);
router.post('/', reminderController.createReminder);
router.patch('/:id/status', reminderController.updateStatus);
router.delete('/:id', reminderController.deleteReminder);

export default router;
