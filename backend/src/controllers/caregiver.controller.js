import { Caregiver } from '../models/Caregiver.js';
import { sendSuccess, sendError } from '../utils/response.js';

export const getCaregiverProfile = async (req, res, next) => {
  try {
    const caregiver = await Caregiver.findOne({ userId: req.user.id }).populate('assignedPatients');
    return sendSuccess(res, caregiver, 'Caregiver profile');
  } catch (error) {
    return sendError(res, error.message, 500);
  }
};

export const updateCaregiver = async (req, res, next) => {
  try {
    const updated = await Caregiver.findOneAndUpdate({ userId: req.user.id }, req.body, { new: true });
    return sendSuccess(res, updated, 'Caregiver updated');
  } catch (error) {
    return sendError(res, error.message, 400);
  }
};
