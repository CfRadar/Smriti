import * as voiceService from '../services/voice.service.js';
import { sendSuccess, sendError } from '../utils/response.js';

export const handleVoiceCommand = async (req, res, next) => {
  try {
    const result = await voiceService.processVoiceInput(req.body.audio, req.body.language);
    return sendSuccess(res, result, 'Voice command processed');
  } catch (error) {
    return sendError(res, error.message, 500);
  }
};

export const getPromptAudio = async (req, res, next) => {
  try {
    const audio = await voiceService.generateVoicePrompt(req.query.text, req.query.language);
    return sendSuccess(res, audio, 'Prompt synthesized');
  } catch (error) {
    return sendError(res, error.message, 500);
  }
};
