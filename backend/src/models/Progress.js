import mongoose from 'mongoose';

const progressSchema = new mongoose.Schema(
  {
    patientId: { type: mongoose.Schema.Types.ObjectId, ref: 'Patient', required: true },
    date: { type: Date, default: Date.now },
    cognitiveScore: { type: Number, min: 0, max: 100 },
    memoryRecallScore: { type: Number, min: 0, max: 100 },
    speechFluencyScore: { type: Number, min: 0, max: 100 },
    completedTasksCount: { type: Number, default: 0 },
    missedTasksCount: { type: Number, default: 0 },
    notes: { type: String },
  },
  { timestamps: true }
);

export const Progress = mongoose.model('Progress', progressSchema);
