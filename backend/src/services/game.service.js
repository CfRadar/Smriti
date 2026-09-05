import { Game } from '../models/Game.js';
import { GameSession } from '../models/GameSession.js';

export const listGames = async () => {
  return Game.find({ isActive: true });
};

export const recordSession = async (sessionData) => {
  return GameSession.create(sessionData);
};

export const getPatientGameHistory = async (patientId) => {
  return GameSession.find({ patientId }).populate('gameId').sort({ completedAt: -1 });
};
