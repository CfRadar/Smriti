import mongoose from 'mongoose';

const assessmentSchema = new mongoose.Schema(
  {
    patientId: { type: mongoose.Schema.Types.ObjectId, ref: 'Patient', required: true },
    evaluatorId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    assessmentType: {
      type: String,
      enum: ['MMSE', 'MoCA', 'AI_SPEECH_ANALYSIS', 'DAILY_COGNITIVE_CHECK'],
      default: 'DAILY_COGNITIVE_CHECK',
    },
    rawScores: { type: mongoose.Schema.Types.Mixed },
    overallScore: { type: Number },
    riskLevel: {
      type: String,
      enum: ['low', 'moderate', 'high', 'severe'],
      default: 'low',
    },
    clinicalObservations: { type: String },
  },
  { timestamps: true }
);

export const Assessment = mongoose.model('Assessment', assessmentSchema);
