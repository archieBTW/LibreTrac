import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:libretrac/features/cognitive/model/cog_test_kind.dart';
import 'package:libretrac/features/mood_sleep/model/dream_metadata.dart';
import 'package:libretrac/services/streak_popup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/database/app_database.dart';

/// Single shared DB instance
final dbProvider = Provider<AppDatabase>((ref) => AppDatabase());

/* ─────────────────────────  SUBSTANCES  ───────────────────────── */

final substancesStreamProvider = StreamProvider.autoDispose<List<Substance>>((
  ref,
) {
  final db = ref.watch(dbProvider);
  return db.select(db.substances).watch();
});

class SubstanceRepo {
  SubstanceRepo(this._db);
  final AppDatabase _db;

  Future<int> add(SubstancesCompanion s) => _db.into(_db.substances).insert(s);
  Future<bool> update(Substance s) => _db.update(_db.substances).replace(s);
  Future<int> delete(int id) =>
      (_db.delete(_db.substances)..where((tbl) => tbl.id.equals(id))).go();
  Future<int> stop(int id) {
    return (_db.update(_db.substances)..where(
      (t) => t.id.equals(id),
    )).write(SubstancesCompanion(stoppedAt: drift.Value(DateTime.now())));
  }
}

final substanceRepoProvider = Provider<SubstanceRepo>(
  (ref) => SubstanceRepo(ref.read(dbProvider)),
);

final activeSubstancesStreamProvider =
    StreamProvider.autoDispose<List<Substance>>((ref) {
      final db = ref.watch(dbProvider);
      return (db.select(db.substances)
        ..where((tbl) => tbl.stoppedAt.isNull())).watch();
    });

final pastSubstancesStreamProvider =
    StreamProvider.autoDispose<List<Substance>>((ref) {
      final db = ref.watch(dbProvider);
      return (db.select(db.substances)
        ..where((tbl) => tbl.stoppedAt.isNotNull())).watch();
    });

/* ───────────────────────────  MOODS  ──────────────────────────── */

/// **Assumes** your Drift table is called `moodEntries` and the data
/// class is `MoodEntry`.  If you named them differently, just adjust.
final moodEntriesStreamProvider = StreamProvider.autoDispose<List<MoodEntry>>((
  ref,
) {
  final db = ref.watch(dbProvider);
  return db.select(db.moodEntries).watch();
});

class MoodRepo {
  MoodRepo(this._db);
  final AppDatabase _db;

  Future<int> add(MoodEntriesCompanion m) =>
      _db.into(_db.moodEntries).insert(m);

  Future<bool> update(MoodEntry m) => _db.update(_db.moodEntries).replace(m);

  Future<int> delete(int id) =>
      (_db.delete(_db.moodEntries)..where((t) => t.id.equals(id))).go();

  /// Handy stream (already used by the journal list screen)
  Stream<List<MoodEntry>> watchAll() => _db.select(_db.moodEntries).watch();
}

final moodRepoProvider = Provider<MoodRepo>(
  (ref) => MoodRepo(ref.read(dbProvider)),
);

final journalEntriesStreamProvider =
    StreamProvider.autoDispose<List<MoodEntry>>((ref) {
      final db = ref.watch(dbProvider);

      final query = db.select(db.moodEntries)..orderBy([
        (t) => drift.OrderingTerm(
          expression: t.timestamp,
          mode: drift.OrderingMode.desc,
        ),
      ]);

      return query.watch();
    });

/// Handy JSON backup / restore helpers for every current table.
extension BackupOps on AppDatabase {
  /* ── EXPORT ─────────────────────────────────────────────────────────── */
  /* ── EXPORT ─────────────────────────────────────────────────────────── */
  // Future<Map<String, dynamic>> exportData() async {
  //   return {
  //     'substances':
  //         (await select(substances).get()).map((e) => e.toJson()).toList(),
  //     'moodEntries':
  //         (await select(moodEntries).get()).map((e) => e.toJson()).toList(),
  //     'sleepEntries':
  //         (await select(sleepEntries).get())
  //             .map((e) => e.toJson())
  //             .toList(), // ← NEW
  //     'reactionResults':
  //         (await select(reactionResults).get()).map((e) => e.toJson()).toList(),
  //     'stroopResults':
  //         (await select(stroopResults).get()).map((e) => e.toJson()).toList(),
  //     'nBackResults':
  //         (await select(nBackResults).get()).map((e) => e.toJson()).toList(),
  //     'goNoGoResults':
  //         (await select(goNoGoResults).get()).map((e) => e.toJson()).toList(),
  //     'digitSpanResults':
  //         (await select(digitSpanResults).get())
  //             .map((e) => e.toJson())
  //             .toList(),
  //     'symbolSearchResults':
  //         (await select(symbolSearchResults).get())
  //             .map((e) => e.toJson())
  //             .toList(),
  //   };
  // }

  Future<Map<String, dynamic>> exportData() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Custom metrics
    final rawMetrics = prefs.getString('custom_metrics');
    List customMetrics = [];
    if (rawMetrics != null) {
      try {
        final decoded = jsonDecode(rawMetrics);
        if (decoded is List) customMetrics = decoded;
      } catch (_) {}
    }

