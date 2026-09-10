import { Caregiver } from '../models/Caregiver.js';
import { sendSuccess, sendError } from '../utils/response.js';

export const getCaregiverProfile = async (req, res, next) => {
  try {
    const caregiver = await Caregiver.findOne({ userId: req.user.id }).populate('assignedPatients');
    if (!caregiver) return sendError(res, 'Caregiver profile not found for this user', 404);
    return sendSuccess(res, caregiver, 'Caregiver profile');
  } catch (error) {
    return sendError(res, error.message, 500);
  }
};

export const updateCaregiver = async (req, res, next) => {
  try {
    // Whitelist only safe fields — prevents overwriting userId or assignedPatients directly
    const { relationToPatient, ngoAffiliation, notificationPreferences } = req.body;
    const updates = {};
    if (relationToPatient !== undefined) updates.relationToPatient = relationToPatient;
    if (ngoAffiliation !== undefined) updates.ngoAffiliation = ngoAffiliation;
    if (notificationPreferences !== undefined) updates.notificationPreferences = notificationPreferences;

    const updated = await Caregiver.findOneAndUpdate(
      { userId: req.user.id },
      { $set: updates },
      { new: true, runValidators: true }
    );
    if (!updated) return sendError(res, 'Caregiver profile not found', 404);
    return sendSuccess(res, updated, 'Caregiver updated');
  } catch (error) {
    return sendError(res, error.message, 400);
  }
};
