import 'package:shared_preferences/shared_preferences.dart';

class GeminiModelOption {
  final String id;
  final String label;
  final String description;

  const GeminiModelOption({
    required this.id,
    required this.label,
    required this.description,
  });
}

const List<GeminiModelOption> kGeminiModelOptions = [
  GeminiModelOption(
    id: 'gemini-3.8-flash',
    label: 'Gemini 3.8 Flash',
    description: 'Balanced speed and intelligence for trend & dream analysis',
  ),
  GeminiModelOption(
    id: 'gemini-3.5-flash-lite',
    label: 'Gemini 3.5 Flash-Lite',
    description: 'Fast, lightweight responses',
  ),
];

class DreamLensOption {
  final String id;
  final String label;
  final String description;
  final String promptDirective;

  const DreamLensOption({
    required this.id,
    required this.label,
    required this.description,
    required this.promptDirective,
  });
}

const List<DreamLensOption> kDreamLensOptions = [
  DreamLensOption(
    id: 'psychological',
    label: 'Psychological & Sleep Science (Default)',
    description: 'Cognitive/emotional processing, symbolism, and sleep physiology',
    promptDirective:
        'Interpret dreams through a modern psychological, emotional-processing, and sleep-science lens.',
  ),
  DreamLensOption(
    id: 'christian',
    label: 'Christian / Biblical & Spiritual',
    description: 'Biblical symbolism, spiritual discernment, and prayerful reflection',
    promptDirective:
        'Interpret dreams through a Christian / Biblical and spiritual lens. Consider biblical symbolism, spiritual discernment, themes of grace, peace, or spiritual warfare where relevant, and offer a grounded, encouraging, faith-informed reflection alongside practical sleep/mood observations.',
  ),
  DreamLensOption(
    id: 'spiritual',
    label: 'Spiritual & Holistic Mindfulness',
    description: 'Intuitive symbolism, inner wisdom, and mind-body harmony',
    promptDirective:
        'Interpret dreams through a holistic spiritual and mindfulness lens, focusing on inner wisdom, intuitive symbolism, emotional alignment, and personal growth.',
  ),
  DreamLensOption(
    id: 'jungian',
    label: 'Jungian & Archetypal',
    description: 'Archetypes, shadow work, and unconscious symbolism',
    promptDirective:
        'Interpret dreams through a Jungian depth-psychology lens, exploring archetypes, the shadow, anima/animus, compensatory messages from the unconscious, and personal individuation.',
  ),
  DreamLensOption(
    id: 'neuroscience',
    label: 'Neuroscience & Pharmacology Only',
    description: 'Strictly biological: REM sleep, neurotransmitters, and supplements',
    promptDirective:
        'Use a strictly empirical neuroscience and pharmacology lens. Focus on REM sleep physiology, memory consolidation, stress hormones, mood metrics, and substance/supplement effects without symbolic or mystical interpretation.',
  ),
  DreamLensOption(
    id: 'custom',
    label: 'Custom Lens Only',
    description: 'Use only your custom dream interpretation instructions below',
    promptDirective: '',
  ),
];

class PrefsService {
  static const _remindersKey = 'checkinRemindersEnabled';
  static const _geminiApiKeyKey = 'gemini_api_key';
  static const _geminiModelKey = 'gemini_model';
  static const _dreamLensKey = 'dream_lens_preset';
  static const _dreamCustomInstructionsKey = 'dream_custom_instructions';

  static const defaultGeminiModel = 'gemini-3.8-flash';
  static const defaultDreamLens = 'psychological';

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

  static Future<String> getGeminiModel() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_geminiModelKey)?.trim();
    if (saved == null ||
        saved.isEmpty ||
        !kGeminiModelOptions.any((m) => m.id == saved)) {
      return defaultGeminiModel;
    }
    return saved;
  }

  static Future<void> setGeminiModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = model.trim();
    if (trimmed.isEmpty) {
      await prefs.setString(_geminiModelKey, defaultGeminiModel);
    } else {
      await prefs.setString(_geminiModelKey, trimmed);
    }
  }

  static String labelForModel(String modelId) {
    for (final opt in kGeminiModelOptions) {
      if (opt.id == modelId) return opt.label;
    }
    return '$modelId (Custom)';
  }

  static Future<String> getDreamLensPreset() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_dreamLensKey)?.trim();
    if (saved == null || saved.isEmpty) {
      return defaultDreamLens;
    }
    return saved;
  }

  static Future<void> setDreamLensPreset(String presetId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dreamLensKey, presetId.trim());
  }

  static Future<String> getDreamCustomInstructions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_dreamCustomInstructionsKey)?.trim() ?? '';
  }

  static Future<void> setDreamCustomInstructions(String? instructions) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = instructions?.trim() ?? '';
    if (trimmed.isEmpty) {
      await prefs.remove(_dreamCustomInstructionsKey);
    } else {
      await prefs.setString(_dreamCustomInstructionsKey, trimmed);
    }
  }

  static String labelForDreamLens(String presetId, {String? customText}) {
    final opt = kDreamLensOptions.firstWhere(
      (o) => o.id == presetId,
      orElse: () => kDreamLensOptions.first,
    );
    final hasCustom = customText != null && customText.trim().isNotEmpty;
    if (presetId == 'custom') {
      return hasCustom ? 'Custom Instructions' : 'Custom (Not set)';
    }
    return hasCustom ? '${opt.label} + Custom' : opt.label;
  }

  static Future<String> getEffectiveDreamInstructions() async {
    final presetId = await getDreamLensPreset();
    final custom = await getDreamCustomInstructions();

    final opt = kDreamLensOptions.firstWhere(
      (o) => o.id == presetId,
      orElse: () => kDreamLensOptions.first,
    );

    final parts = <String>[];
    if (opt.promptDirective.isNotEmpty) {
      parts.add(opt.promptDirective);
    }
    if (custom.isNotEmpty) {
      parts.add('Additional user interpretation instructions: $custom');
    }

    if (parts.isEmpty) {
      return kDreamLensOptions.first.promptDirective;
    }
    return parts.join('\n');
  }
}
