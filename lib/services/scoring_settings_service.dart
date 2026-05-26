import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing AI vs random scoring settings
class ScoringSettingsService {
  static const String _useAIScoringKey = 'use_ai_scoring';

  /// Get whether AI scoring is enabled
  Future<bool> getUseAIScoring() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to AI scoring
    return prefs.getBool(_useAIScoringKey) ?? true;
  }

  /// Set whether AI scoring is enabled
  Future<void> setUseAIScoring(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useAIScoringKey, enabled);
  }

  /// Toggle AI scoring on/off
  Future<bool> toggleAIScoring() async {
    final currentValue = await getUseAIScoring();
    final newValue = !currentValue;
    await setUseAIScoring(newValue);
    return newValue;
  }
}
