// lib/models/caregiver_models.dart
// Data models for the caregiver dashboard

class CaregiverAuth {
  final String token;
  final String userId;
  final String name;
  final String email;
  final String role;

  const CaregiverAuth({
    required this.token,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
  });

  factory CaregiverAuth.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};
    return CaregiverAuth(
      token: json['token']?.toString() ?? '',
      userId: user['id']?.toString() ?? '',
      name: user['name']?.toString() ?? '',
      email: user['email']?.toString() ?? '',
      role: user['role']?.toString() ?? 'caregiver',
    );
  }
}

class AnalyticsSummary {
  final int totalSessions;
  final int totalReminders;
  final int pendingReminders;
  final int acknowledgedReminders;
  final int adherenceRate;
  final int? avgCognitiveScore;
  final int? avgMemoryRecallScore;
  final int? avgSpeechFluencyScore;
  final List<TrendPoint> sevenDayTrend;
  final List<GameTypeBreakdown> gameTypeBreakdown;

  const AnalyticsSummary({
    required this.totalSessions,
    required this.totalReminders,
    required this.pendingReminders,
    required this.acknowledgedReminders,
    required this.adherenceRate,
    this.avgCognitiveScore,
    this.avgMemoryRecallScore,
    this.avgSpeechFluencyScore,
    required this.sevenDayTrend,
    required this.gameTypeBreakdown,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    final trend = (json['sevenDayTrend'] as List? ?? [])
        .map((e) => TrendPoint.fromJson(e as Map<String, dynamic>))
        .toList();
    final breakdown = (json['gameTypeBreakdown'] as List? ?? [])
        .map((e) => GameTypeBreakdown.fromJson(e as Map<String, dynamic>))
        .toList();

    return AnalyticsSummary(
      totalSessions: (json['totalSessions'] as num?)?.toInt() ?? 0,
      totalReminders: (json['totalReminders'] as num?)?.toInt() ?? 0,
      pendingReminders: (json['pendingReminders'] as num?)?.toInt() ?? 0,
      acknowledgedReminders: (json['acknowledgedReminders'] as num?)?.toInt() ?? 0,
      adherenceRate: (json['adherenceRate'] as num?)?.toInt() ?? 0,
      avgCognitiveScore: (json['avgCognitiveScore'] as num?)?.toInt(),
      avgMemoryRecallScore: (json['avgMemoryRecallScore'] as num?)?.toInt(),
      avgSpeechFluencyScore: (json['avgSpeechFluencyScore'] as num?)?.toInt(),
      sevenDayTrend: trend,
      gameTypeBreakdown: breakdown,
    );
  }
}

class TrendPoint {
  final String date;
  final double cognitiveScore;
  final double memoryRecallScore;
  final double speechFluencyScore;

  const TrendPoint({
    required this.date,
    required this.cognitiveScore,
    required this.memoryRecallScore,
    required this.speechFluencyScore,
  });

  factory TrendPoint.fromJson(Map<String, dynamic> json) => TrendPoint(
        date: json['date']?.toString() ?? '',
        cognitiveScore: (json['cognitiveScore'] as num?)?.toDouble() ?? 0.0,
        memoryRecallScore: (json['memoryRecallScore'] as num?)?.toDouble() ?? 0.0,
        speechFluencyScore: (json['speechFluencyScore'] as num?)?.toDouble() ?? 0.0,
      );
}

class GameTypeBreakdown {
  final String gameType;
  final int count;
  final double avgScore;

  const GameTypeBreakdown({
    required this.gameType,
    required this.count,
    required this.avgScore,
  });

  factory GameTypeBreakdown.fromJson(Map<String, dynamic> json) => GameTypeBreakdown(
        gameType: json['gameType']?.toString() ?? 'unknown',
        count: (json['count'] as num?)?.toInt() ?? 0,
        avgScore: (json['avgScore'] as num?)?.toDouble() ?? 0.0,
      );
}

class FamilyMemory {
  final String id;
  final String title;
  final String? description;
  final String? mediaUrl;
  final String mediaType;
  final List<Map<String, String>> associatedPeople;
  final String? audioPromptUrl;

  const FamilyMemory({
    required this.id,
    required this.title,
    this.description,
    this.mediaUrl,
    required this.mediaType,
    required this.associatedPeople,
    this.audioPromptUrl,
  });

  factory FamilyMemory.fromJson(Map<String, dynamic> json) {
    final people = (json['associatedPeople'] as List? ?? []).map((e) {
      final m = e as Map<String, dynamic>;
      return {
        'name': m['name']?.toString() ?? '',
        'relation': m['relation']?.toString() ?? '',
      };
    }).toList();

    return FamilyMemory(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      mediaUrl: json['mediaUrl']?.toString(),
      mediaType: json['mediaType']?.toString() ?? 'image',
      associatedPeople: people,
      audioPromptUrl: json['audioPromptUrl']?.toString(),
    );
  }
}
