import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:libretrac/core/database/app_database.dart';
import 'package:libretrac/services/prefs_service.dart';

/// Standard dream tags with icons and colors for dream journaling and analysis.
class DreamTagDef {
  final String name;
  final IconData icon;
  final Color color;

  const DreamTagDef({
    required this.name,
    required this.icon,
    required this.color,
  });
}

const List<DreamTagDef> kDreamTags = [
  DreamTagDef(
    name: 'Vivid',
    icon: Icons.auto_awesome,
    color: Colors.amber,
  ),
  DreamTagDef(
    name: 'Lucid',
    icon: Icons.visibility,
    color: Colors.cyan,
  ),
  DreamTagDef(
    name: 'Peaceful',
    icon: Icons.spa,
    color: Colors.teal,
  ),
  DreamTagDef(
    name: 'Nightmare',
    icon: Icons.warning_amber_rounded,
    color: Colors.redAccent,
  ),
  DreamTagDef(
    name: 'Recurring',
    icon: Icons.repeat,
    color: Colors.indigoAccent,
  ),
  DreamTagDef(
    name: 'Bizarre',
    icon: Icons.blur_on,
    color: Colors.deepPurpleAccent,
  ),
  DreamTagDef(
    name: 'Emotional',
    icon: Icons.favorite_outline,
    color: Colors.pinkAccent,
  ),
  DreamTagDef(
    name: 'Stressful',
    icon: Icons.bolt,
    color: Colors.deepOrange,
  ),
];

DreamTagDef getDreamTagDef(String name) {
  return kDreamTags.firstWhere(
    (t) => t.name.toLowerCase() == name.toLowerCase(),
    orElse: () => DreamTagDef(
      name: name,
      icon: Icons.label_outline,
      color: Colors.blueGrey,
    ),
  );
}

/// A single message in the retained AI Dream Analysis & follow-up chat thread.
class DreamChatMessage {
  final String role; // 'user' or 'model'
  final String text;
  final DateTime? timestamp;

  const DreamChatMessage({
    required this.role,
    required this.text,
    this.timestamp,
  });

  bool get isUser => role == 'user';

  Map<String, dynamic> toJson() => {
    'role': role,
    'text': text,
    if (timestamp != null) 'ts': timestamp!.toIso8601String(),
  };

  factory DreamChatMessage.fromJson(Map<String, dynamic> json) {
    final tsRaw = json['ts'] as String?;
    return DreamChatMessage(
      role: (json['role'] as String?) ?? 'model',
      text: (json['text'] as String?) ?? '',
      timestamp: tsRaw != null ? DateTime.tryParse(tsRaw) : null,
    );
  }
}

/// Structured representation of a sleep entry's dream journal field.
/// Encodes optional metadata (title, tags, clarity, aiChat) in a lossless header comment
/// so existing SQLite tables and ZIP backups work seamlessly without schema breaks.
class ParsedDreamJournal {
  final String? title;
  final List<String> tags;
  final int? clarity; // 1-5 recall clarity
  final String text;
  final List<DreamChatMessage> aiChat;

  const ParsedDreamJournal({
    this.title,
    this.tags = const [],
    this.clarity,
    this.text = '',
    this.aiChat = const [],
  });

  ParsedDreamJournal copyWith({
    String? title,
    List<String>? tags,
    int? clarity,
    String? text,
    List<DreamChatMessage>? aiChat,
  }) {
    return ParsedDreamJournal(
      title: title ?? this.title,
      tags: tags ?? this.tags,
      clarity: clarity ?? this.clarity,
      text: text ?? this.text,
      aiChat: aiChat ?? this.aiChat,
    );
  }

  bool get isEmpty =>
      (title == null || title!.trim().isEmpty) &&
      tags.isEmpty &&
      clarity == null &&
      text.trim().isEmpty;

  bool get hasNarrative => text.trim().isNotEmpty;
  bool get hasAiChat => aiChat.isNotEmpty;

  static const _metaPrefix = '<!--dream_meta:';
  static const _metaSuffix = '-->';

