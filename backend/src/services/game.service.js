import { Game } from '../models/Game.js';
import { GameSession } from '../models/GameSession.js';
import { Assessment } from '../models/Assessment.js';
import { callAiPrediction } from './ai.service.js';

export const listGames = async () => {
  return Game.find({ isActive: true });
};

export const recordSession = async (sessionData) => {
  // 1. Always save the game session first
  const session = await GameSession.create(sessionData);

  // 2. Fire-and-forget: call AI prediction and persist as Assessment
  //    Any failure here must NOT affect the session save response
  setImmediate(async () => {
    try {
      const aiInput = {
        patientId: session.patientId,
        score: session.score,
        durationSeconds: session.durationSeconds,
        difficulty: session.difficulty,
        metrics: session.metrics,
      };

      const prediction = await callAiPrediction(aiInput);

      // Map AI riskScore (0-1 float) → Assessment riskLevel enum
      const riskScore = prediction.riskScore ?? 0;
      let riskLevel = 'low';
      if (riskScore >= 0.75) riskLevel = 'severe';
      else if (riskScore >= 0.5) riskLevel = 'high';
      else if (riskScore >= 0.25) riskLevel = 'moderate';

      await Assessment.create({
        patientId: session.patientId,
        assessmentType: 'DAILY_COGNITIVE_CHECK',
        rawScores: prediction,
        overallScore: Math.round((1 - riskScore) * 100), // invert: high risk → low score
        riskLevel,
        clinicalObservations: prediction.recommendations?.join('; ') ?? '',
      });
    } catch (err) {
      console.warn('[game.service] AI assessment persistence failed (non-fatal):', err.message);
    }
  });

  return session;
};

export const getPatientGameHistory = async (patientId) => {
  return GameSession.find({ patientId }).populate('gameId').sort({ completedAt: -1 });
};
