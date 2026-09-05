import mongoose from 'mongoose';

const caregiverSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    assignedPatients: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Patient' }],
    relationToPatient: { type: String },
    ngoAffiliation: { type: String },
    notificationPreferences: {
      sms: { type: Boolean, default: true },
      email: { type: Boolean, default: true },
      push: { type: Boolean, default: true },
    },
  },
  { timestamps: true }
);

export const Caregiver = mongoose.model('Caregiver', caregiverSchema);
