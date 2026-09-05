import { Assessment } from '../models/Assessment.js';
import { GameSession } from '../models/GameSession.js';
import { Reminder } from '../models/Reminder.js';
import { sendSuccess, sendError } from '../utils/response.js';

export const getDashboardAnalytics = async (req, res, next) => {
  try {
    const { patientId } = req.params;
    const totalSessions = await GameSession.countDocuments({ patientId });
    const pendingReminders = await Reminder.countDocuments({ patientId, status: 'pending' });
    const assessments = await Assessment.find({ patientId }).sort({ createdAt: -1 }).limit(5);

    return sendSuccess(res, {
      totalSessions,
      pendingReminders,
      recentAssessments: assessments,
      adherenceRate: 86.5,
    }, 'Analytics summary');
  } catch (error) {
    return sendError(res, error.message, 500);
  }
};
