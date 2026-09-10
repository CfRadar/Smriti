/**
 * seed_caregiver.js — Seeds a complete Caregiver test account & sample patient data
 * Run: node src/scripts/seed_caregiver.js
 */

import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';
import dotenv from 'dotenv';
dotenv.config();

import { User } from '../models/User.js';
import { Caregiver } from '../models/Caregiver.js';
import { Patient } from '../models/Patient.js';
import { Reminder } from '../models/Reminder.js';
import { FamilyMemory } from '../models/FamilyMemory.js';
import { Progress } from '../models/Progress.js';
import { Game } from '../models/Game.js';
import { GameSession } from '../models/GameSession.js';

const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/smriti';

async function seedCaregiver() {
  try {
    await mongoose.connect(MONGO_URI);
    console.log('[Seeder] Connected to MongoDB:', MONGO_URI);

    // 1. Create or update Caregiver user
    const caregiverEmail = 'caregiver@smriti.com';
    await User.deleteOne({ email: caregiverEmail });

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash('caregiver123', salt);

    const caregiverUser = await User.create({
      name: 'Ananya Sharma',
      email: caregiverEmail,
      password: passwordHash,
      role: 'caregiver',
      phoneNumber: '+91 9876543210',
    });
    console.log('✅ Created Caregiver User:', caregiverUser.email);

    // 2. Create or update Patient user
    const patientEmail = 'patient@smriti.com';
    await User.deleteOne({ email: patientEmail });

    const patientUser = await User.create({
      name: 'Ramesh Sharma',
      email: patientEmail,
      password: passwordHash,
      role: 'patient',
      phoneNumber: '+91 9876543211',
    });
    console.log('✅ Created Patient User:', patientUser.email);

    // 3. Clear existing Caregiver & Patient profiles for these users
    await Caregiver.deleteMany({ userId: caregiverUser._id });
    await Patient.deleteMany({ userId: patientUser._id });

    // 4. Create Caregiver document first
    const caregiverDoc = await Caregiver.create({
      userId: caregiverUser._id,
      relationToPatient: 'Daughter',
      ngoAffiliation: 'Dementia India Support Network',
      notificationPreferences: { sms: true, email: true, push: true },
      assignedPatients: [],
    });

    // 5. Create Patient document linked to Caregiver
    const patientDoc = await Patient.create({
      userId: patientUser._id,
      caregiverId: caregiverDoc._id,
      dateOfBirth: new Date('1952-04-12'),
      gender: 'male',
      stageOfDementia: 'mild_cognitive_impairment',
      emergencyContact: {
        name: 'Ananya Sharma',
        relation: 'Daughter',
        phone: '+91 9876543210',
      },
      medicalNotes: 'Prescribed Donepezil 5mg once daily at bedtime. Encouraged gentle daily memory games.',
      preferredLanguage: 'en',
    });
    console.log('✅ Created Patient Profile for:', patientDoc._id);

    // 6. Assign patient to caregiver
    caregiverDoc.assignedPatients.push(patientDoc._id);
    await caregiverDoc.save();

    // 7. Seed sample Reminders
    await Reminder.deleteMany({ patientId: patientDoc._id });
    const now = new Date();
    await Reminder.insertMany([
      {
        patientId: patientDoc._id,
        caregiverId: caregiverDoc._id,
        title: 'Morning Blood Pressure Medication',
        description: 'Take 1 tablet of Amlodipine 5mg with a full glass of warm water.',
        type: 'medication',
        scheduledTime: new Date(now.getFullYear(), now.getMonth(), now.getDate(), 9, 0),
        repeat: 'daily',
        isVoicePromptEnabled: true,
        voicePromptText: 'Ramesh ji, please take your morning blood pressure tablet with water.',
        status: 'pending',
      },
      {
        patientId: patientDoc._id,
        caregiverId: caregiverDoc._id,
        title: 'Afternoon Hydration & Light Walk',
        description: 'Drink a glass of coconut water or lemon water and take a 10-minute courtyard walk.',
        type: 'hydration',
        scheduledTime: new Date(now.getFullYear(), now.getMonth(), now.getDate(), 14, 30),
        repeat: 'daily',
        isVoicePromptEnabled: true,
        voicePromptText: 'Time for some refreshing water and a short gentle walk.',
        status: 'acknowledged',
      },
      {
        patientId: patientDoc._id,
        caregiverId: caregiverDoc._id,
        title: 'Evening Memory Photo Journal',
        description: 'Spend 15 minutes reviewing family memories and playing King Shanaba game.',
        type: 'activity',
        scheduledTime: new Date(now.getFullYear(), now.getMonth(), now.getDate(), 19, 0),
        repeat: 'daily',
        isVoicePromptEnabled: true,
        voicePromptText: 'Let us look at some fond family photographs together.',
        status: 'pending',
      },
    ]);
    console.log('✅ Seeded 3 Reminders');

    // 8. Seed sample Family Memories
    await FamilyMemory.deleteMany({ patientId: patientDoc._id });
    await FamilyMemory.insertMany([
      {
        patientId: patientDoc._id,
        title: "Priya's University Graduation",
        description: 'Proud moment celebrating granddaughter Priya graduating with honors in Guwahati.',
        mediaUrl: 'https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=800',
        mediaType: 'image',
        associatedPeople: [
          { name: 'Priya Sharma', relation: 'Granddaughter' },
          { name: 'Ananya Sharma', relation: 'Daughter' },
        ],
        eventDate: new Date('2022-06-15'),
        tags: ['Graduation', 'Guwahati', 'Milestone'],
      },
      {
        patientId: patientDoc._id,
        title: 'Shillong Family Autumn Vacation',
        description: 'Enjoying morning tea overlooking the pine hills of Shillong with all three generations.',
        mediaUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800',
        mediaType: 'image',
        associatedPeople: [
          { name: 'Sunita Sharma', relation: 'Wife' },
          { name: 'Ananya Sharma', relation: 'Daughter' },
        ],
        eventDate: new Date('2019-10-20'),
        tags: ['Vacation', 'Shillong', 'Family'],
      },
      {
        patientId: patientDoc._id,
        title: 'Kang Court Folk Game with Friends',
        description: 'Playing traditional disc sliding game during the autumn community festival in Imphal.',
        mediaUrl: 'https://images.unsplash.com/photo-1511632765486-a01980e01a18?w=800',
        mediaType: 'image',
        associatedPeople: [
          { name: 'Biren Singh', relation: 'Childhood Friend' },
        ],
        eventDate: new Date('2018-11-12'),
        tags: ['Imphal', 'Tradition', 'Festival'],
      },
    ]);
    console.log('✅ Seeded 3 Family Memories');

    // 9. Seed 7-day Progress records for Analytics Chart
    await Progress.deleteMany({ patientId: patientDoc._id });
    const progressRecords = [];
    for (let i = 6; i >= 0; i--) {
      const d = new Date(Date.now() - i * 24 * 60 * 60 * 1000);
      progressRecords.push({
        patientId: patientDoc._id,
        date: d,
        cognitiveScore: 72 + Math.floor(Math.sin(i) * 8 + i * 2),
        memoryRecallScore: 68 + Math.floor(Math.cos(i) * 10 + i * 2),
        speechFluencyScore: 75 + Math.floor(i * 1.5),
        completedTasksCount: 3,
        missedTasksCount: i % 3 === 0 ? 1 : 0,
      });
    }
    await Progress.insertMany(progressRecords);
    console.log('✅ Seeded 7-Day Progress Records');

    // 10. Seed sample Game Sessions
    let games = await Game.find({});
    if (games.length > 0) {
      await GameSession.deleteMany({ patientId: patientDoc._id });
      await GameSession.insertMany([
        {
          patientId: patientDoc._id,
          gameId: games[0]._id,
          score: 85,
          durationSeconds: 120,
          difficulty: 'easy',
          metrics: { reactionTimeMs: 420, accuracyPercentage: 92, errorCount: 1 },
          completedAt: new Date(Date.now() - 3600000),
        },
        {
          patientId: patientDoc._id,
          gameId: games[1 % games.length]._id,
          score: 78,
          durationSeconds: 180,
          difficulty: 'medium',
          metrics: { reactionTimeMs: 510, accuracyPercentage: 84, errorCount: 2 },
          completedAt: new Date(Date.now() - 7200000),
        },
      ]);
      console.log('✅ Seeded Game Sessions');
    }

    console.log('\n=============================================');
    console.log('🎉 SEEDING COMPLETED SUCCESSFULLY!');
    console.log('Use these credentials to test in the Flutter app:');
    console.log('  Email:    caregiver@smriti.com');
    console.log('  Password: caregiver123');
    console.log('=============================================\n');

  } catch (err) {
    console.error('❌ Seeder Error:', err);
  } finally {
    await mongoose.disconnect();
  }
}

seedCaregiver();
