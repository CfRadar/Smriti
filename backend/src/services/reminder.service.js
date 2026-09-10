import { Reminder } from '../models/Reminder.js';
import { Patient } from '../models/Patient.js';
import { User } from '../models/User.js';
import { sendPushNotification } from './notification.service.js';

export const getRemindersByPatient = async (patientId) => {
  return Reminder.find({ patientId }).sort({ scheduledTime: 1 });
};

export const createReminder = async (data) => {
  const reminder = await Reminder.create(data);

  // Fire-and-forget: push notification to the patient's device
  setImmediate(async () => {
    try {
      // Walk the chain: reminder → Patient → User → fcmToken
      const patient = await Patient.findById(reminder.patientId).select('userId');
      if (!patient) return;

      const user = await User.findById(patient.userId).select('fcmToken name');
      if (!user?.fcmToken) return; // Device not registered for push yet

      await sendPushNotification({
        targetToken: user.fcmToken,
        title: `⏰ ${reminder.title}`,
        body: reminder.voicePromptText || reminder.description || reminder.title,
        data: {
          reminderId: reminder._id.toString(),
          type: reminder.type,
          scheduledTime: reminder.scheduledTime?.toISOString() ?? '',
        },
      });
    } catch (err) {
      console.warn('[reminder.service] Push notification failed (non-fatal):', err.message);
    }
  });

  return reminder;
};

export const updateReminderStatus = async (id, status) => {
  const reminder = await Reminder.findByIdAndUpdate(id, { status }, { new: true });
  if (!reminder) throw new Error('Reminder not found');
  return reminder;
};

export const deleteReminder = async (id) => {
  return Reminder.findByIdAndDelete(id);
};

