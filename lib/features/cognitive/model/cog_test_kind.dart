import 'package:drift/drift.dart' as drift;
import 'package:libretrac/core/database/app_database.dart';

enum CogTestKind { reaction, stroop, goNoGo, digitSpan, symbolSearch }

extension CogTestX on CogTestKind {
  String get label => switch (this) {
    CogTestKind.reaction => 'Reaction Time',
    CogTestKind.stroop => 'Stroop Δ',
    CogTestKind.goNoGo => 'Go/No-Go RT',
    CogTestKind.digitSpan => 'Digit Span',
    CogTestKind.symbolSearch => 'Symbol Search RT',
  };

  // Pick a single metric per test for the Y-axis
  double y(dynamic row) => switch (this) {
    CogTestKind.reaction => row.averageTime,
    CogTestKind.stroop => row.deltaMs,
    CogTestKind.goNoGo => row.meanRt,
    CogTestKind.digitSpan => row.bestSpan.toDouble(),
    CogTestKind.symbolSearch => row.meanRt,
  };

  // Map enum → table for your FutureBuilder
  drift.TableInfo<dynamic, dynamic> table(AppDatabase db) => switch (this) {
    CogTestKind.reaction => db.reactionResults,
    CogTestKind.stroop => db.stroopResults,
    CogTestKind.goNoGo => db.goNoGoResults,
    CogTestKind.digitSpan => db.digitSpanResults,
    CogTestKind.symbolSearch => db.symbolSearchResults,
  };

  bool get lowerIsBetter => switch (this) {
    CogTestKind.reaction ||
    CogTestKind.goNoGo ||
    CogTestKind.symbolSearch => true,
    CogTestKind.stroop => true, // lower Stroop Δ → less interference
    _ => false, // DigitSpan ↑ is better
  };

  (double lo, double hi) get refRange => switch (this) {
    CogTestKind.reaction => (260, 560),
    CogTestKind.goNoGo => (250, 600),
    CogTestKind.symbolSearch => (1000, 4000),
    CogTestKind.stroop => (0, 400),
    CogTestKind.digitSpan => (2, 9),
  };
}
