import 'dart:async';
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

  Widget _buildTwoRowMetrics(BuildContext context) {
    if (allMetrics.isEmpty) return const SizedBox.shrink();

    // Split metrics across at most 2 rows so they NEVER wrap onto a 3rd row.
    final int total = allMetrics.length;
    final int firstRowCount = total <= 3 ? total : (total / 2).ceil();
    final List<CustomMetric> row1 = allMetrics.sublist(0, firstRowCount);
    final List<CustomMetric> row2 =
        total > firstRowCount
            ? allMetrics.sublist(firstRowCount)
            : const <CustomMetric>[];

    Widget buildChipRow(List<CustomMetric> rowMetrics) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < rowMetrics.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Flexible(
              fit: FlexFit.tight,
              child: _MetricFilterChip(
                metric: rowMetrics[i],
                selected: selectedMetrics.contains(rowMetrics[i].name),
                onSelected:
                    (val) => onMetricToggle(rowMetrics[i].name, val),
              ),
            ),
          ],
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        buildChipRow(row1),
        if (row2.isNotEmpty) ...[
          const SizedBox(height: 6),
          buildChipRow(row2),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSingle = ordered.length == 1;
    final double minX = isSingle ? -0.5 : 0;
    final double maxX =
        isSingle ? 0.5 : max(1.0, (ordered.length - 1).toDouble());

    return Column(
      children: [
        _buildTwoRowMetrics(context),
        const SizedBox(height: 10),
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

class _MetricFilterChip extends StatelessWidget {
  const _MetricFilterChip({
    required this.metric,
    required this.selected,
    required this.onSelected,
  });

  final CustomMetric metric;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color:
          selected
              ? metric.color.withValues(alpha: 0.25)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.4,
              ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color:
              selected
                  ? metric.color.withValues(alpha: 0.7)
                  : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onSelected(!selected),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      selected ? Icons.check_circle : Icons.circle_outlined,
                      size: 13,
                      color: selected ? metric.color : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: _MarqueeText(
                        text: metric.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Auto-scrolling marquee text widget when text overflows its container width.
class _MarqueeText extends StatefulWidget {
  const _MarqueeText({
    required this.text,
    this.style,
    this.textAlign = TextAlign.center,
  });

  final String text;
  final TextStyle? style;
  final TextAlign textAlign;

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText> {
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startMarqueeIfNeeded());
  }

  @override
  void didUpdateWidget(covariant _MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _timer?.cancel();
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _startMarqueeIfNeeded(),
      );
    }
  }

  void _startMarqueeIfNeeded() {
    if (!mounted || !_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (!mounted || !_scrollController.hasClients) return;
      final extent = _scrollController.position.maxScrollExtent;
      if (extent <= 0) return;
      await _scrollController.animateTo(
        extent,
        duration: Duration(milliseconds: (extent * 35).clamp(800, 3000).toInt()),
        curve: Curves.linear,
      );
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted || !_scrollController.hasClients) return;
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Text(
              widget.text,
              maxLines: 1,
              softWrap: false,
              textAlign: widget.textAlign,
              style: widget.style,
            ),
          ),
        );
      },
    );
  }
}
