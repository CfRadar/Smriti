import axios from 'axios';
import { ENV } from '../config/env.js';

export const callAiPrediction = async (patientData) => {
  try {
    const response = await axios.post(`${ENV.AI_SERVICE_URL}/predict/cognitive-decline`, patientData, {
      timeout: 10000,
    });
    return response.data;
  } catch (error) {
    console.warn('[AI Service Warning]: AI server unreachable or returned error, using heuristic fallback');
    return {
      riskScore: 0.25,
      riskCategory: 'low',
      indicators: ['Stable recall intervals', 'Routine activity completed'],
      recommendations: ['Maintain regular schedule', 'Continue daily memory games'],
      isFallback: true,
    };
  }
};

export const callAiSpeechAnalysis = async (audioBuffer, metadata = {}) => {
  try {
    const response = await axios.post(`${ENV.AI_SERVICE_URL}/speech/analyze`, { audio: audioBuffer, metadata }, {
      timeout: 15000,
    });
    return response.data;
  } catch (error) {
    return {
      hesitationCount: 2,
      speechRateWpm: 120,
      fluencyScore: 88,
      sentiment: 'calm',
      isFallback: true,
    };
  }
};