    // 2. Medication dose logs: check BOTH getString (used by notifier) and getStringList
    final List doseLogs = [];
    final rawLogsStr = prefs.getString('medication_dose_logs');
    if (rawLogsStr != null && rawLogsStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawLogsStr);
        if (decoded is List) doseLogs.addAll(decoded);
      } catch (_) {}
    }
    if (doseLogs.isEmpty) {
      final rawLogsList = prefs.getStringList('medication_dose_logs');
      if (rawLogsList != null) {
        for (final s in rawLogsList) {
          try {
            doseLogs.add(jsonDecode(s));
          } catch (_) {
            doseLogs.add(s);
          }
        }
      }
    }

    // 3. Medication frequencies and custom order
    final rawDosesPerDay = prefs.getString('medication_doses_per_day');
    dynamic dosesPerDay;
    if (rawDosesPerDay != null) {
      try {
        dosesPerDay = jsonDecode(rawDosesPerDay);
      } catch (_) {}
    }
    final substanceOrder = prefs.getStringList('substanceOrder') ?? [];

    // 4. Dream & AI settings
    final dreamLensPreset = prefs.getString('dream_lens_preset');
    final dreamCustomInstructions =
        prefs.getString('dream_custom_instructions');

    // 5. User Profile
    final userProfile = {
      'username': prefs.getString('user_profile_username') ?? 'LibreUser',
      'picture': prefs.getString('user_profile_picture'),
      'bloodType': prefs.getString('user_profile_blood_type'),
      'birthday': prefs.getString('user_profile_birthday'),
      'height': prefs.getString('user_profile_height'),
      'weight': prefs.getString('user_profile_weight'),
    };

    // 6. Theme, Streaks, Reminders & AI settings
    final settings = {
      'themeMode': prefs.getString('theme_mode'),
      'accentColor': prefs.getString('accent_color'),
      'geminiApiKey': prefs.getString('gemini_api_key'),
      'geminiModel': prefs.getString('gemini_model'),
      'dreamLensPreset': dreamLensPreset,
      'dreamCustomInstructions': dreamCustomInstructions,
      'streakCount': prefs.getInt('streak_count'),
      'lastCheckInDate': prefs.getString('last_check_in_date'),
      'dailyReminders': prefs.getBool('daily_reminders'),
    };

    // 7. Full SharedPreferences snapshot for complete portability
    final allPrefs = await exportSharedPrefs();

    Future<List<Map<String, dynamic>>> safeTable(
      Future<List<drift.DataClass>> Function() query,
    ) async {
      try {
        final rows = await query();
        return rows.map((e) => e.toJson()).toList();
      } catch (e) {
        debugPrint('safeTable export warning: $e');
        return [];
      }
    }

    return {
      'substances': await safeTable(() => select(substances).get()),
      'moodEntries': await safeTable(() => select(moodEntries).get()),
      'sleepEntries': await safeTable(() => select(sleepEntries).get()),
      'reactionResults': await safeTable(() => select(reactionResults).get()),
      'stroopResults': await safeTable(() => select(stroopResults).get()),
      'goNoGoResults': await safeTable(() => select(goNoGoResults).get()),
      'digitSpanResults': await safeTable(() => select(digitSpanResults).get()),
      'symbolSearchResults':
          await safeTable(() => select(symbolSearchResults).get()),
      'customMetrics': customMetrics,
      'medicationDoseLogs': doseLogs,
      'medicationDosesPerDay': dosesPerDay,
      'substanceOrder': substanceOrder,
      'dreamLensPreset': dreamLensPreset,
      'dreamCustomInstructions': dreamCustomInstructions,
      'userProfile': userProfile,
      'settings': settings,
      'prefs': allPrefs,
    };
  }

  Future<Map<String, dynamic>> exportSharedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    final Map<String, dynamic> allPrefs = {};

    for (final key in keys) {
      final value = prefs.get(key);
      allPrefs[key] = value;
    }

    return allPrefs;
  }

  // MoodEntry moodEntryFromJson(Map<String, dynamic> json) {
  //   final rawMetrics = json['customMetrics'];
  //   Map<String, int>? customMetrics;

  //   if (rawMetrics is Map<String, dynamic>) {
  //     customMetrics = rawMetrics.map((k, v) => MapEntry(k, v as int));
  //   }

  //   return MoodEntry(
  //     id: json['id'] as int,
  //     timestamp: DateTime.parse(json['timestamp']),
  //     customMetrics: customMetrics,
  //     notes: json['notes'],
  //   );
  // }

  static DateTime? parseDateTime(dynamic val) {
    if (val == null) return null;
    if (val is DateTime) return val;
    if (val is num) {
      final intVal = val.toInt();
      // If timestamp is in seconds (< 10 billion, which is ~year 2286 in seconds)
      // 10 billion ms is only April 1970. All modern timestamps in ms are ~1.7 trillion.
      if (intVal < 10000000000) {
        return DateTime.fromMillisecondsSinceEpoch(intVal * 1000);
      }
      return DateTime.fromMillisecondsSinceEpoch(intVal);
    }
    if (val is String) {
      final trimmed = val.trim();
      if (trimmed.isEmpty) return null;
      final numVal = num.tryParse(trimmed);
      if (numVal != null) {
        return parseDateTime(numVal);
      }
      final dt = DateTime.tryParse(trimmed);
      if (dt != null) return dt;

      try {
        return DateFormat('yyyy-MM-dd HH:mm').parse(trimmed);
      } catch (_) {}
      try {
        return DateFormat('yyyy-MM-dd').parse(trimmed);
      } catch (_) {}
    }
    return null;
  }

  static double parseDouble(dynamic val, [double defaultVal = 0.0]) {
    if (val == null) return defaultVal;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? defaultVal;
    return defaultVal;
  }

  static int parseInt(dynamic val, [int defaultVal = 0]) {
    if (val == null) return defaultVal;
    if (val is num) return val.toInt();
    if (val is String) {
      return int.tryParse(val) ??
          (double.tryParse(val)?.toInt() ?? defaultVal);
    }
    return defaultVal;
  }

  MoodEntry moodEntryFromJson(Map<String, dynamic> json) {
    final rawMetrics = json['customMetrics'] ?? json['custom_metrics'];
    Map<String, int>? customMetrics;

    if (rawMetrics is String) {
      try {
        final decoded = jsonDecode(rawMetrics);
        if (decoded is Map) {
          customMetrics = decoded.map(
            (k, v) => MapEntry(k.toString(), parseInt(v)),
          );
        }
      } catch (_) {}
    } else if (rawMetrics is Map) {
      customMetrics = rawMetrics.map(
        (k, v) => MapEntry(k.toString(), parseInt(v)),
      );
    }

    final id = parseInt(json['id']);
    final ts = parseDateTime(json['timestamp']) ?? DateTime.now();

    return MoodEntry(
      id: id,
      timestamp: ts,
      customMetrics: customMetrics,
      notes: json['notes']?.toString(),
    );
  }

  Future<Uint8List> exportAllToZip(AppDatabase db) async {
    final dataJson = await db.exportData();
    final prefsJson = await db.exportSharedPrefs();

    final dataBytes = utf8.encode(jsonEncode(dataJson));
    final prefsBytes = utf8.encode(jsonEncode(prefsJson));

    final archive =
        Archive()
          ..addFile(ArchiveFile('data.json', dataBytes.length, dataBytes))
          ..addFile(ArchiveFile('prefs.json', prefsBytes.length, prefsBytes));

    final zipEncoder = ZipEncoder();
    final zipData = zipEncoder.encode(archive);

    return Uint8List.fromList(zipData);
  }

  Future<List<MoodEntry>> getMoodEntriesBetween(DateTime from, DateTime to) {
    return (select(moodEntries)
      ..where((tbl) => tbl.timestamp.isBetweenValues(from, to))).get();
  }

  /* ── IMPORT (Resilient, Safe, Non-Destructive on error) ─────────────── */
  Future<void> importData(Map<String, dynamic> json) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Load customMetrics if present (handles both List and JSON string)
    final metricList = json['customMetrics'] ?? json['custom_metrics'];
    if (metricList is List) {
      await prefs.setString('custom_metrics', jsonEncode(metricList));
    } else if (metricList is String && metricList.isNotEmpty) {
      await prefs.setString('custom_metrics', metricList);
    }

    // 2. Load medication dose logs: write BOTH setString (expected by notifier) AND setStringList
    final rawDoseLogs =
        json['medicationDoseLogs'] ?? json['medication_dose_logs'];
    if (rawDoseLogs != null) {
      List<dynamic> logsList = [];
      if (rawDoseLogs is String && rawDoseLogs.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawDoseLogs);
          if (decoded is List) logsList = decoded;
        } catch (_) {}
      } else if (rawDoseLogs is List) {
        logsList = rawDoseLogs;
      }

      final stringList = <String>[];
      final objectList = <dynamic>[];
      for (final item in logsList) {
        if (item is String) {
          stringList.add(item);
          try {
            objectList.add(jsonDecode(item));
          } catch (_) {
            objectList.add(item);
          }
        } else {
          stringList.add(jsonEncode(item));
          objectList.add(item);
        }
      }
      await prefs.setString('medication_dose_logs', jsonEncode(objectList));
      await prefs.setStringList('medication_dose_logs', stringList);
    }

    // 3. Medication doses per day
    final dosesPerDay =
        json['medicationDosesPerDay'] ?? json['medication_doses_per_day'];
    if (dosesPerDay != null) {
      await prefs.setString(
        'medication_doses_per_day',
        dosesPerDay is String ? dosesPerDay : jsonEncode(dosesPerDay),
      );
    }

    // 4. Custom substance order
    final substanceOrder = json['substanceOrder'] ?? json['substance_order'];
    if (substanceOrder is List) {
      await prefs.setStringList(
        'substanceOrder',
        substanceOrder.map((e) => e.toString()).toList(),
      );
    }

    // 5. User Profile
    final profile = json['userProfile'] ?? json['user_profile'];
    if (profile is Map) {
      final username = profile['username'];
      if (username != null) {
        await prefs.setString('user_profile_username', username.toString());
      }
      final pic = profile['picture'] ??
          profile['profilePicture'] ??
          profile['profile_picture'];
      if (pic != null) {
        await prefs.setString('user_profile_picture', pic.toString());
      }
      final blood = profile['bloodType'] ?? profile['blood_type'];
      if (blood != null) {
        await prefs.setString('user_profile_blood_type', blood.toString());
      }
      final bday = profile['birthday'];
      if (bday != null) {
        await prefs.setString('user_profile_birthday', bday.toString());
      }
      final height = profile['height'];
      if (height != null) {
        await prefs.setString('user_profile_height', height.toString());
      }
      final weight = profile['weight'];
      if (weight != null) {
        await prefs.setString('user_profile_weight', weight.toString());
      }
    }

    // 6. Settings, Theme, AI & Streaks
    final settings = json['settings'];
    if (settings is Map) {
      final tm = settings['themeMode'] ?? settings['theme_mode'];
      if (tm != null) {
        await prefs.setString('theme_mode', tm.toString());
      }
      final ac = settings['accentColor'] ?? settings['accent_color'];
      if (ac != null) {
        await prefs.setString('accent_color', ac.toString());
      }
      final key = settings['geminiApiKey'] ?? settings['gemini_api_key'];
      if (key != null) {
        await prefs.setString('gemini_api_key', key.toString());
      }
      final model = settings['geminiModel'] ?? settings['gemini_model'];
      if (model != null) {
        await prefs.setString('gemini_model', model.toString());
      }
      final preset =
          settings['dreamLensPreset'] ?? settings['dream_lens_preset'];
      if (preset != null) {
        await prefs.setString('dream_lens_preset', preset.toString());
      }
      final instr = settings['dreamCustomInstructions'] ??
          settings['dream_custom_instructions'];
      if (instr != null) {
        await prefs.setString('dream_custom_instructions', instr.toString());
      }
      final streak = settings['streakCount'] ?? settings['streak_count'];
      if (streak is int) {
        await prefs.setInt('streak_count', streak);
      } else if (streak != null) {
        final parsed = int.tryParse('$streak');
        if (parsed != null) await prefs.setInt('streak_count', parsed);
      }
      final lastCheckIn =
          settings['lastCheckInDate'] ?? settings['last_check_in_date'];
      if (lastCheckIn != null) {
        await prefs.setString('last_check_in_date', lastCheckIn.toString());
      }
      final reminders =
          settings['dailyReminders'] ?? settings['daily_reminders'];
      if (reminders is bool) {
        await prefs.setBool('daily_reminders', reminders);
      } else if (reminders != null) {
        await prefs.setBool('daily_reminders', reminders.toString() == 'true');
      }
    }

    // 7. Dream Lens fallback
    final dreamLens = json['dreamLensPreset'] ?? json['dream_lens_preset'];
    if (dreamLens is String && dreamLens.isNotEmpty) {
      await prefs.setString('dream_lens_preset', dreamLens);
    }
    final dreamInstr =
        json['dreamCustomInstructions'] ?? json['dream_custom_instructions'];
    if (dreamInstr is String && dreamInstr.isNotEmpty) {
      await prefs.setString('dream_custom_instructions', dreamInstr);
    }

    // 8. Restore raw SharedPreferences if present
    final rawPrefs = json['prefs'] ?? json['localStorage'];
    if (rawPrefs is Map) {
      for (final entry in rawPrefs.entries) {
        var k = entry.key.toString();
        if (k.startsWith('flutter.')) {
          k = k.substring('flutter.'.length);
        }
        final v = entry.value;
        if (v is bool) {
          await prefs.setBool(k, v);
        } else if (v is int) {
          await prefs.setInt(k, v);
        } else if (v is double) {
          await prefs.setDouble(k, v);
        } else if (v is String) {
          await prefs.setString(k, v);
        } else if (v is List && v.every((e) => e is String)) {
          await prefs.setStringList(k, List<String>.from(v));
        } else if (v is Map || v is List) {
          await prefs.setString(k, jsonEncode(v));
        }
      }
    }

    // Helper: Find list from map using multiple key variants
    List<dynamic>? findList(List<String> keys) {
      for (final k in keys) {
        if (json.containsKey(k) && json[k] is List) {
          return json[k] as List<dynamic>;
        }
      }
      return null;
    }

    // 3. Pre-parse all table records safely outside of the transaction
    final rawSubstances = findList(['substances']);
    final List<SubstancesCompanion> parsedSubstances = [];
    if (rawSubstances != null) {
      for (final r in rawSubstances) {
        if (r is Map) {
          final m = Map<String, dynamic>.from(r);
          final idVal = m['id'] != null ? parseInt(m['id']) : null;
          parsedSubstances.add(
            SubstancesCompanion(
              id: idVal != null ? drift.Value(idVal) : const drift.Value.absent(),
              name: drift.Value((m['name'] ?? 'Unnamed').toString()),
              dosage: drift.Value(m['dosage']?.toString()),
              notes: drift.Value(m['notes']?.toString()),
              addedAt: drift.Value(
                parseDateTime(m['addedAt'] ?? m['added_at']) ?? DateTime.now(),
              ),
              stoppedAt: drift.Value(
                parseDateTime(m['stoppedAt'] ?? m['stopped_at']),
              ),
            ),
          );
        }
      }
    }

    final rawMoods = findList(['moodEntries', 'mood_entries']);
    final List<MoodEntriesCompanion> parsedMoods = [];
    if (rawMoods != null) {
      for (final r in rawMoods) {
        if (r is Map) {
          final m = Map<String, dynamic>.from(r);
          final idVal = m['id'] != null ? parseInt(m['id']) : null;
          final rawMetrics = m['customMetrics'] ?? m['custom_metrics'];
          Map<String, int>? metrics;
          if (rawMetrics is String) {
            try {
              final d = jsonDecode(rawMetrics);
              if (d is Map) {
                metrics = d.map((k, v) => MapEntry(k.toString(), parseInt(v)));
              }
            } catch (_) {}
          } else if (rawMetrics is Map) {
            metrics = rawMetrics.map(
              (k, v) => MapEntry(k.toString(), parseInt(v)),
            );
          }

          parsedMoods.add(
            MoodEntriesCompanion(
              id: idVal != null ? drift.Value(idVal) : const drift.Value.absent(),
              timestamp: drift.Value(
                parseDateTime(m['timestamp']) ?? DateTime.now(),
              ),
              customMetrics: drift.Value(metrics),
              notes: drift.Value(m['notes']?.toString()),
            ),
          );
        }
      }
    }

    final rawSleep = findList(['sleepEntries', 'sleep_entries']);
    final List<SleepEntriesCompanion> parsedSleep = [];
    if (rawSleep != null) {
      for (final r in rawSleep) {
        if (r is Map) {
          final m = Map<String, dynamic>.from(r);
          final idVal = m['id'] != null ? parseInt(m['id']) : null;
          final date = parseDateTime(m['date']) ?? DateTime.now();
          parsedSleep.add(
            SleepEntriesCompanion(
              id: idVal != null ? drift.Value(idVal) : const drift.Value.absent(),
              date: drift.Value(date),
              hoursSlept: drift.Value(
                parseDouble(m['hoursSlept'] ?? m['hours_slept'], 0.0),
              ),
              dreamJournal: drift.Value(
                (m['dreamJournal'] ?? m['dream_journal'])?.toString(),
              ),
              quality: drift.Value(parseInt(m['quality'], 3)),
              createdAt: drift.Value(
                parseDateTime(m['createdAt'] ?? m['created_at']) ?? date,
              ),
            ),
          );
        }
      }
    }

    final rawReactions = findList(['reactionResults', 'reaction_results']);
    final List<ReactionResultsCompanion> parsedReactions = [];
    if (rawReactions != null) {
      for (final r in rawReactions) {
        if (r is Map) {
          final m = Map<String, dynamic>.from(r);
          final idVal = m['id'] != null ? parseInt(m['id']) : null;
          parsedReactions.add(
            ReactionResultsCompanion(
              id: idVal != null ? drift.Value(idVal) : const drift.Value.absent(),
              timestamp: drift.Value(
                parseDateTime(m['timestamp']) ?? DateTime.now(),
              ),
              averageTime: drift.Value(
                parseDouble(m['averageTime'] ?? m['average_time']),
              ),
              fastest: drift.Value(parseDouble(m['fastest'])),
              slowest: drift.Value(parseDouble(m['slowest'])),
            ),
          );
        }
      }
    }

    final rawStroop = findList(['stroopResults', 'stroop_results']);
    final List<StroopResultsCompanion> parsedStroop = [];
    if (rawStroop != null) {
      for (final r in rawStroop) {
        if (r is Map) {
          final m = Map<String, dynamic>.from(r);
          final idVal = m['id'] != null ? parseInt(m['id']) : null;
          parsedStroop.add(
            StroopResultsCompanion(
              id: idVal != null ? drift.Value(idVal) : const drift.Value.absent(),
              timestamp: drift.Value(
                parseDateTime(m['timestamp']) ?? DateTime.now(),
              ),
              congruentMs: drift.Value(
                parseDouble(m['congruentMs'] ?? m['congruent_ms']),
              ),
              incongruentMs: drift.Value(
                parseDouble(m['incongruentMs'] ?? m['incongruent_ms']),
              ),
              deltaMs: drift.Value(
                parseDouble(m['deltaMs'] ?? m['delta_ms']),
              ),
            ),
          );
        }
      }
    }

    final rawGoNoGo = findList(['goNoGoResults', 'go_no_go_results']);
    final List<GoNoGoResultsCompanion> parsedGoNoGo = [];
    if (rawGoNoGo != null) {
      for (final r in rawGoNoGo) {
        if (r is Map) {
          final m = Map<String, dynamic>.from(r);
          final idVal = m['id'] != null ? parseInt(m['id']) : null;
          parsedGoNoGo.add(
            GoNoGoResultsCompanion(
              id: idVal != null ? drift.Value(idVal) : const drift.Value.absent(),
              timestamp: drift.Value(
                parseDateTime(m['timestamp']) ?? DateTime.now(),
              ),
              meanRt: drift.Value(
                parseDouble(m['meanRt'] ?? m['mean_rt']),
              ),
              commissionErrors: drift.Value(
                parseInt(m['commissionErrors'] ?? m['commission_errors']),
              ),
              omissionErrors: drift.Value(
                parseInt(m['omissionErrors'] ?? m['omission_errors']),
              ),
            ),
          );
        }
      }
    }

    final rawDigitSpan = findList(['digitSpanResults', 'digit_span_results']);
    final List<DigitSpanResultsCompanion> parsedDigitSpan = [];
    if (rawDigitSpan != null) {
      for (final r in rawDigitSpan) {
        if (r is Map) {
          final m = Map<String, dynamic>.from(r);
          final idVal = m['id'] != null ? parseInt(m['id']) : null;
          parsedDigitSpan.add(
            DigitSpanResultsCompanion(
              id: idVal != null ? drift.Value(idVal) : const drift.Value.absent(),
              timestamp: drift.Value(
                parseDateTime(m['timestamp']) ?? DateTime.now(),
              ),
              bestSpan: drift.Value(
                parseInt(m['bestSpan'] ?? m['best_span']),
              ),
            ),
          );
        }
      }
    }

    final rawSymbols = findList(['symbolSearchResults', 'symbol_search_results']);
    final List<SymbolSearchResultsCompanion> parsedSymbols = [];
    if (rawSymbols != null) {
      for (final r in rawSymbols) {
        if (r is Map) {
          final m = Map<String, dynamic>.from(r);
          final idVal = m['id'] != null ? parseInt(m['id']) : null;
          parsedSymbols.add(
            SymbolSearchResultsCompanion(
              id: idVal != null ? drift.Value(idVal) : const drift.Value.absent(),
              timestamp: drift.Value(
                parseDateTime(m['timestamp']) ?? DateTime.now(),
              ),
              hits: drift.Value(parseInt(m['hits'])),
              total: drift.Value(parseInt(m['total'])),
              meanRt: drift.Value(
                parseDouble(m['meanRt'] ?? m['mean_rt']),
              ),
            ),
          );
        }
      }
    }

    // 4. Safely insert parsed records table-by-table
    Future<void> replaceTable<D>(
      drift.TableInfo<drift.Table, D> table,
      List<drift.Insertable<D>> items,
    ) async {
      if (items.isEmpty) return;
      try {
        await delete(table).go();
        for (final item in items) {
          try {
            await into(table)
                .insert(item, mode: drift.InsertMode.insertOrReplace);
          } catch (e) {
            debugPrint('Insert warning on ${table.actualTableName}: $e');
          }
        }
      } catch (e) {
        debugPrint('Replace table warning on ${table.actualTableName}: $e');
      }
    }

    await replaceTable(substances, parsedSubstances);
    await replaceTable(moodEntries, parsedMoods);
    await replaceTable(sleepEntries, parsedSleep);
    await replaceTable(reactionResults, parsedReactions);
    await replaceTable(stroopResults, parsedStroop);
    await replaceTable(goNoGoResults, parsedGoNoGo);
    await replaceTable(digitSpanResults, parsedDigitSpan);
    await replaceTable(symbolSearchResults, parsedSymbols);
  }
}

