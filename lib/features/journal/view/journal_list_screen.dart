import 'package:drift/drift.dart' as drift;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:libretrac/core/database/app_database.dart';
import 'package:libretrac/features/journal/view/journal_detail_screen.dart';
import 'package:libretrac/features/mood_sleep/view/mood_checkin_screen.dart';
import 'package:libretrac/providers/db_provider.dart';

class JournalListScreen extends ConsumerWidget {
  const JournalListScreen({super.key});

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final moodAsync = ref.watch(journalEntriesStreamProvider);
    final sleepAsync = ref.watch(sleepStreamProvider);

    if (moodAsync.isLoading || sleepAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (moodAsync.hasError || sleepAsync.hasError) {
      final err = moodAsync.error ?? sleepAsync.error;
      final stack = moodAsync.stackTrace ?? sleepAsync.stackTrace;
      return Scaffold(body: Center(child: Text('⚠️ $err\n$stack')));
    }

    final moods = moodAsync.value ?? const <MoodEntry>[];
    final sleeps = sleepAsync.value ?? const <SleepEntry>[];

    final moodRows = <_JournalRow>[];
    final sleepRows = <_JournalRow>[];

    final filter = ref.watch(journalFilterProvider);
    final metricDefs = ref.watch(customMetricsProvider);

    for (final m in moods) {
      final hasNote = (m.notes?.trim().isNotEmpty ?? false);
      if (filter == JournalFilter.all || hasNote) {
        moodRows.add(_JournalRow.mood(m, metricDefs));
      }
    }

    for (final s in sleeps) {
      final hasDream = (s.dreamJournal?.trim().isNotEmpty ?? false);
      if (filter == JournalFilter.all || hasDream) {
        sleepRows.add(_JournalRow.sleep(s));
      }
    }

    moodRows.sort((a, b) => b.date.compareTo(a.date));
    sleepRows.sort((a, b) => b.date.compareTo(a.date));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            filter == JournalFilter.all ? 'All Check-ins' : 'Journals',
          ),
          bottom: const TabBar(
            tabs: [Tab(text: 'Mood'), Tab(text: 'Sleep')],
          ),
          actions: [
            PopupMenuButton<JournalFilter>(
              icon: const Icon(Icons.filter_list),
              onSelected:
                  (val) => ref.read(journalFilterProvider.notifier).state = val,
              itemBuilder:
                  (ctx) => [
                    const PopupMenuItem(
                      value: JournalFilter.all,
                      child: Text('All Check-ins'),
                    ),
                    const PopupMenuItem(
                      value: JournalFilter.notesOnly,
                      child: Text('Journal Entries Only'),
                    ),
                  ],
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _JournalList(rows: moodRows),
            _JournalList(rows: sleepRows),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed:
              () => Navigator.push(
                ctx,
                MaterialPageRoute(builder: (_) => const MoodCheckInScreen()),
              ),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _JournalList extends StatelessWidget {
  const _JournalList({required this.rows});

  final List<_JournalRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(child: Text('No entries found.'));
    }

    return ListView.separated(
      itemCount: rows.length,
      separatorBuilder: (_, __) => const Divider(height: 0),
      itemBuilder: (ctx, i) {
        final row = rows[i];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                row.isSleep ? Icons.bedtime : Icons.mood,
                color:
                    row.isSleep
                        ? Theme.of(ctx).colorScheme.primary
                        : Theme.of(ctx).colorScheme.secondary,
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat.MMMd().format(row.date),
                style: const TextStyle(fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          title: null,
          subtitle: SizedBox(
            height: 80,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (row.miniBars.isNotEmpty) MiniBarGraph(row.miniBars),
                if (row.preview.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      row.preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontStyle:
                            row.preview.startsWith('(')
                                ? FontStyle.italic
                                : null,
                        color:
                            row.preview.startsWith('(')
                                ? Theme.of(ctx).colorScheme.onSurface
                                    .withValues(alpha: 0.6)
                                : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          onTap: () {
            if (row.isSleep) {
              Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) => SleepDetailScreen(entry: row.sleep!),
                ),
              );
            } else {
              Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) => JournalDetailScreen(entry: row.mood!),
                ),
              );
            }
          },
        );
      },
    );
  }
}

// class _JournalRow {
//   _JournalRow.mood(this.mood)
//     : sleep = null,
//       date = mood!.timestamp,
//       preview =
//           (mood.notes?.trim().isNotEmpty ?? false)
//               ? mood.notes!.split('\n').first
//               : '',
//       isSleep = false;

//   _JournalRow.sleep(this.sleep)
//     : mood = null,
//       date = sleep!.date,
//       preview = [
//         '${sleep.hoursSlept.toStringAsFixed(1)} h',
//         'Q${sleep.quality}',
//         if (sleep.dreamJournal?.trim().isNotEmpty ?? false)
//           sleep.dreamJournal!.split('\n').first
//         else
//           '',
//       ].join(' • '),
//       isSleep = true;

//   final MoodEntry? mood;
//   final SleepEntry? sleep;
//   final DateTime date;
//   final String preview;
//   final bool isSleep;
// }

class _JournalRow {
  _JournalRow.mood(this.mood, List<CustomMetric> metricDefs)
    : sleep = null,
      date = mood!.timestamp,
      preview = mood.notes?.trim().split('\n').first ?? '',
      isSleep = false,
      miniBars = _generateMoodBars(mood, metricDefs);

