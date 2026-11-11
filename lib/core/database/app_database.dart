import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:libretrac/core/database/mood_entries.dart';
import 'package:libretrac/core/database/reaction_results.dart';
import 'package:libretrac/core/database/sleep_entries.dart';
import 'package:libretrac/core/database/substances.dart';
import 'package:libretrac/core/database/type_converters.dart';
part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Substances,
    MoodEntries,
    ReactionResults,
    SleepEntries,
    StroopResults,
    GoNoGoResults,
    DigitSpanResults,
    SymbolSearchResults,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  static final AppDatabase _instance = AppDatabase._();

  factory AppDatabase() => _instance;

  @visibleForTesting
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2; // ← bumped

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => m.createAllTables(),
    onUpgrade: (m, from, to) async {
      if (from == 1) {
        // coming from the old build
        // await m.createTable(substances);
        await m.alterTable(TableMigration(moodEntries));
      }
    },
    beforeOpen: (details) async {
      // Ensure custom_metrics column exists if database was created or copied without it
      try {
        await customStatement('ALTER TABLE mood_entries ADD COLUMN custom_metrics TEXT;');
      } catch (_) {}

      // If legacy v1 mood columns (energy, happiness, etc.) exist, migrate them into custom_metrics
      try {
        final tableInfo = await customSelect('PRAGMA table_info(mood_entries);').get();
        final columnNames = tableInfo
            .map((r) => r.data['name']?.toString().toLowerCase())
            .whereType<String>()
            .toSet();

        if (columnNames.contains('energy')) {
          final rows = await customSelect(
            'SELECT * FROM mood_entries WHERE custom_metrics IS NULL OR custom_metrics = ""',
          ).get();
          for (final row in rows) {
            final data = row.data;
            final Map<String, int> metrics = {};
            for (final k in [
              'energy',
              'happiness',
              'creativity',
              'focus',
              'irritability',
              'anxiety',
            ]) {
              if (data.containsKey(k) && data[k] != null) {
                final title = k[0].toUpperCase() + k.substring(1);
                final val = int.tryParse(data[k].toString());
                if (val != null) metrics[title] = val;
              }
            }
            if (metrics.isNotEmpty) {
              final id = data['id'];
              final encoded = jsonEncode(metrics);
              await customStatement(
                'UPDATE mood_entries SET custom_metrics = ? WHERE id = ?',
                [encoded, id],
              );
            }
          }
        }
      } catch (_) {}
    },
  );

  // // ── Sleep helpers ────────────────────────────────────────────
  Future<int> insertSleep(SleepEntriesCompanion data) =>
      into(sleepEntries).insert(data);

  Stream<List<SleepEntry>> watchAllSleep() =>
      (select(sleepEntries)
        ..orderBy([(t) => OrderingTerm.desc(t.date)])).watch();

  Future<SleepEntry?> entryFor(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return (select(sleepEntries)
      ..where((t) => t.date.isBetweenValues(start, end))).getSingleOrNull();
  }

  Future<void> updateSleepEntry(SleepEntry entry) {
    return (update(sleepEntries)
      ..where((tbl) => tbl.id.equals(entry.id))).write(entry);
  }

  Future<int> deleteSleepEntry(int id) {
    return (delete(sleepEntries)..where((tbl) => tbl.id.equals(id))).go();
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'libretrac',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}