// Top-level resilient parsers for database, backup, and settings operations
DateTime? parseDateTime(dynamic val) => BackupOps.parseDateTime(val);
double parseDouble(dynamic val, [double defaultVal = 0.0]) =>
    BackupOps.parseDouble(val, defaultVal);
int parseInt(dynamic val, [int defaultVal = 0]) =>
    BackupOps.parseInt(val, defaultVal);

// NEW: enum + helper
enum MoodWindow { week, month, threeMonths, sixMonths }

extension WindowDays on MoodWindow {
  int get days => switch (this) {
    MoodWindow.week => 7,
    MoodWindow.month => 30,
    MoodWindow.threeMonths => 90,
    MoodWindow.sixMonths => 180,
  };
}

extension MoodWindowExt on MoodWindow {
  DateTime get since {
    final now = DateTime.now();
    switch (this) {
      case MoodWindow.week:
        return now.subtract(const Duration(days: 7));
      case MoodWindow.month:
        return DateTime(now.year, now.month - 1, now.day);
      case MoodWindow.threeMonths:
        return DateTime(now.year, now.month - 3, now.day);
      case MoodWindow.sixMonths:
        return DateTime(now.year, now.month - 6, now.day);
    }
  }
}

/// Currently‐selected window (defaults to the old “7-day” view).
final moodWindowProvider = StateProvider<MoodWindow>((_) => MoodWindow.week);

