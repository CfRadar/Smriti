/**
 * seed.js — Smriti Game Definitions Seeder
 * Run: node src/scripts/seed.js
 *
 * Inserts the 5 cognitive therapy games into the Game collection.
 * Safe to re-run: clears existing Game docs before inserting.
 */

import mongoose from 'mongoose';
import dotenv from 'dotenv';
dotenv.config();

import { Game } from '../models/Game.js';

const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/smriti';

const games = [
  {
    title: 'King Shanaba (Kang Court)',
    description:
      'Traditional Northeast Manipuri target-sliding memory game. Patient slides a disc toward marked zones while recalling position patterns.',
    type: 'pattern_recall',
    difficultyLevels: ['easy', 'medium', 'hard'],
    config: {
      boardType: 'kang_court',
      targetCount: 7,
      timeLimitSeconds: 60,
    },
    isActive: true,
  },
  {
    title: 'Memory Match',
    description:
      'Classic card flip memory game with culturally familiar imagery (festivals, foods, landmarks). Tests short-term visual memory recall.',
    type: 'memory_match',
    difficultyLevels: ['easy', 'medium', 'hard'],
    config: {
      cardTheme: 'northeast_india',
      pairsCount: { easy: 6, medium: 10, hard: 15 },
    },
    isActive: true,
  },
  {
    title: 'Bamboo Dance (Cheraw)',
    description:
      'Rhythm-based step-pattern recall inspired by the traditional Mizo Cheraw dance. Patient follows and repeats displayed step sequences.',
    type: 'pattern_recall',
    difficultyLevels: ['easy', 'medium', 'hard'],
    config: {
      sequenceLength: { easy: 3, medium: 5, hard: 8 },
      beatIntervalMs: 800,
    },
    isActive: true,
  },
  {
    title: 'Blink & Recall',
    description:
      'Rapid visual attention game. A scene is shown briefly, then the patient answers questions about details — tests attentional capture and recall speed.',
    type: 'photo_recognition',
    difficultyLevels: ['easy', 'medium', 'hard'],
    config: {
      exposureDurationMs: { easy: 3000, medium: 1500, hard: 800 },
      questionCount: 3,
    },
    isActive: true,
  },
  {
    title: 'Word Association',
    description:
      'Patient hears or reads a word and must select the most closely related word from options. Tests semantic memory and language processing.',
    type: 'word_association',
    difficultyLevels: ['easy', 'medium', 'hard'],
    config: {
      wordLanguage: 'en',
      optionsCount: 4,
      roundCount: { easy: 5, medium: 8, hard: 12 },
    },
    isActive: true,
  },
];

async function seed() {
  try {
    await mongoose.connect(MONGO_URI);
    console.log('[Seeder] Connected to MongoDB:', MONGO_URI);

    // Clear existing game definitions (idempotent re-run)
    const deleted = await Game.deleteMany({});
    console.log(`[Seeder] Cleared ${deleted.deletedCount} existing game document(s).`);

    // Insert fresh seed data
    const inserted = await Game.insertMany(games);
    console.log(`[Seeder] ✅ Inserted ${inserted.length} game(s):`);
    inserted.forEach((g) => console.log(`  • [${g._id}] ${g.title}`));

  } catch (err) {
    console.error('[Seeder] ❌ Error:', err.message);
    process.exit(1);
  } finally {
    await mongoose.disconnect();
    console.log('[Seeder] Disconnected. Done.');
  }
}

seed();
