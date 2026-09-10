import 'package:shared_preferences/shared_preferences.dart';

/// Service to track and manage patient daily engagement streak.
class StreakService {
  StreakService._();
  static final StreakService instance = StreakService._();

  static const String _keyStreakCount = 'smriti_daily_streak_count';
  static const String _keyLastActiveDate = 'smriti_last_active_date';
  static const String _keyCelebratedDate = 'smriti_streak_celebrated_date';
  static const String _keyIceBreakPending = 'smriti_ice_break_pending';

  String _formatDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  /// Checks if streak is currently broken (last active date was before yesterday and not today).
  Future<bool> isStreakBroken() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActiveStr = prefs.getString(_keyLastActiveDate);
    if (lastActiveStr == null) return false;

    final today = DateTime.now();
    final todayStr = _formatDate(today);
    final yesterdayStr = _formatDate(today.subtract(const Duration(days: 1)));

    if (lastActiveStr == todayStr || lastActiveStr == yesterdayStr) {
      return false;
    }
    return true;
  }

  /// Whether an ice breaking celebration should be performed when the user opens the app.
  Future<bool> shouldShowIceBreakAnimation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIceBreakPending) ?? false;
  }

  /// Evaluates and returns the active streak count for today.
  Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = _formatDate(today);
    final yesterdayStr = _formatDate(today.subtract(const Duration(days: 1)));
    final lastActiveStr = prefs.getString(_keyLastActiveDate);
    var streak = prefs.getInt(_keyStreakCount);

    if (streak == null || lastActiveStr == null) {
      // First session: start fresh with 1
      streak = 1;
      await prefs.setInt(_keyStreakCount, streak);
      await prefs.setString(_keyLastActiveDate, todayStr);
      await prefs.setBool(_keyIceBreakPending, false);
      return streak;
    }

    if (lastActiveStr == todayStr) {
      return streak;
    }

    if (lastActiveStr == yesterdayStr) {
      // Logged in consecutive day!
      streak += 1;
      await prefs.setBool(_keyIceBreakPending, false);
    } else {
      // Streak broken (gap > 1 day) -> triggers ice breaking animation, resets to 1
      streak = 1;
      await prefs.setBool(_keyIceBreakPending, true);
    }

    await prefs.setInt(_keyStreakCount, streak);
    await prefs.setString(_keyLastActiveDate, todayStr);
    return streak;
  }

  /// Whether the daily celebratory intro overlay should be shown for today.
  Future<bool> shouldShowCelebration() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = _formatDate(DateTime.now());
    final lastCelebrated = prefs.getString(_keyCelebratedDate);
    final iceBreak = prefs.getBool(_keyIceBreakPending) ?? false;
    return iceBreak || lastCelebrated != todayStr;
  }

  /// Marks today's celebration (and any pending ice break) as completed.
  Future<void> markCelebrationShown() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = _formatDate(DateTime.now());
    await prefs.setString(_keyCelebratedDate, todayStr);
    await prefs.setBool(_keyIceBreakPending, false);
  }

  /// Helper for manual test resets
  Future<void> resetForTesting({
    int streak = 1,
    bool resetCelebration = true,
    bool forceIceBreak = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyStreakCount, streak);
    if (resetCelebration) {
      await prefs.remove(_keyCelebratedDate);
    }
    await prefs.setBool(_keyIceBreakPending, forceIceBreak);
  }
}