/// Live list that honours the selected window.
// final filteredMoodEntriesProvider = StreamProvider.autoDispose<List<MoodEntry>>(
//   (ref) {
//     final db = ref.watch(dbProvider);
//     final window = ref.watch(moodWindowProvider);
//     final cutOff = DateTime.now().subtract(Duration(days: window.days));

//     final query =
//         db.select(db.moodEntries)
//           ..where((t) => t.timestamp.isBiggerOrEqualValue(cutOff))
//           ..orderBy([
//             (t) =>
//                 OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
//           ]);

//     return query.watch();
//   },
// );

final showAllCheckInsProvider = StateProvider<bool>((ref) => false);

final filteredMoodEntriesProvider = StreamProvider.autoDispose.family<
  List<MoodEntry>,
  ({MoodWindow window, bool showAllCheckIns})
>((ref, params) {
  final db = ref.watch(dbProvider);
  final cutOff = DateTime.now().subtract(Duration(days: params.window.days));

  final query =
      db.select(db.moodEntries)
        ..where((t) => t.timestamp.isBiggerOrEqualValue(cutOff))
        ..orderBy([
          (t) => drift.OrderingTerm(
            expression: t.timestamp,
            mode: drift.OrderingMode.desc,
          ),
        ]);

  return query.watch().map((entries) {
    if (params.showAllCheckIns) return entries;

    // Group by date (yyyy-MM-dd) and take the latest for each day
    final Map<String, MoodEntry> latestPerDay = {};

    for (final entry in entries) {
      final dayKey =
          DateTime(
            entry.timestamp.year,
            entry.timestamp.month,
            entry.timestamp.day,
          ).toIso8601String();
      latestPerDay[dayKey] =
          latestPerDay[dayKey] == null ||
                  entry.timestamp.isAfter(latestPerDay[dayKey]!.timestamp)
              ? entry
              : latestPerDay[dayKey]!;
    }

    final result =
        latestPerDay.values.toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return result;
  });
});

