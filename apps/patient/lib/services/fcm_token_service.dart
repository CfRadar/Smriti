// lib/services/fcm_token_service.dart
//
// Handles FCM device token registration with the Smriti backend.
// When firebase_messaging is added in the future, replace _getDeviceToken()
// with `await FirebaseMessaging.instance.getToken()`.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FcmTokenService {
  FcmTokenService._();
  static final FcmTokenService instance = FcmTokenService._();

  // ── Config ──────────────────────────────────────────────────────────────────
  static const String _baseUrl = 'http://10.0.2.2:5000'; // emulator → localhost
  // For physical device, replace with your LAN IP: 'http://192.168.x.x:5000'

  static const String _tokenKey = 'smriti_fcm_token';
  static const String _jwtKey = 'smriti_jwt_token';

  // ── Public API ───────────────────────────────────────────────────────────────

  /// Call this right after a successful login.
  /// Saves the JWT locally, gets (or generates) an FCM token, and
  /// registers it with the backend.
  Future<void> registerAfterLogin(String jwtToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_jwtKey, jwtToken);

      final fcmToken = await _getDeviceToken(prefs);
      if (fcmToken == null) return;

      await _sendTokenToBackend(jwtToken, fcmToken);
    } catch (e) {
      // Non-fatal — app works without push notifications
      debugPrint('[FcmTokenService] Registration failed (non-fatal): $e');
    }
  }

  /// Clears stored tokens on logout.
  Future<void> clearOnLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_jwtKey);
    await prefs.remove(_tokenKey);
  }

  // ── Internal ─────────────────────────────────────────────────────────────────

  /// Gets the current FCM token.
  /// TODO: Replace with FirebaseMessaging.instance.getToken() once
  ///       firebase_messaging is added to pubspec.yaml.
  Future<String?> _getDeviceToken(SharedPreferences prefs) async {
    // Check if we already have a cached token
    final cached = prefs.getString(_tokenKey);
    if (cached != null && cached.isNotEmpty) return cached;

    // ── STUB ──
    // Until firebase_messaging is wired up, we generate a unique
    // device identifier as a placeholder token so the backend stores
    // something meaningful. Replace this block when adding Firebase.
    final stubToken = 'smriti-stub-${DateTime.now().millisecondsSinceEpoch}';
    await prefs.setString(_tokenKey, stubToken);
    debugPrint('[FcmTokenService] Using stub token: $stubToken');
    return stubToken;

    // ── FUTURE: real Firebase token ──
    // final token = await FirebaseMessaging.instance.getToken();
    // if (token != null) await prefs.setString(_tokenKey, token);
    // return token;
  }

  /// Calls PATCH /api/auth/device-token with the FCM token.
  Future<void> _sendTokenToBackend(String jwtToken, String fcmToken) async {
    final uri = Uri.parse('$_baseUrl/api/auth/device-token');
    final response = await http.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      },
      body: jsonEncode({'fcmToken': fcmToken}),
    );

    if (response.statusCode == 200) {
      debugPrint('[FcmTokenService] ✅ Device token registered with backend.');
    } else {
      debugPrint(
        '[FcmTokenService] ⚠️ Backend returned ${response.statusCode}: ${response.body}',
      );
    }
  }
}
