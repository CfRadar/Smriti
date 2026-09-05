import { Reminder } from '../models/Reminder.js';
import { GameSession } from '../models/GameSession.js';

export const syncOfflineData = async (patientId, offlinePayload) => {
  const { completedReminders = [], gameSessions = [], timestamp } = offlinePayload;
  const results = { syncedReminders: 0, syncedGames: 0 };

  for (const reminderUpdate of completedReminders) {
    await Reminder.findByIdAndUpdate(reminderUpdate.id, {
      status: reminderUpdate.status,
      acknowledgedAt: reminderUpdate.acknowledgedAt || new Date(),
    });
    results.syncedReminders++;
  }

  for (const session of gameSessions) {
    await GameSession.create({
      ...session,
      patientId,
    });
    results.syncedGames++;
  }

  return {
    success: true,
    serverTimestamp: new Date().toISOString(),
    results,
  };
};
