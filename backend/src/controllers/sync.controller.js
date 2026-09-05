import * as syncService from '../services/sync.service.js';
import { sendSuccess, sendError } from '../utils/response.js';

export const syncData = async (req, res, next) => {
  try {
    const result = await syncService.syncOfflineData(req.body.patientId, req.body);
    return sendSuccess(res, result, 'Data synchronization complete');
  } catch (error) {
    return sendError(res, error.message, 500);
  }
};
