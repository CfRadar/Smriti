import mongoose from 'mongoose';
import { Assessment } from '../models/Assessment.js';
import { GameSession } from '../models/GameSession.js';
import { Reminder } from '../models/Reminder.js';
import { Progress } from '../models/Progress.js';
import { sendSuccess, sendError } from '../utils/response.js';

export const getDashboardAnalytics = async (req, res, next) => {
  try {
    const { patientId } = req.params;

    // Run all aggregations in parallel for performance
    const [
      totalSessions,
      totalReminders,
      pendingReminders,
      acknowledgedReminders,
      assessments,
      scoreAverages,
      sevenDayTrend,
      gameTypeBreakdown,
    ] = await Promise.all([

      // --- Existing counts ---
      GameSession.countDocuments({ patientId }),
      Reminder.countDocuments({ patientId }),
      Reminder.countDocuments({ patientId, status: 'pending' }),
      Reminder.countDocuments({ patientId, status: 'acknowledged' }),
      Assessment.find({ patientId }).sort({ createdAt: -1 }).limit(5),

      // --- Average cognitive/memory/speech scores from Progress ---
      Progress.aggregate([
        { $match: { patientId: new mongoose.Types.ObjectId(patientId) } },
        {
          $group: {
            _id: null,
            avgCognitiveScore: { $avg: '$cognitiveScore' },
            avgMemoryRecallScore: { $avg: '$memoryRecallScore' },
            avgSpeechFluencyScore: { $avg: '$speechFluencyScore' },
            totalCompletedTasks: { $sum: '$completedTasksCount' },
            totalMissedTasks: { $sum: '$missedTasksCount' },
          },
        },
      ]),

      // --- 7-day daily score trend for sparkline charts ---
      Progress.aggregate([
        {
          $match: {
            patientId: new mongoose.Types.ObjectId(patientId),
            date: { $gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) },
          },
        },
        {
          $group: {
            _id: { $dateToString: { format: '%Y-%m-%d', date: '$date' } },
            cognitiveScore: { $avg: '$cognitiveScore' },
            memoryRecallScore: { $avg: '$memoryRecallScore' },
            speechFluencyScore: { $avg: '$speechFluencyScore' },
          },
        },
        { $sort: { _id: 1 } },
        {
          $project: {
            _id: 0,
            date: '$_id',
            cognitiveScore: { $round: ['$cognitiveScore', 1] },
            memoryRecallScore: { $round: ['$memoryRecallScore', 1] },
            speechFluencyScore: { $round: ['$speechFluencyScore', 1] },
          },
        },
      ]),

      // --- Per-game-type session count for pie/bar charts ---
      GameSession.aggregate([
        { $match: { patientId: new mongoose.Types.ObjectId(patientId) } },
        {
          $lookup: {
            from: 'games',
            localField: 'gameId',
            foreignField: '_id',
            as: 'game',
          },
        },
        { $unwind: { path: '$game', preserveNullAndEmpty: true } },
        {
          $group: {
            _id: { $ifNull: ['$game.type', 'unknown'] },
            count: { $sum: 1 },
            avgScore: { $avg: '$score' },
          },
        },
        {
          $project: {
            _id: 0,
            gameType: '$_id',
            count: 1,
            avgScore: { $round: ['$avgScore', 1] },
          },
        },
        { $sort: { count: -1 } },
      ]),
    ]);

    // Adherence rate
    const adherenceRate = totalReminders > 0
      ? Math.round((acknowledgedReminders / totalReminders) * 100)
      : 100;

    // Flatten score averages (empty if no Progress records yet)
    const scores = scoreAverages[0] ?? {
      avgCognitiveScore: null,
      avgMemoryRecallScore: null,
      avgSpeechFluencyScore: null,
      totalCompletedTasks: 0,
      totalMissedTasks: 0,
    };

    return sendSuccess(res, {
      // Core counts
      totalSessions,
      totalReminders,
      pendingReminders,
      acknowledgedReminders,
      adherenceRate,

      // Cognitive score averages
      avgCognitiveScore: scores.avgCognitiveScore !== null ? Math.round(scores.avgCognitiveScore) : null,
      avgMemoryRecallScore: scores.avgMemoryRecallScore !== null ? Math.round(scores.avgMemoryRecallScore) : null,
      avgSpeechFluencyScore: scores.avgSpeechFluencyScore !== null ? Math.round(scores.avgSpeechFluencyScore) : null,
      totalCompletedTasks: scores.totalCompletedTasks,
      totalMissedTasks: scores.totalMissedTasks,

      // Trend data for sparklines (last 7 days)
      sevenDayTrend,

      // Per-game breakdown for pie/bar chart
      gameTypeBreakdown,

      // Recent AI assessments
      recentAssessments: assessments,
    }, 'Analytics summary');

  } catch (error) {
    return sendError(res, error.message, 500);
  }
};

