import 'package:drift/drift.dart';

class ReactionResults extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get timestamp => dateTime()();
  RealColumn get averageTime => real()();
  RealColumn get fastest => real()();
  RealColumn get slowest => real()();
}

// ── NEW tables ───────────────────────────────────────────────
class StroopResults extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  RealColumn get congruentMs => real()();
  RealColumn get incongruentMs => real()();
  RealColumn get deltaMs => real()(); // incongruent − congruent
}

class GoNoGoResults extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  RealColumn get meanRt => real()(); // ms, hits only
  IntColumn get commissionErrors => integer()();
  IntColumn get omissionErrors => integer()();
}

class DigitSpanResults extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  IntColumn get bestSpan => integer()();
}

class SymbolSearchResults extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  IntColumn get hits => integer()();
  IntColumn get total => integer()();
  RealColumn get meanRt => real()(); // ms
}
