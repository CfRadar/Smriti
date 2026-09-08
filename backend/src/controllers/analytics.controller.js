import { Assessment } from '../models/Assessment.js';
import { GameSession } from '../models/GameSession.js';
import { Reminder } from '../models/Reminder.js';
import { sendSuccess, sendError } from '../utils/response.js';

export const getDashboardAnalytics = async (req, res, next) => {
  try {
    const { patientId } = req.params;
    const totalSessions = await GameSession.countDocuments({ patientId });
    const totalReminders = await Reminder.countDocuments({ patientId });
    const pendingReminders = await Reminder.countDocuments({ patientId, status: 'pending' });
    const acknowledgedReminders = await Reminder.countDocuments({ patientId, status: 'acknowledged' });
    const assessments = await Assessment.find({ patientId }).sort({ createdAt: -1 }).limit(5);

    const adherenceRate = totalReminders > 0 
      ? Math.round((acknowledgedReminders / totalReminders) * 100) 
      : 100;

    return sendSuccess(res, {
      totalSessions,
      totalReminders,
      pendingReminders,
      acknowledgedReminders,
      recentAssessments: assessments,
      adherenceRate,
    }, 'Analytics summary');
  } catch (error) {
    return sendError(res, error.message, 500);
  }
};
