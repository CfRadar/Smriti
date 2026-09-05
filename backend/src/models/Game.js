import mongoose from 'mongoose';

const gameSchema = new mongoose.Schema(
  {
    title: { type: String, required: true },
    description: { type: String },
    type: {
      type: String,
      enum: ['memory_match', 'word_association', 'pattern_recall', 'photo_recognition'],
      required: true,
    },
    difficultyLevels: [{ type: String, enum: ['easy', 'medium', 'hard'] }],
    config: { type: mongoose.Schema.Types.Mixed, default: {} },
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true }
);

export const Game = mongoose.model('Game', gameSchema);