/* ─────────────────────  TREND-QUERY HELPERS  ──────────────────────
   One-shot queries that the HomeScreen uses to build the payload
   for the Gemini AI trend-analysis call.
─────────────────────────────────────────────────────────────────── */

/// Extension on the generated `AppDatabase` that exposes three concise
/// helper methods. No new tables are required.
extension TrendQueries on AppDatabase {
  /* Mood entries on or after [since] (inclusive). */
  Future<List<MoodEntry>> moodEntriesSince(DateTime since) {
    return (select(moodEntries)
      ..where((t) => t.timestamp.isBiggerOrEqualValue(since))).get();
  }

  /* Cognitive-test results (reaction-time) on or after [since].  
     🔺 Adjust the column name (`timestamp`) if yours is different. */
  Future<List<ReactionResult>> reactionResultsSince(DateTime since) {
    return (select(reactionResults)
      ..where((t) => t.timestamp.isBiggerOrEqualValue(since))).get();
  }

  Future<List<SleepEntry>> sleepEntriesSince(DateTime since) {
    return (select(sleepEntries)
      ..where((t) => t.date.isBiggerOrEqualValue(since))).get();
  }

  /* Substances that were “active” at any point in the window that
     starts at [since] and ends **now**.
       • startedAt ≤ now
       • stoppedAt is NULL  OR  stoppedAt ≥ since                       */
  Future<List<Substance>> substancesActiveSince(DateTime since) {
    final now = DateTime.now();
    return (select(substances)..where(
      (t) =>
          t.addedAt.isSmallerOrEqualValue(now) &
          (t.stoppedAt.isNull() | t.stoppedAt.isBiggerOrEqualValue(since)),
    )).get();
  }

