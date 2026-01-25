import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libretrac/features/cognitive/model/cog_test_kind.dart';
import 'package:libretrac/providers/db_provider.dart';
import 'package:libretrac/core/database/app_database.dart';

class CognitiveChart {
  showCognitiveChart(WidgetRef ref, MoodWindow window, bool detailed) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Center(
          child: Text(
            'Cognitive Trends',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),

        SizedBox(
          height: 220,
          child: PageView.builder(
            itemCount: CogTestKind.values.length,
            controller: PageController(viewportFraction: .92, keepPage: true),
            itemBuilder: (ctx, index) {
              final kind = CogTestKind.values[index];
              
              return _CognitiveChartCard(
                kind: kind,
                window: window,
                detailed: detailed,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CognitiveChartCard extends ConsumerWidget {
  const _CognitiveChartCard({
    required this.kind,
    required this.window,
    required this.detailed,
  });

  final CogTestKind kind;
  final MoodWindow window;
  final bool detailed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cutoff = DateTime.now().subtract(Duration(days: window.days + 1));
    
    // Handle each type separately to maintain type safety
    switch (kind) {
      case CogTestKind.reaction:
        return ref.watch(reactionResultsStreamProvider).when(
          loading: () => _buildCard(context, [], kind),
          error: (e, _) => _buildCard(context, [], kind),
          data: (rows) => _buildCard(
            context,
            _processRows(rows, cutoff, (r) => r.timestamp),
            kind,
          ),
        );
      case CogTestKind.stroop:
        return ref.watch(stroopResultsStreamProvider).when(
          loading: () => _buildCard(context, [], kind),
          error: (e, _) => _buildCard(context, [], kind),
          data: (rows) => _buildCard(
            context,
            _processRows(rows, cutoff, (r) => r.timestamp),
            kind,
          ),
        );
      case CogTestKind.goNoGo:
        return ref.watch(goNoGoResultsStreamProvider).when(
          loading: () => _buildCard(context, [], kind),
          error: (e, _) => _buildCard(context, [], kind),
          data: (rows) => _buildCard(
            context,
            _processRows(rows, cutoff, (r) => r.timestamp),
            kind,
          ),
        );
      case CogTestKind.digitSpan:
        return ref.watch(digitSpanResultsStreamProvider).when(
          loading: () => _buildCard(context, [], kind),
          error: (e, _) => _buildCard(context, [], kind),
          data: (rows) => _buildCard(
            context,
            _processRows(rows, cutoff, (r) => r.timestamp),
            kind,
          ),
        );
      case CogTestKind.symbolSearch:
        return ref.watch(symbolSearchResultsStreamProvider).when(
          loading: () => _buildCard(context, [], kind),
          error: (e, _) => _buildCard(context, [], kind),
          data: (rows) => _buildCard(
            context,
            _processRows(rows, cutoff, (r) => r.timestamp),
            kind,
          ),
        );
    }
  }

  List<T> _processRows<T>(
    List<T> allRows,
    DateTime cutoff,
    DateTime Function(T) getTimestamp,
  ) {
    var rows = allRows
        .where((r) => getTimestamp(r).isAfter(cutoff))
        .toList()
      ..sort((a, b) => getTimestamp(a).compareTo(getTimestamp(b)));

    // Condense: Keep only the latest per day unless few results or detailed is on
    if (detailed || rows.length <= window.days) {
      return rows;
    }

    final Map<String, T> latestPerDay = {};
    for (final r in rows) {
      final ts = getTimestamp(r);
      final dayKey = DateTime(ts.year, ts.month, ts.day).toIso8601String();
      if (!latestPerDay.containsKey(dayKey) ||
          getTimestamp(r).isAfter(getTimestamp(latestPerDay[dayKey] as T))) {
        latestPerDay[dayKey] = r;
      }
    }
    return latestPerDay.values.toList()
      ..sort((a, b) => getTimestamp(a).compareTo(getTimestamp(b)));
  }

  Widget _buildCard(BuildContext context, List<dynamic> processed, CogTestKind kind) {
    final raw = [
      for (int i = 0; i < processed.length; i++)
        FlSpot(i.toDouble(), kind.y(processed[i])),
    ];

    final (lo, hi) = kind.refRange;
    final span = (hi - lo).abs();

    double toPct(double v) {
      final clamped = v.clamp(min(lo, hi), max(lo, hi));
      final frac =
          kind.lowerIsBetter
              ? (hi - clamped) / span
              : (clamped - lo) / span;
      return frac * 100;
    }

    final spots = [for (final p in raw) FlSpot(p.x, toPct(p.y))];

    // Get timestamps for x-axis labels
    List<DateTime> timestamps = [];
    for (final r in processed) {
      timestamps.add(r.timestamp);
    }

    return Card(
      key: Key(kind.label),
      elevation: 2,
      margin: const EdgeInsets.only(right: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              kind.label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: RepaintBoundary(
                child: spots.isEmpty
                    ? const Center(
                        child: Text(
                          'No data yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : LineChart(
                        LineChartData(
                          clipData: FlClipData.all(),
                          lineTouchData: LineTouchData(
                            enabled: false,
                            handleBuiltInTouches: false,
                          ),
                          minY: 0,
                          maxY: 105,
                          minX: 0,
                          maxX: max(0, (spots.length - 1).toDouble()),
                          gridData: FlGridData(show: true),
                          titlesData: FlTitlesData(
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(
                                maxIncluded: false,
                                showTitles: true,
                                reservedSize: 42,
                                interval: 50,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                maxIncluded: false,
                                showTitles: true,
                                reservedSize: 42,
                                interval: 50,
                              ),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                getTitlesWidget: (value, _) {
                                  final i = value.toInt();
                                  if (i < 0 || i >= timestamps.length) {
                                    return const SizedBox.shrink();
                                  }
                                  final d = timestamps[i];
                                  return Text(
                                    '${d.month}/${d.day}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              color: Colors.amber,
                              barWidth: 3,
                              dotData: FlDotData(show: false),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
