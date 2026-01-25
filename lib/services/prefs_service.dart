import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  static const _remindersKey = 'checkinRemindersEnabled';
  static const _geminiApiKeyKey = 'gemini_api_key';

  static Future<bool> checkinRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_remindersKey) ?? true;
  }

  static Future<void> setCheckinRemindersEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_remindersKey, value);
  }

  static Future<String?> getGeminiApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_geminiApiKeyKey);
  }

  static Future<void> setGeminiApiKey(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null || value.isEmpty) {
      await prefs.remove(_geminiApiKeyKey);
    } else {
      await prefs.setString(_geminiApiKeyKey, value);
    }
  }

  static Future<bool> hasGeminiApiKey() async {
    final key = await getGeminiApiKey();
    return key != null && key.isNotEmpty;
  }
}
