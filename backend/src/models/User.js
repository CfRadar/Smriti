import mongoose from 'mongoose';

const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true, lowercase: true },
    password: { type: String, required: true },
    role: {
      type: String,
      enum: ['patient', 'caregiver', 'admin', 'ngo'],
      default: 'caregiver',
    },
    phoneNumber: { type: String },
    profileImage: { type: String },
    isActive: { type: Boolean, default: true },
    fcmToken: { type: String, default: null }, // Firebase Cloud Messaging device token for push notifications
  },
  { timestamps: true }
);

export const User = mongoose.model('User', userSchema);
