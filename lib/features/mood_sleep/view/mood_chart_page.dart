import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:libretrac/core/database/app_database.dart';
import 'package:libretrac/providers/db_provider.dart';

class MoodChartPage extends StatelessWidget {
  const MoodChartPage({
    required this.ordered,
    required this.selectedMetrics,
    required this.allMetrics,
    required this.onMetricToggle,
    required this.customMetrics,
    required this.window,
    super.key,
  });

  final List<MoodEntry> ordered;
  final Set<String> selectedMetrics;
  final List<CustomMetric> allMetrics;

  final void Function(String metric, bool isSelected) onMetricToggle;
  final List<CustomMetric>? customMetrics;
  final MoodWindow window;

  List<LineChartBarData> _generateMoodLines(List<MoodEntry> entries) {
    final List<LineChartBarData> lines = [];

    for (final metric in allMetrics.where(
      (m) => selectedMetrics.contains(m.name),
    )) {
      final spots = <FlSpot>[];

      for (int i = 0; i < entries.length; i++) {
        final entry = entries[i];
        final value = entry.customMetrics?[metric.name]?.toDouble();

        if (value != null) {
          spots.add(FlSpot(i.toDouble(), value));
        }
      }

      if (spots.isNotEmpty) {
        final isSingle = spots.length == 1;
        lines.add(
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 3,
            color: metric.color,
            dotData: FlDotData(
              show: isSingle || spots.length <= 7,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                    radius: isSingle ? 5.5 : 3.0,
                    color: metric.color,
                    strokeWidth: isSingle ? 2.0 : 1.0,
                    strokeColor: Colors.white,
                  ),
            ),
            belowBarData: BarAreaData(show: false),
          ),
        );
      }
    }

    return lines;
  }

  List<HorizontalLine> _generateSinglePointReferenceLines(
    List<MoodEntry> entries,
  ) {
    if (entries.length != 1) return const [];
    final entry = entries.first;
    final lines = <HorizontalLine>[];
    for (final metric in allMetrics.where(
      (m) => selectedMetrics.contains(m.name),
    )) {
      final value = entry.customMetrics?[metric.name]?.toDouble();
      if (value != null) {
        lines.add(
          HorizontalLine(
            y: value,
            color: metric.color.withValues(alpha: 0.35),
            strokeWidth: 1.5,
            dashArray: [6, 4],
          ),
        );
      }
    }
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final isSingle = ordered.length == 1;
    final double minX = isSingle ? -0.5 : 0;
    final double maxX =
        isSingle ? 0.5 : max(1.0, (ordered.length - 1).toDouble());

    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children:
              allMetrics.map((metric) {
                final selected = selectedMetrics.contains(metric.name);
                return FilterChip(
                  label: Text(metric.name),
                  selected: selected,
                  selectedColor: metric.color.withValues(alpha: .30),
                  onSelected: (value) => onMetricToggle(metric.name, value),
                );
              }).toList(),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  enabled: false,
                  handleBuiltInTouches: false,
                ),
                minY: 0,
                maxY: 10,
                minX: minX,
                maxX: maxX,
                gridData: FlGridData(show: true),
                extraLinesData: ExtraLinesData(
                  horizontalLines: _generateSinglePointReferenceLines(ordered),
                ),
                titlesData: FlTitlesData(
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      reservedSize: 42,
                      showTitles: true,
                      interval: 2,
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      reservedSize: 42,
                      showTitles: true,
                      interval: 2,
                    ),
                  ),
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
                        final d = ordered[i].timestamp;

                        Widget label(String text) =>
                            Text(text, style: const TextStyle(fontSize: 10));

                        switch (window) {
                          case MoodWindow.week:
                            return label('${d.month}/${d.day}');
                          case MoodWindow.month:
                            if (i == 0) {
                              return label('${d.month}/${d.day}');
                            } else {
                              final prev = ordered[i - 1].timestamp;
                              if (!_isSameWeek(prev, d)) {
                                return label('${d.month}/${d.day}');
                              }
                            }
                            return const SizedBox.shrink();
                          case MoodWindow.threeMonths:
                          case MoodWindow.sixMonths:
                            if (i == 0) {
                              return label(_monthName(d.month));
                            } else {
                              final prev = ordered[i - 1].timestamp;
                              if (prev.month != d.month) {
                                return label(_monthName(d.month));
                              }
                            }
                            return const SizedBox.shrink();
                        }
                      },
                    ),
                  ),
                ),
                lineBarsData: _generateMoodLines(ordered),
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _isSameWeek(DateTime a, DateTime b) {
    final aStart = a.subtract(Duration(days: a.weekday - 1));
    final bStart = b.subtract(Duration(days: b.weekday - 1));

    return aStart.year == bStart.year &&
        aStart.month == bStart.month &&
        aStart.day == bStart.day;
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month < 1 || month > 12) return '';
    return months[month - 1];
  }
}
