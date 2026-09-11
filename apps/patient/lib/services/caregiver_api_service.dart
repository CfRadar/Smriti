// lib/services/caregiver_api_service.dart
// All caregiver API calls — login, analytics, reminders, family memories.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/caregiver_models.dart';
import '../models/reminder_model.dart';

class CaregiverApiService {
  CaregiverApiService._();
  static final CaregiverApiService instance = CaregiverApiService._();

  // ── Storage keys ────────────────────────────────────────────────────────────
  static const String _jwtKey = 'smriti_caregiver_jwt';
  static const String _caregiverIdKey = 'smriti_caregiver_id';
  static const String _patientIdKey = 'smriti_caregiver_patient_id';

  // ── Base URL (same resolution as ReminderService) ───────────────────────────
  static const List<String> _candidates = [
    'http://10.0.2.2:5000/api',
    'http://localhost:5000/api',
    'http://127.0.0.1:5000/api',
  ];

  String? _resolvedBase;

  Future<String> get _base async {
    if (_resolvedBase != null) return _resolvedBase!;
    for (final c in _candidates) {
      try {
        final r = await http
            .get(Uri.parse('$c/../health'))
            .timeout(const Duration(seconds: 1));
        if (r.statusCode < 500) {
          _resolvedBase = c;
          return c;
        }
      } catch (_) {}
    }
    _resolvedBase = kIsWeb ? 'http://localhost:5000/api' : 'http://10.0.2.2:5000/api';
    return _resolvedBase!;
  }

  // ── Auth helpers ─────────────────────────────────────────────────────────────