  _JournalRow.sleep(this.sleep)
    : mood = null,
      date = sleep!.date,
      preview = '', // remove the text here
      isSleep = true,
      miniBars = _generateSleepBars(sleep);

  final MoodEntry? mood;
  final SleepEntry? sleep;
  final DateTime date;
  final String preview;
  final bool isSleep;
  final List<(String, double, Color)> miniBars;

  static List<(String, double, Color)> _generateMoodBars(
    MoodEntry entry,
    List<CustomMetric> metricDefs,
  ) {
    final values = entry.customMetrics ?? {};

    return metricDefs
        .where((m) => values.containsKey(m.name))
        .map(
          (m) => (
            m.name,
            (values[m.name]!.toDouble() / 10).clamp(0.0, 1.0),
            m.color,
          ),
        )
        .toList();
  }

  static List<(String, double, Color)> _generateSleepBars(SleepEntry entry) {
    return [
      ('Sleep', (entry.hoursSlept / 12.0).clamp(0.0, 1.0), Colors.indigo),
      ('Quality', (entry.quality / 5.0).clamp(0.0, 1.0), Colors.green),
    ];
  }
}

class SleepDetailScreen extends StatelessWidget {
  const SleepDetailScreen({required this.entry, super.key});
  final SleepEntry entry;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat.yMMMd().add_jm();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep Entry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditSleepEntryScreen(entry: entry),
                ),
              );
            },
          ),
        ],
      ),

      resizeToAvoidBottomInset: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title + Date ────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: Text(
              dateFmt.format(entry.date),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 16),
          // ── Dream Notes ────────────────────────────────
          if (entry.dreamJournal != null &&
              entry.dreamJournal!.trim().isNotEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // const Text(
                    // 'Notes',
                    // style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    // ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 300,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Text(
                                entry.dreamJournal!,
                                style: const TextStyle(fontSize: 18),
                                textAlign: TextAlign.left,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No dream notes for this night.'),
              ),
            ),
          // const Spacer(),
          // ── Sleep Bar Graph ────────────────────────────────
          SizedBox(
            height: 450,
            child: Padding(
              padding: const EdgeInsets.only(right: 12, bottom: 24),
              child: BarChart(
                BarChartData(
                  maxY: 10,
                  minY: 0,
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: (entry.hoursSlept / 12.0) * 10.0,
                          width: 150,
                          color: Colors.indigo,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: (entry.quality / 5.0) * 10.0,
                          width: 150,
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ],
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval:
                            1, // shows ticks every 2 units (for even spacing)
                        getTitlesWidget: (value, _) {
                          // Convert graph value back to hours (0–10 → 0–12)
                          final hours = (value * 1.2);
                          return Text(
                            hours.toStringAsFixed(0),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, _) {
                          // Only show labels at exact mapped positions
                          const qualityTicks = {
                            0: '0',
                            2: '1',
                            4: '2',
                            6: '3',
                            8: '4',
                            10: '5',
                          };
                          if (qualityTicks.containsKey(value)) {
                            return Text(
                              qualityTicks[value]!,
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),

                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (value, _) {
                          final labels = ['Hours Slept', 'Quality'];
                          return Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              labels[value.toInt()],
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
        ],
      ),
    );
  }
}

class EditSleepEntryScreen extends ConsumerStatefulWidget {
  const EditSleepEntryScreen({required this.entry, super.key});
  final SleepEntry entry;

  @override
  ConsumerState<EditSleepEntryScreen> createState() =>
      _EditSleepEntryScreenState();
}

class _EditSleepEntryScreenState extends ConsumerState<EditSleepEntryScreen> {
  late double hours;
  late int quality;
  late TextEditingController journalController;

  @override
  void initState() {
    super.initState();
    hours = widget.entry.hoursSlept;
    quality = widget.entry.quality;
    journalController = TextEditingController(
      text: widget.entry.dreamJournal ?? '',
    );
  }

  @override
  void dispose() {
    journalController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final db = ref.read(dbProvider);
    await db.updateSleepEntry(
      widget.entry.copyWith(
        hoursSlept: hours,
        quality: quality,
        dreamJournal: drift.Value(journalController.text.trim()),
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Sleep Entry')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              initialValue: hours.toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Hours Slept'),
              onChanged: (val) => hours = double.tryParse(val) ?? hours,
            ),
            DropdownButtonFormField<int>(
              value: quality,
              decoration: const InputDecoration(labelText: 'Sleep Quality'),
              items:
                  [1, 2, 3, 4, 5]
                      .map((q) => DropdownMenuItem(value: q, child: Text('$q')))
                      .toList(),
              onChanged: (val) => quality = val ?? quality,
            ),
            TextFormField(
              controller: journalController,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Dream Journal'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}

class MiniBarGraph extends StatelessWidget {
  final List<(String, double, Color)> bars;

  const MiniBarGraph(this.bars, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: BarChart(
        BarChartData(
          barTouchData: BarTouchData(enabled: false),
          maxY: 1,
          minY: 0,
          barGroups: [
            for (int i = 0; i < bars.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: bars[i].$2,
                    width: 14,
                    color: bars[i].$3,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
          ],
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
                getTitlesWidget: (value, _) {
                  if (value.toInt() < bars.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        bars[value.toInt()].$1,
                        style: const TextStyle(fontSize: 9),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
