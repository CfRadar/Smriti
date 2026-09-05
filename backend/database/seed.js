import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';
import { ENV } from '../src/config/env.js';
import { User } from '../src/models/User.js';
import { Game } from '../src/models/Game.js';

const seedDatabase = async () => {
  try {
    await mongoose.connect(ENV.MONGO_URI);
    console.log('[Seed] Connected to database');

    await User.deleteMany({});
    await Game.deleteMany({});

    const passwordHash = await bcrypt.hash('Password@123', 10);

    const users = await User.create([
      {
        name: 'Caregiver Anita',
        email: 'caregiver@smriti.org',
        password: passwordHash,
        role: 'caregiver',
        phoneNumber: '+919876543210',
      },
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

    console.log(`[Seed] Seeded ${users.length} users`);

    const games = await Game.create([
      {
        title: 'Memory Match',
        description: 'Match pairs of familiar family cards and daily objects.',
        type: 'memory_match',
        difficultyLevels: ['easy', 'medium', 'hard'],
      },
      {
        title: 'Word Association',
        description: 'Connect related words to stimulate language pathways.',
        type: 'word_association',
        difficultyLevels: ['easy', 'medium'],
      },
      {
        title: 'Photo Face Recall',
        description: 'Identify family members and close friends from your memory album.',
        type: 'photo_recognition',
        difficultyLevels: ['easy', 'medium', 'hard'],
      },
    ]);

    console.log(`[Seed] Seeded ${games.length} games`);
    console.log('[Seed] Seeding completed successfully');
    process.exit(0);
  } catch (error) {
    console.error('[Seed Error]:', error);
    process.exit(1);
  }
};

seedDatabase();