  Future<List<StroopResult>> stroopResultsSince(DateTime since) {
    return (select(stroopResults)
      ..where((t) => t.timestamp.isBiggerOrEqualValue(since))).get();
  }

  Future<List<GoNoGoResult>> goNoGoResultsSince(DateTime since) {
    return (select(goNoGoResults)
      ..where((t) => t.timestamp.isBiggerOrEqualValue(since))).get();
  }

  Future<List<DigitSpanResult>> digitSpanResultsSince(DateTime since) {
    return (select(digitSpanResults)
      ..where((t) => t.timestamp.isBiggerOrEqualValue(since))).get();
  }

  Future<List<SymbolSearchResult>> symbolSearchResultsSince(DateTime since) {
    return (select(symbolSearchResults)
      ..where((t) => t.timestamp.isBiggerOrEqualValue(since))).get();
  }
}

/* ─────────── OPTIONAL RIVERPOD HELPERS (convenience) ──────────── */
/* If you prefer plain `db.*Since()` calls in the UI, delete these. */

final moodsSinceProvider = FutureProvider.autoDispose
    .family<List<MoodEntry>, DateTime>(
      (ref, since) => ref.watch(dbProvider).moodEntriesSince(since),
    );

final reactionResultsSinceProvider = FutureProvider.autoDispose
    .family<List<ReactionResult>, DateTime>(
      (ref, since) => ref.watch(dbProvider).reactionResultsSince(since),
    );

final substancesActiveSinceProvider = FutureProvider.autoDispose
    .family<List<Substance>, DateTime>(
      (ref, since) => ref.watch(dbProvider).substancesActiveSince(since),
    );

final sleepStreamProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(dbProvider).watchAllSleep(),
);

/* ─────────────────────  COGNITIVE STREAMS  ──────────────────────── */

