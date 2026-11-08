import 'package:flutter/material.dart';
import 'package:libretrac/core/database/app_database.dart';
import 'package:libretrac/features/shared/chart/single_metric_line.dart';

class SleepChartPage extends StatelessWidget {
  const SleepChartPage({required this.entries, super.key});

  final List<SleepEntry> entries;

  @override
  Widget build(BuildContext context) {
    // Only plot actual sleep check-ins (hoursSlept > 0), excluding standalone dream-only entries
    final sleepOnly = entries.where((e) => e.hoursSlept > 0).toList();
    // oldest → newest for a sensible X-axis
    final ordered = [...sleepOnly]..sort((a, b) => a.date.compareTo(b.date));

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
