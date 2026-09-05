import { Reminder } from '../models/Reminder.js';

export const getRemindersByPatient = async (patientId) => {
  return Reminder.find({ patientId }).sort({ scheduledTime: 1 });
};

export const createReminder = async (data) => {
  return Reminder.create(data);
};

export const updateReminderStatus = async (id, status) => {
  const reminder = await Reminder.findByIdAndUpdate(id, { status }, { new: true });
  if (!reminder) throw new Error('Reminder not found');
  return reminder;
};

export const deleteReminder = async (id) => {
  return Reminder.findByIdAndDelete(id);
};
