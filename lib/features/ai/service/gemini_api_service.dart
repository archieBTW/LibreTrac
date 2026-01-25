import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:libretrac/core/database/app_database.dart';
import 'package:libretrac/core/database/extensions/extensions.dart';
import 'package:libretrac/services/prefs_service.dart';

const _noApiKeyMessage = '''
## 🔑 API Key Required

To use AI features, you need a free Gemini API key.

**How to get your key:**

1. Go to **aistudio.google.com**
2. Sign in with your Google account
3. Click **"Get API key"** in the left menu
4. Click **"Create API key"**
5. Copy the key

**Then in LibreTrac:**

Go to **Settings → Gemini API Key** and paste your key.

That's it! AI features will work immediately.
''';

class GeminiAPI {
  GeminiAPI._();
  
  static final instance = GeminiAPI._();
  
  GenerativeModel? _model;
  GenerativeModel? _textModel;
  String? _currentApiKey;

  Future<void> _ensureInitialized() async {
    final apiKey = await PrefsService.getGeminiApiKey();
    
    // Reinitialize if API key changed
    if (apiKey != _currentApiKey) {
      _currentApiKey = apiKey;
      if (apiKey != null && apiKey.isNotEmpty) {
        _model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
          ),
        );
        _textModel = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: apiKey,
        );
      } else {
        _model = null;
        _textModel = null;
      }
    }
  }

  Future<String> getSubstanceProfile(
    String substanceName,
    List<String> currentStack, {
    String? notes,
  }) async {
    await _ensureInitialized();
    
    if (_model == null) {
      return _noApiKeyMessage;
    }

    final filteredStack =
        currentStack
            .where((s) => s.toLowerCase() != substanceName.toLowerCase())
            .toList();

    final prompt = '''
You are a clinical pharmacist.
Respond ONLY with valid JSON in the format:
{ "benefits": ["..."], "cautions": ["..."], "ingredients": ["..."] if applicable, "interactsWith": ["..."] (ONLY those from the stack that interact) }.
Take the user's notes into account if relevant.

Substance: $substanceName
User notes: ${notes ?? 'none'}
Current stack: ${filteredStack.join(', ')}.
Give its benefits, cautions, ingredients (if compound), and ONLY include interactions between the given substance and substances from the stack that are known to interact, not just all interactions in the stack.
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      final raw = response.text?.trim() ?? '';

      Map<String, dynamic> decoded;
      try {
        decoded = jsonDecode(raw);
      } catch (_) {
        return '⚠️ Failed to parse substance info.';
      }

      final b = (decoded['benefits'] as List?)?.cast<String>() ?? [];
      final c = (decoded['cautions'] as List?)?.cast<String>() ?? [];
      final i = (decoded['ingredients'] as List?)?.cast<String>() ?? [];
      final x = (decoded['interactsWith'] as List?)?.cast<String>() ?? [];

      return [
        '## ✅ Benefits',
        if (b.isNotEmpty) ...b.map((e) => '- $e') else ['- None noted.'],
        '\n## ⚠️ Cautions',
        if (c.isNotEmpty) ...c.map((e) => '- $e') else ['- No known cautions.'],
        if (i.isNotEmpty) ...['\n## 🧪 Ingredients', ...i.map((e) => '- $e')],
        if (x.isNotEmpty) ...[
          '\n## 🔗 Interactions with Your Stack',
          ...x.map((e) => '- $e'),
        ],
      ].join('\n');
    } catch (e) {
      return '⚠️ Error fetching substance info: $e';
    }
  }

  Future<String> analyzeTrends(TrendRequest req) async {
    await _ensureInitialized();
    
    if (_textModel == null) {
      return _noApiKeyMessage;
    }

    final prompt = '''
You are a data analyst specialised in mood, cognition, sleep and pharmacology.
Analyse the JSON-encoded data and identify any correlations or concerning trends.
Refer to entries by date, not by ID.
Respond in concise Markdown.

Here is the anonymised data:
${req.toPrettyJson()}
''';

    try {
      final response = await _textModel!.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? 'No analysis available.';
    } catch (e) {
      return '⚠️ Error analyzing trends: $e';
    }
  }
}

class TrendRequest {
  TrendRequest({
    required this.since,
    required this.moods,
    required this.reactions,
    required this.stroop,
    required this.goNoGo,
    required this.digitSpan,
    required this.symbolSearch,
    required this.substances,
    required this.sleeps,
  });

  final DateTime since;
  final List<MoodEntry> moods;
  final List<ReactionResult> reactions;
  final List<StroopResult> stroop;
  final List<GoNoGoResult> goNoGo;
  final List<DigitSpanResult> digitSpan;
  final List<SymbolSearchResult> symbolSearch;
  final List<Substance> substances;
  final List<SleepEntry> sleeps;

  Map<String, dynamic> toMap() => {
    'since': since.toIso8601String(),
    'moodEntries': moods.map((m) => m.toExportJson()).toList(),
    'reactionResults': reactions.map((c) => c.toExportJson()).toList(),
    'stroopResults': stroop.map((s) => s.toExportJson()).toList(),
    'goNoGoResults': goNoGo.map((g) => g.toExportJson()).toList(),
    'digitSpanResults': digitSpan.map((d) => d.toExportJson()).toList(),
    'symbolSearchResults': symbolSearch.map((s) => s.toExportJson()).toList(),
    'substances': substances.map((s) => s.toExportJson()).toList(),
    'sleeps': sleeps.map((s) => s.toExportJson()).toList(),
  };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toMap());
}