  Future<String?> get savedToken async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_jwtKey);
  }

  Future<String?> get savedPatientId async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_patientIdKey);
  }

  Future<bool> get isLoggedIn async => (await savedToken) != null;

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_jwtKey);
    await prefs.remove(_caregiverIdKey);
    await prefs.remove(_patientIdKey);
  }

  Map<String, String> _authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // ── Login ────────────────────────────────────────────────────────────────────

  /// Returns null on success, error message on failure.
  Future<String?> login(String email, String password) async {
    try {
      final base = await _base;
      final response = await http.post(
        Uri.parse('$base/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'] as Map<String, dynamic>;
        final auth = CaregiverAuth.fromJson(data);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_jwtKey, auth.token);
        await prefs.setString(_caregiverIdKey, auth.userId);

        // Fetch first assigned patient
        await _fetchAndCachePatientId(auth.token, base);
        return null; // success
      }

      final body = jsonDecode(response.body);
      return body['message']?.toString() ?? 'Login failed (${response.statusCode})';
    } catch (e) {
      return 'Network error: $e';
    }
  }

  Future<void> _fetchAndCachePatientId(String token, String base) async {
    try {
      final r = await http
          .get(Uri.parse('$base/patients'), headers: _authHeaders(token))
          .timeout(const Duration(seconds: 5));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body)['data'];
        if (data is List && data.isNotEmpty) {
          final pid = data[0]['_id']?.toString() ?? '';
          if (pid.isNotEmpty) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_patientIdKey, pid);
          }
        }
      }
    } catch (e) {
      debugPrint('[CaregiverApiService] Could not fetch patient id: $e');
    }
  }

  // ── Analytics ────────────────────────────────────────────────────────────────

  Future<AnalyticsSummary?> fetchAnalytics(String patientId) async {
    try {
      final token = await savedToken;
      if (token == null) return null;
      final base = await _base;
      final r = await http
          .get(Uri.parse('$base/analytics/dashboard/$patientId'),
              headers: _authHeaders(token))
          .timeout(const Duration(seconds: 8));
      if (r.statusCode == 200) {
        return AnalyticsSummary.fromJson(jsonDecode(r.body)['data']);
      }
    } catch (e) {
      debugPrint('[CaregiverApiService] analytics error: $e');
    }
    return null;
  }

  // ── Reminders ────────────────────────────────────────────────────────────────

  Future<List<PatientReminder>> fetchReminders(String patientId) async {
    try {
      final token = await savedToken;
      if (token == null) return [];
      final base = await _base;
      final r = await http
          .get(Uri.parse('$base/reminders/$patientId'),
              headers: _authHeaders(token))
          .timeout(const Duration(seconds: 6));
      if (r.statusCode == 200) {
        final list = jsonDecode(r.body)['data'] as List? ?? [];
        return list
            .map((e) => PatientReminder.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('[CaregiverApiService] reminders error: $e');
    }
    return [];
  }

  Future<bool> createReminder({
    required String patientId,
    required String title,
    required String type,
    required DateTime scheduledTime,
    String? description,
    String? voicePromptText,
    String repeat = 'daily',
    bool isVoicePromptEnabled = true,
  }) async {
    try {
      final token = await savedToken;
      if (token == null) return false;
      final base = await _base;
      final r = await http
          .post(
            Uri.parse('$base/reminders'),
            headers: _authHeaders(token),
            body: jsonEncode({
              'patientId': patientId,
              'title': title,
              'description': description ?? '',
              'type': type,
              'scheduledTime': scheduledTime.toIso8601String(),
              'repeat': repeat,
              'isVoicePromptEnabled': isVoicePromptEnabled,
              'voicePromptText': voicePromptText ?? title,
            }),
          )
          .timeout(const Duration(seconds: 6));
      return r.statusCode == 201;
    } catch (e) {
      debugPrint('[CaregiverApiService] create reminder error: $e');
      return false;
    }
  }

  Future<bool> deleteReminder(String reminderId) async {
    try {
      final token = await savedToken;
      if (token == null) return false;
      final base = await _base;
      final r = await http
          .delete(Uri.parse('$base/reminders/$reminderId'),
              headers: _authHeaders(token))
          .timeout(const Duration(seconds: 6));
      return r.statusCode == 200;
    } catch (e) {
      debugPrint('[CaregiverApiService] delete reminder error: $e');
      return false;
    }
  }

  Future<bool> updateReminderStatus(String reminderId, String status) async {
    try {
      final token = await savedToken;
      if (token == null) return false;
      final base = await _base;
      final r = await http
          .patch(
            Uri.parse('$base/reminders/$reminderId/status'),
            headers: _authHeaders(token),
            body: jsonEncode({'status': status}),
          )
          .timeout(const Duration(seconds: 6));
      return r.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ── Family Memories ──────────────────────────────────────────────────────────

  Future<List<FamilyMemory>> fetchMemories(String patientId) async {
    try {
      final token = await savedToken;
      if (token == null) return [];
      final base = await _base;
      final r = await http
          .get(Uri.parse('$base/family/$patientId'),
              headers: _authHeaders(token))
          .timeout(const Duration(seconds: 6));
      if (r.statusCode == 200) {
        final list = jsonDecode(r.body)['data'] as List? ?? [];
        return list
            .map((e) => FamilyMemory.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('[CaregiverApiService] memories error: $e');
    }
    return [];
  }

  Future<bool> addMemory({
    required String patientId,
    required String title,
    String? description,
    String? mediaUrl,
    List<Map<String, String>> associatedPeople = const [],
  }) async {
    try {
      final token = await savedToken;
      if (token == null) return false;
      final base = await _base;
      final r = await http
          .post(
            Uri.parse('$base/family'),
            headers: _authHeaders(token),
            body: jsonEncode({
              'patientId': patientId,
              'title': title,
              'description': description ?? '',
              'mediaUrl': mediaUrl ?? '',
              'mediaType': 'image',
              'associatedPeople': associatedPeople,
            }),
          )
          .timeout(const Duration(seconds: 6));
      return r.statusCode == 201;
    } catch (e) {
      debugPrint('[CaregiverApiService] add memory error: $e');
      return false;
    }
  }

  Future<bool> deleteMemory(String memoryId) async {
    try {
      final token = await savedToken;
      if (token == null) return false;
      final base = await _base;
      final r = await http
          .delete(Uri.parse('$base/family/$memoryId'),
              headers: _authHeaders(token))
          .timeout(const Duration(seconds: 6));
      return r.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
