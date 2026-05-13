import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:libretrac/core/database/app_database.dart';
import 'package:libretrac/features/shared/chart/single_metric_line.dart';

class SleepChartPage extends StatelessWidget {
  const SleepChartPage({required this.entries});

  final List<SleepEntry> entries;

  static const double _qualityScale = 12 / 5; // 2.4 → fits 1-5 onto 0-12

  @override
  Widget build(BuildContext context) {
    // oldest → newest for a sensible X-axis
    final ordered = [...entries]..sort((a, b) => a.date.compareTo(b.date));

    final hoursSpots = <FlSpot>[];
    final qualitySpots = <FlSpot>[];

    for (var i = 0; i < ordered.length; i++) {
      final e = ordered[i];
      hoursSpots.add(FlSpot(i.toDouble(), e.hoursSlept));
      qualitySpots.add(FlSpot(i.toDouble(), e.quality * _qualityScale));
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: SingleMetricLine(
                      entries: ordered,
                      title: 'Hours slept',
                      maxY: 12,
                      getY: (e) => e.hoursSlept,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleMetricLine(
                      entries: ordered,
                      title: 'Sleep quality',
                      maxY: 5,
                      getY: (e) => e.quality.toDouble(),
                      color: Colors.pink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
