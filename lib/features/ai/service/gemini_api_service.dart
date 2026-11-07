import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:libretrac/core/database/app_database.dart';
import 'package:libretrac/core/database/extensions/extensions.dart';
import 'package:libretrac/features/mood_sleep/model/dream_metadata.dart';
import 'package:libretrac/features/substances/model/medication_dose_log.dart';
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
  String? _currentModelName;

  Future<void> _ensureInitialized() async {
    final apiKey = await PrefsService.getGeminiApiKey();
    final modelName = await PrefsService.getGeminiModel();

    // Reinitialize if API key or model changed
    if (apiKey != _currentApiKey || modelName != _currentModelName) {
      _currentApiKey = apiKey;
      _currentModelName = modelName;
      if (apiKey != null && apiKey.isNotEmpty) {
        _model = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
          ),
        );
        _textModel = GenerativeModel(
          model: modelName,
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
You are a data analyst specialised in mood, cognition, sleep, dream psychology, and pharmacology.
Analyse the JSON-encoded data and identify any correlations, patterns, or concerning trends across:
- Mood metrics & notes
- Sleep duration, quality, dream tags, dream recall clarity, and dream narratives
- Cognitive test performance (Reaction Time, Stroop Δ, Go/No-Go, Digit Span, Symbol Search)
- Active medications & supplements

Refer to entries by date, not by ID.
Respond in concise, well-structured Markdown with clear headings.

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

  /// Analyzes a single sleep & dream entry in context of recent mood and active stack.
  Future<String> analyzeDreamEntry({
    required SleepEntry entry,
    List<MoodEntry> recentMoods = const [],
    List<Substance> activeSubstances = const [],
    List<SleepEntry> recentSleeps = const [],
  }) async {
    await _ensureInitialized();

    if (_textModel == null) {
      return _noApiKeyMessage;
    }

    final dreamInstructions = await PrefsService.getEffectiveDreamInstructions();

    final payload = {
      'targetSleepEntry': entry.toExportJson(),
      if (recentSleeps.isNotEmpty)
        'recentSleepHistory': recentSleeps.map((s) => s.toExportJson()).toList(),
      if (recentMoods.isNotEmpty)
        'recentMoodCheckIns': recentMoods.map((m) => m.toExportJson()).toList(),
      if (activeSubstances.isNotEmpty)
        'activeSubstances':
            activeSubstances.map((s) => s.toExportJson()).toList(),
    };

    final prompt = '''
You are an expert in sleep analysis, dream interpretation, and behavioral health.
Analyze the user's `targetSleepEntry` (including hours slept, sleep quality, dream title, dream tags, recall clarity, and dream narrative) in the context of their recent mood check-ins, sleep history, and active supplements/medications.

Dream Interpretation Lens & User Instructions:
$dreamInstructions

Structure your response in concise Markdown with:
1. **🌙 Dream Interpretation & Themes**: Key imagery, themes, or patterns interpreted through the user's chosen lens above (or sleep quality reflection if no narrative was logged).
2. **🔗 Sleep, Mood & Stack Connections**: How this night's sleep/dream relates to recent mood metrics, sleep debt, or active substances/supplements (e.g., compounds known to affect REM sleep or dream vividness).
3. **💡 Takeaway & Reflection**: One brief, practical takeaway or reflective question aligned with the user's interpretation lens.

Data:
${const JsonEncoder.withIndent('  ').convert(payload)}
''';

    try {
      final response = await _textModel!.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? 'No dream analysis available.';
    } catch (e) {
      return '⚠️ Error analyzing dream entry: $e';
    }
  }

  /// Continues a multi-turn follow-up chat about a specific sleep & dream entry.
  Future<String> continueDreamChat({
    required SleepEntry entry,
    required List<DreamChatMessage> history,
    required String userQuestion,
    List<MoodEntry> recentMoods = const [],
    List<Substance> activeSubstances = const [],
    List<SleepEntry> recentSleeps = const [],
  }) async {
    await _ensureInitialized();

    if (_textModel == null) {
      return _noApiKeyMessage;
    }

    final dreamInstructions = await PrefsService.getEffectiveDreamInstructions();

    final payload = {
      'targetSleepEntry': entry.toExportJson(),
      if (recentSleeps.isNotEmpty)
        'recentSleepHistory': recentSleeps.map((s) => s.toExportJson()).toList(),
      if (recentMoods.isNotEmpty)
        'recentMoodCheckIns': recentMoods.map((m) => m.toExportJson()).toList(),
      if (activeSubstances.isNotEmpty)
        'activeSubstances':
            activeSubstances.map((s) => s.toExportJson()).toList(),
    };

    final systemContext = '''
You are an expert in sleep analysis, dream interpretation, and behavioral health assisting the user with a specific sleep & dream check-in.
Use the user's sleep/dream entry, recent mood check-ins, sleep history, and active supplements/medications below to answer their follow-up questions thoughtfully and concisely in Markdown.

Dream Interpretation Lens & User Instructions:
$dreamInstructions

Context Data:
${const JsonEncoder.withIndent('  ').convert(payload)}
''';

    final contents = <Content>[
      Content.text(systemContext),
      Content.model([
        TextPart(
          'Understood. I have reviewed the sleep entry, dream journal, mood check-ins, and active stack.',
        ),
      ]),
      for (final msg in history)
        msg.isUser
            ? Content.text(msg.text)
            : Content.model([TextPart(msg.text)]),
      Content.text(userQuestion),
    ];

    try {
      final response = await _textModel!.generateContent(contents);
      return response.text?.trim() ?? 'No response available.';
    } catch (e) {
      return '⚠️ Error getting follow-up response: $e';
    }
  }

  /// Analyzes multi-night dream and sleep patterns across a time window.
  Future<String> analyzeDreamAndSleepPatterns({
    required List<SleepEntry> sleeps,
    List<MoodEntry> moods = const [],
    List<Substance> substances = const [],
  }) async {
    await _ensureInitialized();

    if (_textModel == null) {
      return _noApiKeyMessage;
    }

    final dreamInstructions = await PrefsService.getEffectiveDreamInstructions();

    final payload = {
      'sleepAndDreamEntries': sleeps.map((s) => s.toExportJson()).toList(),
      if (moods.isNotEmpty)
        'moodEntries': moods.map((m) => m.toExportJson()).toList(),
      if (substances.isNotEmpty)
        'substances': substances.map((s) => s.toExportJson()).toList(),
    };

    final prompt = '''
You are a sleep researcher and dream analyst.
Analyze the user's sleep and dream journal history alongside their mood check-ins and active substances.

Dream Interpretation Lens & User Instructions:
$dreamInstructions

Provide a concise, insightful Markdown report covering:
1. **📊 Sleep Architecture & Consistency**: Trends in hours slept, subjective sleep quality, and dream recall clarity.
2. **💭 Recurring Dream Motifs & Tags**: Patterns in dream tags (e.g., Vivid, Lucid, Nightmare, Peaceful, Recurring) and narrative themes interpreted through the user's chosen lens.
3. **🧠 Next-Day Mood & Pharmacology Links**: Correlations between sleep quality/dream types and mood metrics or supplements/medications.
4. **✨ Recommendations**: 2–3 tailored suggestions for improving sleep quality or dream reflection.

Refer to entries by date, not by ID.

Data:
${const JsonEncoder.withIndent('  ').convert(payload)}
''';

    try {
      final response = await _textModel!.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? 'No sleep pattern analysis available.';
    } catch (e) {
      return '⚠️ Error analyzing sleep patterns: $e';
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
    this.medicationLogs = const [],
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
  final List<MedicationDoseLog> medicationLogs;

  Map<String, dynamic> toMap() => {
    'since': since.toIso8601String(),
    'moodEntries': moods.map((m) => m.toExportJson()).toList(),
    'reactionResults': reactions.map((c) => c.toExportJson()).toList(),
    'stroopResults': stroop.map((s) => s.toExportJson()).toList(),
    'goNoGoResults': goNoGo.map((g) => g.toExportJson()).toList(),
    'digitSpanResults': digitSpan.map((d) => d.toExportJson()).toList(),
    'symbolSearchResults': symbolSearch.map((s) => s.toExportJson()).toList(),
    'substances': substances.map((s) => s.toExportJson()).toList(),
    'medicationDoseLogs': medicationLogs.map((l) => l.toExportJson()).toList(),
    'sleeps': sleeps.map((s) => s.toExportJson()).toList(),
  };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toMap());
}
