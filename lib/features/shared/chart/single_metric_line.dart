import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:libretrac/core/database/app_database.dart';

class SingleMetricLine extends StatelessWidget {
  const SingleMetricLine({
    super.key,
    required this.entries,
    required this.title,
    required this.maxY,
    required this.getY,
    required this.color,
    this.minY = 0,
    this.intervalY,
  });

  final List<SleepEntry> entries;
  final String title;
  final double minY;
  final double maxY;
  final double? intervalY; // if null → auto‐pick
  final double Function(SleepEntry e) getY;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // oldest → newest so X-axis labels make sense
    final ordered = [...entries]..sort((a, b) => a.date.compareTo(b.date));

    final spots = <FlSpot>[
      for (var i = 0; i < ordered.length; i++)
        FlSpot(i.toDouble(), getY(ordered[i])),
    ];

    final isSingle = ordered.length == 1;
    final double minX = isSingle ? -0.5 : 0;
    final double maxX =
        isSingle ? 0.5 : max(1.0, (ordered.length - 1).toDouble());

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(title, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Expanded(
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    enabled: false,
                    handleBuiltInTouches: false,
                  ),
                  minX: minX,
                  maxX: maxX,
                  minY: minY,
                  maxY: maxY,
                  gridData: FlGridData(show: true),
                  extraLinesData: ExtraLinesData(
                    horizontalLines:
                        isSingle
                            ? [
                              HorizontalLine(
                                y: getY(ordered.first),
                                color: color.withValues(alpha: 0.35),
                                strokeWidth: 1.5,
                                dashArray: [6, 4],
                              ),
                            ]
                            : const [],
                  ),
                  lineBarsData: [
                    if (spots.isNotEmpty)
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        barWidth: 3,
                        color: color,
                        dotData: FlDotData(
                          show: isSingle || spots.length <= 7,
                          getDotPainter: (spot, percent, barData, index) =>
                              FlDotCirclePainter(
                                radius: isSingle ? 5.5 : 3.0,
                                color: color,
                                strokeWidth: isSingle ? 2.0 : 1.0,
                                strokeColor: Colors.white,
                              ),
                        ),
                        belowBarData: BarAreaData(show: false),
                      ),
                  ],
                  titlesData: FlTitlesData(
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    // Y-axis
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        interval:
                            intervalY ??
                            ((maxY - minY) / 5).clamp(1, double.infinity),
                      ),
                    ),
                    // X-axis
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, _) {
                          if ((value - value.roundToDouble()).abs() > 0.01) {
                            return const SizedBox.shrink();
                          }
                          final i = value.round();
                          if (i < 0 || i >= ordered.length) {
                            return const SizedBox.shrink();
                          }
                          final d = ordered[i].date;
                          return Text(
                            '${d.month}/${d.day}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
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
