import mongoose from 'mongoose';

const familyMemorySchema = new mongoose.Schema(
  {
    patientId: { type: mongoose.Schema.Types.ObjectId, ref: 'Patient', required: true },
    title: { type: String, required: true },
    description: { type: String },
    mediaUrl: { type: String },
    mediaType: { type: String, enum: ['image', 'audio', 'video'], default: 'image' },
    associatedPeople: [
      {
        name: String,
        relation: String,
      },
    ],
    eventDate: { type: Date },
    tags: [String],
    audioPromptUrl: { type: String },
  },
  { timestamps: true }
);

export const FamilyMemory = mongoose.model('FamilyMemory', familyMemorySchema);
