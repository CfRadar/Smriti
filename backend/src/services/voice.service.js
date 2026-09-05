export const processVoiceInput = async (audioData, language = 'en') => {
  return {
    transcription: 'Take medicine for blood pressure at 2 PM',
    intent: 'create_reminder',
    extractedEntities: {
      action: 'take_medicine',
      item: 'blood pressure medication',
      time: '14:00',
    },
    confidence: 0.94,
  };
};

export const generateVoicePrompt = async (text, language = 'en') => {
  return {
    audioUrl: `/static/prompts/prompt_${Date.now()}.mp3`,
    durationSeconds: 3.5,
    text,
  };
};
