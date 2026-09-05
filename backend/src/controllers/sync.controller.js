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


export const syncPush = async (req, res, next) => {
  try {
    const result = await syncService.syncOfflineData(req.body.patientId, req.body);
    return sendSuccess(res, result, 'Data synchronization complete');
  } catch (error) {
    return sendError(res, error.message, 500);
  }
};

export const syncPull = async (req, res, next) => {
  try {
    const { patientId } = req.params;
    const { since } = req.query; // optional ISO timestamp to fetch only newer updates
    const data = await syncService.getSyncPullData(patientId, since);
    return sendSuccess(res, data, 'Latest updates retrieved for offline cache');
  } catch (error) {
    return sendError(res, error.message, 500);
  }
};
