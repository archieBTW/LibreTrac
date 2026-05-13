import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libretrac/features/cognitive/model/cog_test_kind.dart';
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
    final rawMetrics = prefs.getString('custom_metrics');
    final customMetrics =
        rawMetrics != null ? jsonDecode(rawMetrics) as List : [];

    return {
      'substances':
          (await select(substances).get()).map((e) => e.toJson()).toList(),
      'moodEntries':
          (await select(moodEntries).get()).map((e) => e.toJson()).toList(),
      'sleepEntries':
          (await select(sleepEntries).get()).map((e) => e.toJson()).toList(),
      'reactionResults':
          (await select(reactionResults).get()).map((e) => e.toJson()).toList(),
      'stroopResults':
          (await select(stroopResults).get()).map((e) => e.toJson()).toList(),
      'goNoGoResults':
          (await select(goNoGoResults).get()).map((e) => e.toJson()).toList(),
      'digitSpanResults':
          (await select(digitSpanResults).get())
              .map((e) => e.toJson())
              .toList(),
      'symbolSearchResults':
          (await select(symbolSearchResults).get())
              .map((e) => e.toJson())
              .toList(),

      // ← NEW
      'customMetrics': customMetrics,
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

  MoodEntry moodEntryFromJson(Map<String, dynamic> json) {
    final rawMetrics = json['customMetrics'];
    Map<String, int>? customMetrics;

    if (rawMetrics is String) {
      try {
        final decoded = jsonDecode(rawMetrics) as Map<String, dynamic>;
        customMetrics = decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
      } catch (_) {}
    } else if (rawMetrics is Map<String, dynamic>) {
      customMetrics = rawMetrics.map((k, v) => MapEntry(k, (v as num).toInt()));
    }

    return MoodEntry(
      id: json['id'] as int,
      timestamp:
          json['timestamp'] is int
              ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
              : DateTime.parse(json['timestamp'] as String),
      customMetrics: customMetrics,
      notes: json['notes'] as String?,
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
    final zipData = zipEncoder.encode(archive)!;

    return Uint8List.fromList(zipData);
  }

  Future<List<MoodEntry>> getMoodEntriesBetween(DateTime from, DateTime to) {
    return (select(moodEntries)
      ..where((tbl) => tbl.timestamp.isBetweenValues(from, to))).get();
  }

  /* ── IMPORT (⚠ overwrites everything) ───────────────────────────────── */
  Future<void> importData(Map<String, dynamic> json) async {
    // Load customMetrics if present
    final metricList = json['customMetrics'];
    if (metricList != null && metricList is List) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_metrics', jsonEncode(metricList));
    }

    await transaction(() async {
      // 1. wipe
      await batch(
        (b) =>
            b
              ..deleteAll(substances)
              ..deleteAll(moodEntries)
              ..deleteAll(reactionResults)
              ..deleteAll(stroopResults)
              ..deleteAll(goNoGoResults)
              ..deleteAll(digitSpanResults)
              ..deleteAll(symbolSearchResults)
              ..deleteAll(sleepEntries),
      );

      // 2. helper – takes raw JSON → companion → insert
      Future<void> _addAll<L, D>(
        List<dynamic>? list,
        drift.Insertable<D> Function(Map<String, dynamic>) toCompanion,
        drift.TableInfo<drift.Table, D> table,
      ) async {
        if (list == null) return;
        for (final row in list) {
          await into(table).insert(toCompanion(Map<String, dynamic>.from(row)));
        }
      }

      await _addAll(
        json['substances'],
        (m) => Substance.fromJson(m).toCompanion(true),
        substances,
      );
      await _addAll(
        json['moodEntries'],
        (m) => moodEntryFromJson(m).toCompanion(true),
        moodEntries,
      );

      await _addAll(
        json['reactionResults'],
        (m) => ReactionResult.fromJson(m).toCompanion(true),
        reactionResults,
      );
      await _addAll(
        json['stroopResults'],
        (m) => StroopResult.fromJson(m).toCompanion(true),
        stroopResults,
      );
      await _addAll(
        json['goNoGoResults'],
        (m) => GoNoGoResult.fromJson(m).toCompanion(true),
        goNoGoResults,
      );
      await _addAll(
        json['digitSpanResults'],
        (m) => DigitSpanResult.fromJson(m).toCompanion(true),
        digitSpanResults,
      );
      await _addAll(
        json['symbolSearchResults'],
        (m) => SymbolSearchResult.fromJson(m).toCompanion(true),
        symbolSearchResults,
      );
      await _addAll(
        json['sleepEntries'],
        (m) => SleepEntry.fromJson(m).toCompanion(true),
        sleepEntries,
      );
    });
  }
}

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

  factory CustomMetric.fromJson(Map<String, dynamic> json) =>
      CustomMetric(name: json['name'], color: Color(json['color']));
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

final weeklySleepStatsProvider =
    FutureProvider<({int avgDuration, int entryCount})>((ref) async {
      final db = ref.watch(dbProvider);
      final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
      final entries = await db.sleepEntriesSince(oneWeekAgo);

      if (entries.isEmpty) {
        return (avgDuration: 0, entryCount: 0);
      }

      final totalDuration = entries
          .map((e) => e.hoursSlept)
          .reduce((a, b) => a + b);

      final avg = totalDuration ~/ entries.length;

      return (avgDuration: avg, entryCount: entries.length);
    });
