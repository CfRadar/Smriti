import axios from 'axios';
import { ENV } from '../config/env.js';

/**
 * Sends audio/transcript to the FastAPI /speech/analyze endpoint.
 * Maps snake_case AI response → camelCase intent envelope.
 * Falls back gracefully if the AI service is unreachable.
 */
export const processVoiceInput = async (audioData, language = 'en') => {
  try {
    const response = await axios.post(
      `${ENV.AI_SERVICE_URL}/speech/analyze`,
      {
        audio: audioData ?? null,
        // Use audioData as transcript if it's plain text (e.g., from STT pre-processing)
        transcript: typeof audioData === 'string' && !audioData.startsWith('data:')
          ? audioData
          : 'Voice input received.',
        metadata: { language },
      },
      { timeout: 12000 }
    );

    const ai = response.data;

    // Derive a simple intent from the fluency score
    const intent = ai.fluency_score < 60 ? 'flag_cognitive_concern' : 'voice_acknowledged';
    const confidence = parseFloat((ai.acoustic_clarity ?? 0.8).toFixed(2));

    return {
      transcription: typeof audioData === 'string' ? audioData : '[audio received]',
      intent,
      extractedEntities: {
        fluencyScore: ai.fluency_score,
        hesitationCount: ai.hesitation_count,
        speechRateWpm: ai.speech_rate_wpm,
        sentiment: ai.sentiment,
        acousticClarity: ai.acoustic_clarity,
      },
      confidence,
      language,
    };
  } catch (error) {
    console.warn('[voice.service] FastAPI unreachable, using fallback:', error.message);
    // Safe fallback — never crash the patient app
    return {
      transcription: typeof audioData === 'string' ? audioData : '[audio received]',
      intent: 'voice_acknowledged',
      extractedEntities: {
        fluencyScore: 88,
        hesitationCount: 1,
        speechRateWpm: 120,
        sentiment: 'calm',
        acousticClarity: 0.85,
      },
      confidence: 0.7,
      language,
      isFallback: true,
    };
  }
};

/**
 * Generates a voice prompt for patient reminders.
 * TODO: Integrate Google Cloud TTS / gTTS for actual audio generation.
 * Currently returns a URL stub — the text is always present for display fallback.
 */
export const generateVoicePrompt = async (text, language = 'en') => {
  if (!text) {
    return { audioUrl: null, durationSeconds: 0, text: '' };
  }

  // Estimate duration: average 130 WPM → words / 130 * 60 seconds
  const wordCount = text.trim().split(/\s+/).length;
  const estimatedDuration = parseFloat(((wordCount / 130) * 60).toFixed(1));

  return {
    audioUrl: `/static/prompts/prompt_${Date.now()}_${language}.mp3`,
    durationSeconds: estimatedDuration,
    text,
    language,
    // Flag so client knows this is a stub URL until TTS is integrated
    isGeneratedStub: true,
  };
};