  static ParsedDreamJournal parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const ParsedDreamJournal();
    }

    final trimmed = raw.trim();
    if (trimmed.startsWith(_metaPrefix)) {
      final endIdx = trimmed.indexOf(_metaSuffix);
      if (endIdx != -1) {
        final jsonStr =
            trimmed.substring(_metaPrefix.length, endIdx).trim();
        final body = trimmed.substring(endIdx + _metaSuffix.length).trim();
        try {
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          final title = (map['title'] as String?)?.trim();
          final tags = (map['tags'] as List?)
                  ?.map((e) => e.toString())
                  .where((e) => e.isNotEmpty)
                  .toList() ??
              const <String>[];
          final clarity = (map['clarity'] as num?)?.toInt();
          final rawChat = map['aiChat'] as List?;
          final aiChat =
              rawChat
                  ?.whereType<Map<String, dynamic>>()
                  .map(DreamChatMessage.fromJson)
                  .where((m) => m.text.trim().isNotEmpty)
                  .toList() ??
              const <DreamChatMessage>[];
          return ParsedDreamJournal(
            title: (title != null && title.isNotEmpty) ? title : null,
            tags: tags,
            clarity: clarity,
            text: body,
            aiChat: aiChat,
          );
        } catch (_) {
          // Fallback to plain text if malformed
        }
      }
    }

    return ParsedDreamJournal(text: trimmed);
  }

  /// Encodes back into a single nullable String for `SleepEntries.dreamJournal`.
  String? encode() {
    final cleanTitle = title?.trim();
    final cleanText = text.trim();
    final hasMeta = (cleanTitle != null && cleanTitle.isNotEmpty) ||
        tags.isNotEmpty ||
        clarity != null ||
        aiChat.isNotEmpty;

    if (!hasMeta && cleanText.isEmpty) {
      return null;
    }

    if (!hasMeta) {
      return cleanText;
    }

    final metaMap = <String, dynamic>{
      if (cleanTitle != null && cleanTitle.isNotEmpty) 'title': cleanTitle,
      if (tags.isNotEmpty) 'tags': tags,
      if (clarity != null) 'clarity': clarity,
      if (aiChat.isNotEmpty)
        'aiChat': aiChat.map((m) => m.toJson()).toList(),
    };

    final header = '$_metaPrefix${jsonEncode(metaMap)}$_metaSuffix';
    if (cleanText.isEmpty) {
      return header;
    }
    return '$header\n$cleanText';
  }
}

extension SleepEntryDreamX on SleepEntry {
  ParsedDreamJournal get parsedDream =>
      ParsedDreamJournal.parse(dreamJournal);

  String get dreamText => parsedDream.text;
  String? get dreamTitle => parsedDream.title;
  List<String> get dreamTags => parsedDream.tags;
  int? get dreamClarity => parsedDream.clarity;
  List<DreamChatMessage> get dreamAiChat => parsedDream.aiChat;
  bool get hasDream => !parsedDream.isEmpty;
  bool get hasAiChat => parsedDream.hasAiChat;

  String get dreamPreview {
    final p = parsedDream;
    if (p.title != null && p.title!.isNotEmpty && p.text.isNotEmpty) {
      return '${p.title!} — ${p.text.split('\n').first}';
    }
    if (p.title != null && p.title!.isNotEmpty) {
      return p.title!;
    }
    if (p.text.isNotEmpty) {
      return p.text.split('\n').first;
    }
    if (p.tags.isNotEmpty) {
      return 'Tags: ${p.tags.join(', ')}';
    }
    return '';
  }
}

String sleepQualityLabel(int quality) {
  return switch (quality) {
    1 => '1 · Poor',
    2 => '2 · Fair',
    3 => '3 · Okay',
    4 => '4 · Good',
    5 => '5 · Restorative',
    _ => '$quality / 5',
  };
}

String dreamClarityLabel(int clarity) {
  return switch (clarity) {
    1 => '1 · Hazy fragments',
    2 => '2 · Dim recall',
    3 => '3 · Moderate recall',
    4 => '4 · Clear recall',
    5 => '5 · Crystal clear',
    _ => '$clarity / 5',
  };
}

/// Opens a dialog allowing the user to select a Dream Interpretation Lens preset
/// (e.g., Psychological, Christian/Biblical, Spiritual, Jungian, Neuroscience)
/// and/or enter custom interpretation instructions.
/// Returns `true` if settings were saved.
Future<bool> showDreamLensDialog(BuildContext context) async {
  String selectedPreset = await PrefsService.getDreamLensPreset();
  final existingCustom = await PrefsService.getDreamCustomInstructions();
  final customController = TextEditingController(text: existingCustom);

  if (!context.mounted) return false;

  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) {
      return StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.auto_fix_high_outlined),
                SizedBox(width: 8),
                Expanded(child: Text('Dream Interpretation Lens')),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose the perspective Gemini uses when interpreting your dreams and answering follow-up questions:',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    for (final opt in kDreamLensOptions)
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        value: opt.id,
                        groupValue: selectedPreset,
                        title: Text(
                          opt.label,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          opt.description,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedPreset = val);
                          }
                        },
                      ),
                    const Divider(height: 20),
                    const Text(
                      'Custom Instructions (optional)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: customController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText:
                            'e.g., "Include relevant Biblical scripture parallels" or "Focus on career stress and lucid dreaming cues"',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await PrefsService.setDreamLensPreset(selectedPreset);
                  await PrefsService.setDreamCustomInstructions(
                    customController.text,
                  );
                  if (dialogCtx.mounted) {
                    Navigator.pop(dialogCtx, true);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );

  return saved == true;
}

