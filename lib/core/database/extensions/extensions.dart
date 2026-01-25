import 'package:intl/intl.dart';
import 'package:libretrac/core/database/app_database.dart';

String formatDate(DateTime date) {
  return DateFormat('yyyy-MM-dd').format(date);
}

// MoodEntry
extension MoodEntryExport on MoodEntry {
  Map<String, dynamic> toExportJson() => {
    'date': formatDate(timestamp),
    'customMetrics': customMetrics,
    if (notes != null) 'notes': notes,
  };
}

// SleepEntry
extension SleepEntryExport on SleepEntry {
  Map<String, dynamic> toExportJson() => {
    'date': formatDate(date),
    'hoursSlept': hoursSlept,
    'quality': quality,
    if (dreamJournal != null) 'dreamJournal': dreamJournal,
  };
}

// ReactionResult
extension ReactionResultExport on ReactionResult {
  Map<String, dynamic> toExportJson() => {
    'date': formatDate(timestamp),
    'averageMs': averageTime,
    'fastestMs': fastest,
    'slowestMs': slowest,
  };
}

// StroopResult
extension StroopResultExport on StroopResult {
  Map<String, dynamic> toExportJson() => {
    'date': formatDate(timestamp),
    'congruentMs': congruentMs,
    'incongruentMs': incongruentMs,
    'deltaMs': deltaMs,
  };
}

// GoNoGoResult
extension GoNoGoResultExport on GoNoGoResult {
  Map<String, dynamic> toExportJson() => {
    'date': formatDate(timestamp),
    'meanRt': meanRt,
    'commissionErrors': commissionErrors,
    'omissionErrors': omissionErrors,
  };
}

// DigitSpanResult
extension DigitSpanResultExport on DigitSpanResult {
  Map<String, dynamic> toExportJson() => {
    'date': formatDate(timestamp),
    'bestSpan': bestSpan,
  };
}

// SymbolSearchResult
extension SymbolSearchResultExport on SymbolSearchResult {
  Map<String, dynamic> toExportJson() => {
    'date': formatDate(timestamp),
    'hits': hits,
    'total': total,
    'meanRt': meanRt,
  };
}

// Substance
extension SubstanceExport on Substance {
  Map<String, dynamic> toExportJson() => {
    'name': name,
    if (dosage != null) 'dosage': dosage,
    if (notes != null) 'notes': notes,
    'addedAt': formatDate(addedAt),
    if (stoppedAt != null) 'stoppedAt': formatDate(stoppedAt!),
  };
}
