import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libretrac/features/ai/service/gemini_api_service.dart';
import 'package:libretrac/providers/db_provider.dart';

enum TrendRange { week, month, threeMonths, sixMonths }

extension on TrendRange {
  int get days => switch (this) {
    TrendRange.week => 7,
    TrendRange.month => 30,
    TrendRange.threeMonths => 90,
    TrendRange.sixMonths => 180,
  };
}

final trendRangeProvider = StateProvider<TrendRange>((_) => TrendRange.week);

final analysisProvider = FutureProvider.autoDispose<String?>((ref) async {
  final range = ref.watch(trendRangeProvider);
  final since = DateTime.now().subtract(Duration(days: range.days));

  final db = ref.read(dbProvider);

  final moods = await db.moodEntriesSince(since);
  final reactions = await db.reactionResultsSince(since);
  final stroop = await db.stroopResultsSince(since);
  final goNoGo = await db.goNoGoResultsSince(since);
  final digitSpan = await db.digitSpanResultsSince(since);
  final symbolSearch = await db.symbolSearchResultsSince(since);
  final substances = await db.substancesActiveSince(since);
  final sleeps = await db.sleepEntriesSince(since);

  // If there's nothing to analyze, return null
  final hasData =
      moods.isNotEmpty ||
      reactions.isNotEmpty ||
      stroop.isNotEmpty ||
      goNoGo.isNotEmpty ||
      digitSpan.isNotEmpty ||
      symbolSearch.isNotEmpty;

  if (!hasData) return null;

  final api = GeminiAPI.instance;

  return api.analyzeTrends(
    TrendRequest(
      since: since,
      moods: moods,
      reactions: reactions,
      stroop: stroop,
      goNoGo: goNoGo,
      digitSpan: digitSpan,
      symbolSearch: symbolSearch,
      substances: substances,
      sleeps: sleeps,
    ),
  );
});
