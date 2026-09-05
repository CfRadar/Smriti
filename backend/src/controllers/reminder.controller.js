import * as reminderService from '../services/reminder.service.js';
import { sendSuccess, sendError } from '../utils/response.js';

export const getReminders = async (req, res, next) => {
  try {
    const reminders = await reminderService.getRemindersByPatient(req.params.patientId);
    return sendSuccess(res, reminders, 'Reminders list');
  } catch (error) {
    return sendError(res, error.message, 500);
  }
};

export const createReminder = async (req, res, next) => {
  try {
    const reminder = await reminderService.createReminder(req.body);
    return sendSuccess(res, reminder, 'Reminder created', 201);
  } catch (error) {
    return sendError(res, error.message, 400);
  }
};

export const updateStatus = async (req, res, next) => {
  try {
    const reminder = await reminderService.updateReminderStatus(req.params.id, req.body.status);
    return sendSuccess(res, reminder, 'Reminder status updated');
  } catch (error) {
    return sendError(res, error.message, 400);
  }
};

export const deleteReminder = async (req, res, next) => {
  try {
    await reminderService.deleteReminder(req.params.id);
    return sendSuccess(res, null, 'Reminder deleted');
  } catch (error) {
    return sendError(res, error.message, 500);
  }
};
