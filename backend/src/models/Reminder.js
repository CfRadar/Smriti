import mongoose from 'mongoose';

const reminderSchema = new mongoose.Schema(
  {
    patientId: { type: mongoose.Schema.Types.ObjectId, ref: 'Patient', required: true },
    caregiverId: { type: mongoose.Schema.Types.ObjectId, ref: 'Caregiver' },
    title: { type: String, required: true },
    description: { type: String },
    type: {
      type: String,
      enum: ['medication', 'meal', 'hydration', 'activity', 'appointment', 'custom'],
      default: 'custom',
    },
    scheduledTime: { type: Date, required: true },
    repeat: {
      type: String,
      enum: ['none', 'daily', 'weekly', 'custom'],
      default: 'none',
    },
    isVoicePromptEnabled: { type: Boolean, default: true },
    voicePromptText: { type: String },
    status: {
      type: String,
      enum: ['pending', 'acknowledged', 'missed', 'snoozed'],
      default: 'pending',
    },
  },
  { timestamps: true }
);

export const Reminder = mongoose.model('Reminder', reminderSchema);
