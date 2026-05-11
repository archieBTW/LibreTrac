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
