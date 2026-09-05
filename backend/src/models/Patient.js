import mongoose from 'mongoose';

const patientSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    caregiverId: { type: mongoose.Schema.Types.ObjectId, ref: 'Caregiver' },
    dateOfBirth: { type: Date },
    gender: { type: String, enum: ['male', 'female', 'other'] },
    stageOfDementia: {
      type: String,
      enum: ['mild_cognitive_impairment', 'early_stage', 'middle_stage', 'late_stage'],
      default: 'mild_cognitive_impairment',
    },
    emergencyContact: {
      name: String,
      relation: String,
      phone: String,
    },
    medicalNotes: { type: String },
    preferredLanguage: { type: String, default: 'en' },
  },
  { timestamps: true }
);

export const Patient = mongoose.model('Patient', patientSchema);
