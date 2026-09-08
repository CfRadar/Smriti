import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';
import { ENV } from '../src/config/env.js';
import { User } from '../src/models/User.js';
import { Caregiver } from '../src/models/Caregiver.js';
import { Patient } from '../src/models/Patient.js';
import { Game } from '../src/models/Game.js';
import { Reminder } from '../src/models/Reminder.js';
import { FamilyMemory } from '../src/models/FamilyMemory.js';
import { GameSession } from '../src/models/GameSession.js';
import { Progress } from '../src/models/Progress.js';

const seedDatabase = async () => {
  try {
    await mongoose.connect(ENV.MONGO_URI);
    console.log('[Seed] Connected to database:', ENV.MONGO_URI);

    // Clean existing records
    await Promise.all([
      User.deleteMany({}),
      Caregiver.deleteMany({}),
      Patient.deleteMany({}),
      Game.deleteMany({}),
      Reminder.deleteMany({}),
      FamilyMemory.deleteMany({}),
      GameSession.deleteMany({}),
      Progress.deleteMany({}),
    ]);

    const passwordHash = await bcrypt.hash('Password@123', 10);

    // 1. Create Core Users
    const caregiverUser = await User.create({
      name: 'Caregiver Anita Bora',
      email: 'caregiver@smriti.org',
      password: passwordHash,
      role: 'caregiver',
      phoneNumber: '+919876543210',
    });

    const patientUser = await User.create({
      name: 'Shri Biren Bora',
      email: 'patient@smriti.org',
      password: passwordHash,
      role: 'patient',
      phoneNumber: '+919876543219',
    });

    await User.create([
      {
        name: 'Admin Rajesh',
        email: 'admin@smriti.org',
        password: passwordHash,
        role: 'admin',
        phoneNumber: '+919876543211',
      },
      {
        name: 'NGO Coordinator Priya',
        email: 'ngo@smriti.org',
        password: passwordHash,
        role: 'ngo',
        phoneNumber: '+919876543212',
      },
    ]);

    // 2. Create Caregiver Profile
    const caregiverProfile = await Caregiver.create({
      userId: caregiverUser._id,
      relationToPatient: 'Daughter',
      ngoAffiliation: 'Assam Dementia Support Network',
      notificationPreferences: { sms: true, email: true, push: true },
    });

    // 3. Create Patient Profile
    const patientProfile = await Patient.create({
      userId: patientUser._id,
      caregiverId: caregiverProfile._id,
      dateOfBirth: new Date('1952-08-15'),
      gender: 'male',
      stageOfDementia: 'mild_cognitive_impairment',
      preferredLanguage: 'as', // Assamese
      emergencyContact: {
        name: 'Anita Bora',
        relation: 'Daughter',
        phone: '+919876543210',
      },
      medicalNotes: 'Mild memory lapse during evenings. Loves listening to Bihu tunes and photos of grandkids.',
    });

    // Link assigned patient to caregiver
    caregiverProfile.assignedPatients = [patientProfile._id];
    await caregiverProfile.save();

    console.log('[Seed] Seeded Users, Caregiver, and Patient profiles');

    // 4. Seed Cognitive Games
    const games = await Game.create([
      {
        title: 'Blink Reaction Game',
        description: 'Focus and press the target number when highlighted to assess visual alertness.',
        type: 'memory_match',
        difficultyLevels: ['easy', 'medium', 'hard'],
      },
      {
        title: 'Pattern Memory Game',
        description: 'Follow and reproduce sequential memory patterns of regional symbols.',
        type: 'word_association',
        difficultyLevels: ['easy', 'medium'],
      },
      {
        title: 'Family Face Recall',
        description: 'Recognize family members and cherished places from your personal memory wall.',
        type: 'photo_recognition',
        difficultyLevels: ['easy', 'medium', 'hard'],
      },
    ]);

    // 5. Seed Daily Reminders
    const morningTime = new Date();
    morningTime.setHours(8, 30, 0, 0);

    const lunchTime = new Date();
    lunchTime.setHours(13, 0, 0, 0);

    const eveningWalkTime = new Date();
    eveningWalkTime.setHours(17, 30, 0, 0);

    await Reminder.create([
      {
        patientId: patientProfile._id,
        caregiverId: caregiverProfile._id,
        title: 'Morning Donepezil & Warm Water',
        description: '1 tablet (5mg) after breakfast with warm water.',
        type: 'medication',
        scheduledTime: morningTime,
        repeat: 'daily',
        isVoicePromptEnabled: true,
        voicePromptText: 'Deuta, please take your morning medicine with warm water.',
        status: 'acknowledged',
      },
      {
        patientId: patientProfile._id,
        caregiverId: caregiverProfile._id,
        title: 'Afternoon Hydration',
        description: 'Drink a full glass of water or lemon tea.',
        type: 'hydration',
        scheduledTime: lunchTime,
        repeat: 'daily',
        isVoicePromptEnabled: true,
        voicePromptText: 'Deuta, it is time for a glass of water.',
        status: 'pending',
      },
      {
        patientId: patientProfile._id,
        caregiverId: caregiverProfile._id,
        title: 'Garden Stroll & Fresh Air',
        description: 'Light 15-minute garden walk in courtyard.',
        type: 'activity',
        scheduledTime: eveningWalkTime,
        repeat: 'daily',
        isVoicePromptEnabled: false,
        status: 'pending',
      },
    ]);

    // 6. Seed Family Memories
    await FamilyMemory.create([
      {
        patientId: patientProfile._id,
        title: 'Diwali Celebration with Grandchildren',
        description: 'Lighting diyas with Aarav and Priya on the veranda in Guwahati.',
        mediaUrl: 'https://images.unsplash.com/photo-1609137144822-42173f274a27?auto=format&fit=crop&w=600&q=80',
        mediaType: 'image',
        associatedPeople: [
          { name: 'Aarav', relation: 'Grandson' },
          { name: 'Priya', relation: 'Granddaughter' },
        ],
        eventDate: new Date('2024-11-01'),
        tags: ['festival', 'family', 'guwahati'],
      },
      {
        patientId: patientProfile._id,
        title: 'Morning in Jorhat Tea Estate',
        description: 'Walking through the tea garden rows with brother Ratan.',
        mediaUrl: 'https://images.unsplash.com/photo-1544717305-2782549b5136?auto=format&fit=crop&w=600&q=80',
        mediaType: 'image',
        associatedPeople: [{ name: 'Ratan Bora', relation: 'Brother' }],
        eventDate: new Date('2023-04-14'),
        tags: ['jorhat', 'nature', 'tea-garden'],
      },
    ]);

    // 7. Seed Game Sessions
    await GameSession.create([
      {
        patientId: patientProfile._id,
        gameId: games[0]._id,
        score: 85,
        durationSeconds: 120,
        difficulty: 'medium',
        metrics: {
          reactionTimeMs: 760,
          accuracyPercentage: 88,
        },
      },
      {
        patientId: patientProfile._id,
        gameId: games[1]._id,
        score: 92,
        durationSeconds: 150,
        difficulty: 'easy',
        metrics: {
          reactionTimeMs: 810,
          accuracyPercentage: 94,
        },
      },
    ]);

    // 8. Seed Progress Record
    await Progress.create({
      patientId: patientProfile._id,
      cognitiveScore: 82,
      memoryRecallScore: 86,
      speechFluencyScore: 78,
      date: new Date(),
      notes: 'Strong attention during Blink trials. Readily recognized grandson Aarav.',
    });

    console.log('[Seed] Database seeding completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('[Seed Error]:', error);
    process.exit(1);
  }
};

seedDatabase();
