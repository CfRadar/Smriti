import { Router } from 'express';
import * as reminderController from '../controllers/reminder.controller.js';
import { authMiddleware } from '../middleware/auth.middleware.js';
import { roleMiddleware } from '../middleware/role.middleware.js';

const router = Router();

router.use(authMiddleware);

// Patients can read their own reminders; only caregivers/admins can write
router.get(['/:patientId', '/patient/:patientId'], roleMiddleware(['patient', 'caregiver', 'admin']), reminderController.getReminders);
router.post('/', roleMiddleware(['caregiver', 'admin']), reminderController.createReminder);
router.patch('/:id/status', roleMiddleware(['caregiver', 'patient', 'admin']), reminderController.updateStatus);
router.delete('/:id', roleMiddleware(['caregiver', 'admin']), reminderController.deleteReminder);

export default router;
