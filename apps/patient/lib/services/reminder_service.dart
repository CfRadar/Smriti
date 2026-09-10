import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reminder_model.dart';

class ReminderService {
  static final ReminderService instance = ReminderService._internal();
  ReminderService._internal();

  static const String _cacheKey = 'smriti_cached_reminders';
  static const String _patientIdKey = 'smriti_active_patient_id';
  static const List<String> _candidateBaseUrls = [
    'http://10.0.2.2:5000/api',
    'http://localhost:5000/api',
    'http://127.0.0.1:5000/api',
  ];

  Future<String> _resolveBaseUrl() async {
    for (final candidate in _candidateBaseUrls) {
      try {
        final response = await http
            .get(Uri.parse('$candidate/patients'))
            .timeout(const Duration(seconds: 1));
        if (response.statusCode < 500) {
          return candidate;
        }
      } catch (_) {}
    }

    return kIsWeb ? 'http://localhost:5000/api' : 'http://10.0.2.2:5000/api';
  }

  /// Resolves active patient ID from cache or API
  Future<String> getActivePatientId() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_patientIdKey);
    if (savedId != null && savedId.isNotEmpty) {
      return savedId;
    }

    final baseUrl = await _resolveBaseUrl();

    try {
      final response = await http
          .get(Uri.parse('$baseUrl/patients'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = decoded['data'] ?? decoded;
        if (list is List && list.isNotEmpty) {
          final firstId = list[0]['_id']?.toString() ?? list[0]['id']?.toString() ?? '';
          if (firstId.isNotEmpty) {
            await prefs.setString(_patientIdKey, firstId);
            return firstId;
          }
        }
      }
    } catch (_) {}

    return 'demo-patient-001';
  }

  /// Fetches reminders for the current patient, falling back to local cache if offline
  Future<List<PatientReminder>> fetchReminders({String? patientId}) async {
    final pId = patientId ?? await getActivePatientId();
    final baseUrl = await _resolveBaseUrl();

    try {
      final response = await http
          .get(Uri.parse('$baseUrl/reminders/$pId'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final dynamic rawList = decoded['data'] ?? decoded;

        if (rawList is List) {
          final reminders = rawList
              .map((item) => PatientReminder.fromJson(Map<String, dynamic>.from(item)))
              .toList();

          // Cache locally for offline availability
          await _cacheReminders(reminders);
          return reminders;
        }
      }
    } catch (e) {
      debugPrint('ReminderService: network fetch failed ($e), reading local cache');
    }

    return getCachedReminders();
  }

  /// Acknowledges/completes a reminder both on the backend and locally
  Future<bool> acknowledgeReminder(String reminderId) async {
    bool networkSuccess = false;
    final baseUrl = await _resolveBaseUrl();
    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl/reminders/$reminderId/status'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'status': 'acknowledged'}),
          )
          .timeout(const Duration(seconds: 4));

      networkSuccess = response.statusCode == 200;
    } catch (e) {
      debugPrint('ReminderService: error marking reminder acknowledged online: $e');
    }

    // Update local cache
    final local = await getCachedReminders();
    final updated = local.map((r) {
      if (r.id == reminderId) {
        return PatientReminder(
          id: r.id,
          title: r.title,
          description: r.description,
          type: r.type,
          scheduledTime: r.scheduledTime,
          repeat: r.repeat,
          isVoicePromptEnabled: r.isVoicePromptEnabled,
          voicePromptText: r.voicePromptText,
          status: 'acknowledged',
        );
      }
      return r;
    }).toList();

    await _cacheReminders(updated);
    return networkSuccess;
  }

  Future<void> _cacheReminders(List<PatientReminder> reminders) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = reminders.map((r) => jsonEncode(r.toJson())).toList();
      await prefs.setStringList(_cacheKey, list);
    } catch (e) {
      debugPrint('ReminderService: failed to cache reminders: $e');
    }
  }

  Future<List<PatientReminder>> getCachedReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_cacheKey) ?? [];
      return rawList
          .map((item) => PatientReminder.fromJson(jsonDecode(item)))
          .toList();
    } catch (e) {
      debugPrint('ReminderService: failed to read cached reminders: $e');
      return [];
    }
  }
}
