import { Progress } from '../models/Progress.js';
import { sendSuccess, sendError } from '../utils/response.js';

export const getPatientProgress = async (req, res, next) => {
  try {
    const records = await Progress.find({ patientId: req.params.patientId }).sort({ date: 1 });
    return sendSuccess(res, records, 'Patient progress timeline');
  } catch (error) {
    return sendError(res, error.message, 500);
  }
};

export const recordProgress = async (req, res, next) => {
  try {
    const record = await Progress.create(req.body);
    return sendSuccess(res, record, 'Progress recorded', 201);
  } catch (error) {
    return sendError(res, error.message, 400);
  }
};