final reactionResultsStreamProvider = StreamProvider.autoDispose<List<ReactionResult>>((ref) {
  final db = ref.watch(dbProvider);
  return db.select(db.reactionResults).watch();
});

final stroopResultsStreamProvider = StreamProvider.autoDispose<List<StroopResult>>((ref) {
  final db = ref.watch(dbProvider);
  return db.select(db.stroopResults).watch();
});

final goNoGoResultsStreamProvider = StreamProvider.autoDispose<List<GoNoGoResult>>((ref) {
  final db = ref.watch(dbProvider);
  return db.select(db.goNoGoResults).watch();
});

final digitSpanResultsStreamProvider = StreamProvider.autoDispose<List<DigitSpanResult>>((ref) {
  final db = ref.watch(dbProvider);
  return db.select(db.digitSpanResults).watch();
});

final symbolSearchResultsStreamProvider = StreamProvider.autoDispose<List<SymbolSearchResult>>((ref) {
  final db = ref.watch(dbProvider);
  return db.select(db.symbolSearchResults).watch();
});

enum JournalFilter { all, notesOnly }

final journalFilterProvider = StateProvider<JournalFilter>((ref) {
  return JournalFilter.all;
});

class CustomMetric {
  final String name;
  final Color color;

  CustomMetric({required this.name, required this.color});

  Map<String, dynamic> toJson() => {'name': name, 'color': color.value};

  factory CustomMetric.fromJson(Map<String, dynamic> json) {
    Color parsedColor = const Color(0xFF2196F3);
    final rawColor = json['color'];
    if (rawColor is num) {
      parsedColor = Color(rawColor.toInt());
    } else if (rawColor is String) {
      final s = rawColor.replaceAll('#', '');
      final val = int.tryParse(s, radix: s.length > 6 ? 16 : 10) ??
          int.tryParse(s, radix: 16);
      if (val != null) parsedColor = Color(val);
    }
    return CustomMetric(
      name: (json['name'] ?? 'Metric').toString(),
      color: parsedColor,
    );
  }
}

final customMetricsProvider =
    StateNotifierProvider<CustomMetricsNotifier, List<CustomMetric>>((ref) {
      return CustomMetricsNotifier(); // implement loading/saving here
    });

class CustomMetricsNotifier extends StateNotifier<List<CustomMetric>> {
  static const _prefsKey = 'custom_metrics';

  CustomMetricsNotifier() : super([]) {
    _loadMetrics();
  }

  Future<void> reload() => _loadMetrics();

  Future<void> _loadMetrics() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      final List decoded = jsonDecode(raw);
      state =
          decoded
              .map((e) => CustomMetric.fromJson(e as Map<String, dynamic>))
              .toList();
    } else {
      // Optional: Load defaults if first launch
      state = [
        CustomMetric(name: 'Energy', color: Colors.teal),
        CustomMetric(name: 'Happiness', color: Colors.orange),
        CustomMetric(name: 'Focus', color: Colors.blue),
      ];
      _save();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(state.map((e) => e.toJson()).toList());
    await prefs.setString(_prefsKey, encoded);
  }

  void addMetric(CustomMetric metric) {
    if (state.length >= 6) return; // max 6
    state = [...state, metric];
    _save();
  }

  void updateMetric(int index, CustomMetric updated) {
    final copy = [...state];
    copy[index] = updated;
    state = copy;
    _save();
  }

  void deleteMetric(int index) {
    final copy = [...state]..removeAt(index);
    state = copy;
    _save();
  }
}

// final userProfileProvider =
//     StateNotifierProvider<UserProfileNotifier, UserProfile>(
//       (ref) => UserProfileNotifier(),
//     );

// class UserProfile {
//   final String username;
//   final String? profilePicturePath;

//   UserProfile({required this.username, this.profilePicturePath});
// }

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>(
      (ref) => UserProfileNotifier(),
    );

class UserProfile {
  final String username;
  final String? profilePicturePath;
  final String? bloodType;
  final String? birthday;
  final String? height;
  final String? weight;

  UserProfile({
    required this.username,
    this.profilePicturePath,
    this.bloodType,
    this.birthday,
    this.height,
    this.weight,
  });
}

class UserProfileNotifier extends StateNotifier<UserProfile> {
  static const _usernameKey = 'user_profile_username';
  static const _pictureKey = 'user_profile_picture';
  static const _bloodTypeKey = 'user_profile_blood_type';
  static const _birthdayKey = 'user_profile_birthday';
  static const _heightKey = 'user_profile_height';
  static const _weightKey = 'user_profile_weight';

  UserProfileNotifier() : super(UserProfile(username: 'LibreUser')) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_usernameKey) ?? 'LibreUser';
    final pic = prefs.getString(_pictureKey);
    final bloodType = prefs.getString(_bloodTypeKey);
    final birthday = prefs.getString(_birthdayKey);
    final height = prefs.getString(_heightKey);
    final weight = prefs.getString(_weightKey);
    state = UserProfile(
      username: username,
      profilePicturePath: pic,
      bloodType: bloodType,
      birthday: birthday,
      height: height,
      weight: weight,
    );
  }

  Future<void> reload() async {
    await _load();
  }

  Future<void> setUsername(String val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, val);
    state = state.copyWith(username: val);
  }

  Future<void> setPicturePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pictureKey, path);
    state = state.copyWith(profilePicturePath: path);
  }

  Future<void> setBloodType(String val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bloodTypeKey, val);
    state = state.copyWith(bloodType: val);
  }

  Future<void> setBirthday(String val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_birthdayKey, val);
    state = state.copyWith(birthday: val);
  }

  Future<void> setHeight(String val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_heightKey, val);
    state = state.copyWith(height: val);
  }

  Future<void> setWeight(String val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_weightKey, val);
    state = state.copyWith(weight: val);
  }
}

