import * as gameService from '../services/game.service.js';
import { sendSuccess, sendError } from '../utils/response.js';

export const listGames = async (req, res, next) => {
  try {
    const games = await gameService.listGames();
    return sendSuccess(res, games, 'Available cognitive games');
  } catch (error) {
    return sendError(res, error.message, 500);
  }
};

export const submitGameSession = async (req, res, next) => {
  try {
    const session = await gameService.recordSession(req.body);
    return sendSuccess(res, session, 'Game session recorded', 201);
  } catch (error) {
    return sendError(res, error.message, 400);
  }
};

export const getGameHistory = async (req, res, next) => {
  try {
    const history = await gameService.getPatientGameHistory(req.params.patientId);
    return sendSuccess(res, history, 'Patient game history');
  } catch (error) {
    return sendError(res, error.message, 500);
  }
};
