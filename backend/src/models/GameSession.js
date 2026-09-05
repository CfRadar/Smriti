import mongoose from 'mongoose';

const gameSessionSchema = new mongoose.Schema(
  {
    patientId: { type: mongoose.Schema.Types.ObjectId, ref: 'Patient', required: true },
    gameId: { type: mongoose.Schema.Types.ObjectId, ref: 'Game', required: true },
    score: { type: Number, required: true },
    durationSeconds: { type: Number, required: true },
    difficulty: { type: String, enum: ['easy', 'medium', 'hard'], default: 'easy' },
    metrics: {
      reactionTimeMs: Number,
      accuracyPercentage: Number,
      errorCount: Number,
    },
    completedAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

export const GameSession = mongoose.model('GameSession', gameSessionSchema);