extension on UserProfile {
  UserProfile copyWith({
    String? username,
    String? profilePicturePath,
    String? bloodType,
    String? birthday,
    String? height,
    String? weight,
  }) {
    return UserProfile(
      username: username ?? this.username,
      profilePicturePath: profilePicturePath ?? this.profilePicturePath,
      bloodType: bloodType ?? this.bloodType,
      birthday: birthday ?? this.birthday,
      height: height ?? this.height,
      weight: weight ?? this.weight,
    );
  }
}

final streakCountProvider = FutureProvider<int>((ref) async {
  return await StreakService.updateStreak();
});

// class UserProfileNotifier extends StateNotifier<UserProfile> {
//   static const _usernameKey = 'user_profile_username';
//   static const _pictureKey = 'user_profile_picture';

//   UserProfileNotifier() : super(UserProfile(username: 'LibreUser')) {
//     _load();
//   }

//   Future<void> _load() async {
//     final prefs = await SharedPreferences.getInstance();
//     final username = prefs.getString(_usernameKey) ?? 'LibreUser';
//     final pic = prefs.getString(_pictureKey);
//     state = UserProfile(username: username, profilePicturePath: pic);
//   }

//   Future<void> setUsername(String newName) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(_usernameKey, newName);
//     state = UserProfile(
//       username: newName,
//       profilePicturePath: state.profilePicturePath,
//     );
//   }

//   Future<void> setPicturePath(String path) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(_pictureKey, path);
//     state = UserProfile(username: state.username, profilePicturePath: path);
//   }
// }

final weeklyMoodAverageProvider = FutureProvider<double>((ref) async {
  final db = ref.watch(dbProvider);
  final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
  final entries = await db.moodEntriesSince(oneWeekAgo);

  int totalScore = 0;
  int metricCount = 0;

  for (final entry in entries) {
    final metrics = entry.customMetrics;
    if (metrics != null) {
      for (final score in metrics.values) {
        totalScore += score;
        metricCount++;
      }
    }
  }

  if (metricCount == 0) return 0;

  return totalScore / metricCount;
});

final weeklyMoodMetricAveragesProvider = FutureProvider<Map<String, double>>((
  ref,
) async {
  final db = ref.watch(dbProvider);
  final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
  final entries = await db.moodEntriesSince(oneWeekAgo);

  final Map<String, List<int>> metricValues = {};

  for (final entry in entries) {
    final metrics = entry.customMetrics;
    if (metrics != null) {
      for (final entry in metrics.entries) {
        metricValues.putIfAbsent(entry.key, () => []).add(entry.value);
      }
    }
  }

  final Map<String, double> averages = {};
  metricValues.forEach((key, values) {
    final sum = values.reduce((a, b) => a + b);
    averages[key] = sum / values.length;
  });

  return averages;
});

final cognitiveTopScoresProvider = FutureProvider<Map<CogTestKind, String>>((
  ref,
) async {
  final db = ref.watch(dbProvider);
  final results = <CogTestKind, String>{};

  for (final kind in CogTestKind.values) {
    final table = kind.table(db);
    final rows = await db.select(table as dynamic).get();

    if (rows.isEmpty) continue;

    rows.sort((a, b) {
      final aScore = kind.y(a);
      final bScore = kind.y(b);
      return kind.lowerIsBetter
          ? aScore.compareTo(bScore)
          : bScore.compareTo(aScore);
    });

    final best = rows.first;
    final d = best.timestamp;
    final dateStr = '${d.month}/${d.day}';

    String scoreStr;

    switch (kind) {
      case CogTestKind.reaction:
        scoreStr = '${best.averageTime.toStringAsFixed(0)}ms avg';
        break;
      case CogTestKind.stroop:
        scoreStr =
            'Δ${best.deltaMs.toStringAsFixed(0)}ms '
            '(In: ${best.incongruentMs.toStringAsFixed(0)}ms, '
            'Con: ${best.congruentMs.toStringAsFixed(0)}ms)';
        break;
      case CogTestKind.goNoGo:
        scoreStr =
            '${best.meanRt.toStringAsFixed(0)}ms avg, '
            '${best.omissionErrors} omissions, '
            '${best.commissionErrors} commissions';
        break;
      case CogTestKind.digitSpan:
        scoreStr = 'Span: ${best.bestSpan}';
        break;
      case CogTestKind.symbolSearch:
        scoreStr =
            '${best.hits}/${best.total}, '
            '${best.meanRt.toStringAsFixed(0)}ms avg';
        break;
    }

    results[kind] = '$scoreStr on $dateStr';
  }

  return results;
});

final weeklySleepStatsProvider = FutureProvider<
  ({
    double avgDuration,
    double avgQuality,
    int entryCount,
    int dreamCount,
    List<String> topTags,
  })
>((ref) async {
  ref.watch(sleepStreamProvider);
  final db = ref.watch(dbProvider);
  final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
  final entries = await db.sleepEntriesSince(oneWeekAgo);

  final sleepEntries = entries.where((e) => e.hoursSlept > 0).toList();

  int dreamCount = 0;
  final tagFreq = <String, int>{};
  for (final e in entries) {
    if (e.hasDream) {
      dreamCount++;
      for (final t in e.dreamTags) {
        tagFreq[t] = (tagFreq[t] ?? 0) + 1;
      }
    }
  }

  final sortedTags =
      tagFreq.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

  if (sleepEntries.isEmpty) {
    return (
      avgDuration: 0.0,
      avgQuality: 0.0,
      entryCount: 0,
      dreamCount: dreamCount,
      topTags: sortedTags.take(3).map((e) => e.key).toList(),
    );
  }

  final totalDuration = sleepEntries
      .map((e) => e.hoursSlept)
      .reduce((a, b) => a + b);
  final totalQuality = sleepEntries
      .map((e) => e.quality)
      .reduce((a, b) => a + b);

  return (
    avgDuration: totalDuration / sleepEntries.length,
    avgQuality: totalQuality / sleepEntries.length,
    entryCount: sleepEntries.length,
    dreamCount: dreamCount,
    topTags: sortedTags.take(3).map((e) => e.key).toList(),
  );
});
