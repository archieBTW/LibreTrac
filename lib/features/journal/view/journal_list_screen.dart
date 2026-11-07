import 'package:drift/drift.dart' as drift;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:libretrac/core/database/app_database.dart';
import 'package:libretrac/features/ai/service/gemini_api_service.dart';
import 'package:libretrac/features/journal/view/journal_detail_screen.dart';
import 'package:libretrac/features/mood_sleep/model/dream_metadata.dart';
import 'package:libretrac/features/mood_sleep/view/mood_checkin_screen.dart';
import 'package:libretrac/features/mood_sleep/view/sleep_checkin_dialog.dart';
import 'package:libretrac/features/substances/add_edit_substance_screen.dart';
import 'package:libretrac/features/substances/model/medication_dose_log.dart';
import 'package:libretrac/providers/db_provider.dart';
import 'package:libretrac/services/prefs_service.dart';

final sleepTagFilterProvider = StateProvider<String?>((ref) => null);

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
    final selectedDreamTag = ref.watch(sleepTagFilterProvider);
    final metricDefs = ref.watch(customMetricsProvider);

    for (final m in moods) {
      final hasNote = (m.notes?.trim().isNotEmpty ?? false);
      if (filter == JournalFilter.all || hasNote) {
        moodRows.add(_JournalRow.mood(m, metricDefs));
      }
    }

    for (final s in sleeps) {
      final hasDream = s.hasDream;
      if (filter == JournalFilter.notesOnly && !hasDream) continue;
      if (selectedDreamTag != null) {
        if (selectedDreamTag == '__has_dream__') {
          if (!hasDream) continue;
        } else if (!s.dreamTags.contains(selectedDreamTag)) {
          continue;
        }
      }
      sleepRows.add(_JournalRow.sleep(s));
    }

    moodRows.sort((a, b) => b.date.compareTo(a.date));
    sleepRows.sort((a, b) => b.date.compareTo(a.date));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            filter == JournalFilter.all ? 'All Check-ins' : 'Journals',
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Mood'),
              Tab(text: 'Sleep & Dreams'),
              Tab(text: 'Meds'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              tooltip: 'AI Dream & Sleep Pattern Analysis',
              onPressed: () => _showSleepPatternAnalysisDialog(ctx, ref, sleeps, moods),
            ),
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
            Column(
              children: [
                _SleepFilterHeader(
                  allSleeps: sleeps,
                  selectedTag: selectedDreamTag,
                  onTagSelected:
                      (tag) =>
                          ref.read(sleepTagFilterProvider.notifier).state = tag,
                  onAnalyzeTap:
                      () => _showSleepPatternAnalysisDialog(
                        ctx,
                        ref,
                        sleeps,
                        moods,
                      ),
                ),
                const Divider(height: 1),
                Expanded(child: _JournalList(rows: sleepRows)),
              ],
            ),
            const MedicationTrackerView(),
          ],
        ),
        floatingActionButton: Builder(
          builder: (tabCtx) {
            return FloatingActionButton(
              onPressed: () {
                final tabIndex = DefaultTabController.of(tabCtx).index;
                if (tabIndex == 1) {
                  showDialog(
                    context: ctx,
                    builder: (_) => const SleepCheckinDialog(),
                  );
                } else if (tabIndex == 2) {
                  Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => const AddEditSubstanceScreen(),
                    ),
                  );
                } else {
                  Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => const MoodCheckInScreen(),
                    ),
                  );
                }
              },
              child: const Icon(Icons.add),
            );
          },
        ),
      ),
    );
  }

  void _showSleepPatternAnalysisDialog(
    BuildContext context,
    WidgetRef ref,
    List<SleepEntry> sleeps,
    List<MoodEntry> moods,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        Future<String>? analysisFuture;
        int windowDays = 30;

        return StatefulBuilder(
          builder: (ctx, setState) {
            final cutoff = DateTime.now().subtract(Duration(days: windowDays));
            final filteredSleeps =
                sleeps.where((s) => s.date.isAfter(cutoff)).toList();
            final filteredMoods =
                moods.where((m) => m.timestamp.isAfter(cutoff)).toList();

            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.nights_stay_outlined),
                  SizedBox(width: 8),
                  Expanded(child: Text('Dream & Sleep AI Insights')),
                ],
              ),
              content: SizedBox(
                width: 380,
                height: analysisFuture != null ? 420 : null,
                child:
                    analysisFuture == null
                        ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Analyze your sleep consistency, recurring dream themes, dream tags, and how they correlate with your next-day mood and active supplements.',
                              style: TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              children: [
                                for (final (days, label) in [
                                  (7, '7 days'),
                                  (30, '30 days'),
                                  (90, '90 days'),
                                  (180, '6 months'),
                                ])
                                  ChoiceChip(
                                    label: Text(label),
                                    selected: windowDays == days,
                                    onSelected: (_) {
                                      setState(() => windowDays = days);
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${filteredSleeps.length} sleep entries (${filteredSleeps.where((s) => s.hasDream).length} with dream logs) in selected window.',
                              style: Theme.of(ctx).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: OutlinedButton.icon(
                                icon: const Icon(
                                  Icons.auto_fix_high_outlined,
                                  size: 16,
                                ),
                                label: const Text('Interpretation Lens'),
                                onPressed: () async {
                                  await showDreamLensDialog(ctx);
                                  setState(() {});
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.auto_awesome),
                                label: const Text('Analyze Sleep & Dreams'),
                                onPressed:
                                    filteredSleeps.isEmpty
                                        ? null
                                        : () async {
                                          final db = ref.read(dbProvider);
                                          final substances = await db
                                              .substancesActiveSince(cutoff);
                                          setState(() {
                                            analysisFuture = GeminiAPI.instance
                                                .analyzeDreamAndSleepPatterns(
                                                  sleeps: filteredSleeps,
                                                  moods: filteredMoods,
                                                  substances: substances,
                                                );
                                          });
                                        },
                              ),
                            ),
                          ],
                        )
                        : FutureBuilder<String>(
                          future: analysisFuture,
                          builder: (ctx, snap) {
                            if (snap.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 16),
                                    Text(
                                      'Analyzing sleep architecture & dream themes…',
                                    ),
                                  ],
                                ),
                              );
                            }
                            if (snap.hasError) {
                              return Text('Error: ${snap.error}');
                            }
                            return SingleChildScrollView(
                              child: MarkdownBody(
                                data: snap.data ?? 'No analysis available.',
                                selectable: true,
                              ),
                            );
                          },
                        ),
              ),
              actions: [
                if (analysisFuture != null)
                  TextButton(
                    onPressed: () => setState(() => analysisFuture = null),
                    child: const Text('Back'),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SleepFilterHeader extends StatelessWidget {
  const _SleepFilterHeader({
    required this.allSleeps,
    required this.selectedTag,
    required this.onTagSelected,
    required this.onAnalyzeTap,
  });

  final List<SleepEntry> allSleeps;
  final String? selectedTag;
  final ValueChanged<String?> onTagSelected;
  final VoidCallback onAnalyzeTap;

  @override
  Widget build(BuildContext context) {
    final dreamCount = allSleeps.where((s) => s.hasDream).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ActionChip(
                  avatar: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('AI Dream Insights'),
                  onPressed: onAnalyzeTap,
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text('All (${allSleeps.length})'),
                  selected: selectedTag == null,
                  onSelected: (_) => onTagSelected(null),
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: Text('With Dreams ($dreamCount)'),
                  selected: selectedTag == '__has_dream__',
                  onSelected:
                      (sel) => onTagSelected(sel ? '__has_dream__' : null),
                ),
                const SizedBox(width: 6),
                for (final tag in kDreamTags) ...[
                  FilterChip(
                    avatar: Icon(tag.icon, size: 14, color: tag.color),
                    label: Text(tag.name),
                    selected: selectedTag == tag.name,
                    selectedColor: tag.color.withValues(alpha: 0.25),
                    onSelected:
                        (sel) => onTagSelected(sel ? tag.name : null),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        ],
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
            vertical: 8,
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
          title:
              row.isSleep && row.sleep != null
                  ? Row(
                    children: [
                      Text(
                        '${row.sleep!.hoursSlept.toStringAsFixed(1)}h',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Quality ${row.sleep!.quality}/5',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            ctx,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      if (row.sleep!.dreamClarity != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '· Clarity ${row.sleep!.dreamClarity}/5',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              ctx,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  )
                  : null,
          subtitle: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              if (row.miniBars.isNotEmpty) MiniBarGraph(row.miniBars),
              if (row.dreamTags.isNotEmpty ||
                  (row.isSleep && (row.sleep?.hasAiChat ?? false))) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    if (row.isSleep && (row.sleep?.hasAiChat ?? false))
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            ctx,
                          ).colorScheme.secondary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 11,
                              color: Theme.of(ctx).colorScheme.secondary,
                            ),
                            const SizedBox(width: 3),
                            const Text(
                              'AI Analyzed',
                              style: TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    for (final tagName in row.dreamTags)
                      Builder(
                        builder: (context) {
                          final def = getDreamTagDef(tagName);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: def.color.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(def.icon, size: 11, color: def.color),
                                const SizedBox(width: 3),
                                Text(
                                  def.name,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ],
              if (row.preview.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    row.preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle:
                          row.preview.startsWith('(')
                              ? FontStyle.italic
                              : null,
                      color:
                          row.preview.startsWith('(')
                              ? Theme.of(
                                ctx,
                              ).colorScheme.onSurface.withValues(alpha: 0.6)
                              : null,
                    ),
                  ),
                ),
            ],
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

class _JournalRow {
  _JournalRow.mood(this.mood, List<CustomMetric> metricDefs)
    : sleep = null,
      date = mood!.timestamp,
      preview = mood.notes?.trim().split('\n').first ?? '',
      dreamTags = const [],
      isSleep = false,
      miniBars = _generateMoodBars(mood, metricDefs);

  _JournalRow.sleep(this.sleep)
    : mood = null,
      date = sleep!.date,
      preview = sleep.dreamPreview,
      dreamTags = sleep.dreamTags,
      isSleep = true,
      miniBars = _generateSleepBars(sleep);

  final MoodEntry? mood;
  final SleepEntry? sleep;
  final DateTime date;
  final String preview;
  final List<String> dreamTags;
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

class SleepDetailScreen extends ConsumerStatefulWidget {
  const SleepDetailScreen({required this.entry, super.key});
  final SleepEntry entry;

  @override
  ConsumerState<SleepDetailScreen> createState() => _SleepDetailScreenState();
}

class _SleepDetailScreenState extends ConsumerState<SleepDetailScreen> {
  final TextEditingController _questionController = TextEditingController();
  bool _isLoadingAi = false;
  String? _transientNotice;
  String _lensLabel = 'Psychological & Sleep Science';

  static const _quickQuestions = [
    'What could the symbols in this dream mean?',
    'Could my active supplements affect this dream?',
    'How does this sleep relate to my recent mood?',
    'Any tips for deeper sleep tonight?',
  ];

  @override
  void initState() {
    super.initState();
    _loadLensLabel();
  }

  Future<void> _loadLensLabel() async {
    final preset = await PrefsService.getDreamLensPreset();
    final custom = await PrefsService.getDreamCustomInstructions();
    if (mounted) {
      setState(() {
        _lensLabel = PrefsService.labelForDreamLens(preset, customText: custom);
      });
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _deleteEntry() async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Delete sleep entry?'),
            content: const Text('This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
    if (ok == true) {
      await ref.read(dbProvider).deleteSleepEntry(widget.entry.id);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _persistChat(
    SleepEntry currentEntry,
    List<DreamChatMessage> updatedChat,
  ) async {
    final parsed = currentEntry.parsedDream.copyWith(aiChat: updatedChat);
    final db = ref.read(dbProvider);
    await db.updateSleepEntry(
      currentEntry.copyWith(dreamJournal: drift.Value(parsed.encode())),
    );
  }

  Future<void> _runAiDreamAnalysis(SleepEntry currentEntry) async {
    if (_isLoadingAi) return;
    setState(() {
      _isLoadingAi = true;
      _transientNotice = null;
    });

    final db = ref.read(dbProvider);
    final since = currentEntry.date.subtract(const Duration(days: 14));
    final recentMoods = await db.moodEntriesSince(since);
    final recentSleeps = await db.sleepEntriesSince(since);
    final activeSubstances = await db.substancesActiveSince(since);

    final result = await GeminiAPI.instance.analyzeDreamEntry(
      entry: currentEntry,
      recentMoods: recentMoods,
      recentSleeps: recentSleeps,
      activeSubstances: activeSubstances,
    );

    if (!mounted) return;

    // Only persist if it's a valid analysis (not the missing API key prompt)
    if (!result.contains('API Key Required') && !result.startsWith('⚠️')) {
      final newChat = [
        DreamChatMessage(
          role: 'model',
          text: result,
          timestamp: DateTime.now(),
        ),
      ];
      await _persistChat(currentEntry, newChat);
    } else {
      setState(() {
        _transientNotice = result;
      });
    }

    if (mounted) {
      setState(() {
        _isLoadingAi = false;
      });
    }
  }

  Future<void> _sendFollowUp(
    SleepEntry currentEntry, [
    String? presetQuestion,
  ]) async {
    final question = (presetQuestion ?? _questionController.text).trim();
    if (question.isEmpty || _isLoadingAi) return;

    _questionController.clear();
    final existingChat = List<DreamChatMessage>.from(
      currentEntry.parsedDream.aiChat,
    );

    final userMsg = DreamChatMessage(
      role: 'user',
      text: question,
      timestamp: DateTime.now(),
    );

    // Save the user's question immediately so it appears in the thread
    final withUserMsg = [...existingChat, userMsg];
    await _persistChat(currentEntry, withUserMsg);

    if (!mounted) return;
    setState(() {
      _isLoadingAi = true;
      _transientNotice = null;
    });

    final db = ref.read(dbProvider);
    final since = currentEntry.date.subtract(const Duration(days: 14));
    final recentMoods = await db.moodEntriesSince(since);
    final recentSleeps = await db.sleepEntriesSince(since);
    final activeSubstances = await db.substancesActiveSince(since);

    final reply = await GeminiAPI.instance.continueDreamChat(
      entry: currentEntry,
      history: existingChat,
      userQuestion: question,
      recentMoods: recentMoods,
      recentSleeps: recentSleeps,
      activeSubstances: activeSubstances,
    );

    if (!mounted) return;

    if (!reply.contains('API Key Required')) {
      final modelMsg = DreamChatMessage(
        role: 'model',
        text: reply,
        timestamp: DateTime.now(),
      );
      await _persistChat(currentEntry, [...withUserMsg, modelMsg]);
    } else {
      setState(() {
        _transientNotice = reply;
      });
    }

    if (mounted) {
      setState(() {
        _isLoadingAi = false;
      });
    }
  }

  Future<void> _clearAiChat(SleepEntry currentEntry) async {
    await _persistChat(currentEntry, const []);
    if (mounted) {
      setState(() {
        _transientNotice = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sleepsAsync = ref.watch(sleepStreamProvider);
    final currentEntry =
        sleepsAsync.value?.firstWhere(
          (s) => s.id == widget.entry.id,
          orElse: () => widget.entry,
        ) ??
        widget.entry;

    final dateFmt = DateFormat.yMMMd().add_jm();
    final dream = currentEntry.parsedDream;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep & Dream Entry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditSleepEntryScreen(entry: currentEntry),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: _deleteEntry,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            dateFmt.format(currentEntry.date),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 12),

          // Summary metric cards
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatBadge(
                icon: Icons.schedule,
                label: 'Hours Slept',
                value: '${currentEntry.hoursSlept.toStringAsFixed(1)} hrs',
                color: Colors.indigo,
              ),
              _StatBadge(
                icon: Icons.star_rounded,
                label: 'Sleep Quality',
                value: sleepQualityLabel(currentEntry.quality),
                color: Colors.green,
              ),
              if (dream.clarity != null)
                _StatBadge(
                  icon: Icons.visibility_outlined,
                  label: 'Dream Recall',
                  value: dreamClarityLabel(dream.clarity!),
                  color: Colors.purple,
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Dream Journal Card
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.nights_stay,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          dream.title ?? 'Dream Journal',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (dream.tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final tagName in dream.tags)
                          Builder(
                            builder: (_) {
                              final def = getDreamTagDef(tagName);
                              return Chip(
                                visualDensity: VisualDensity.compact,
                                avatar: Icon(
                                  def.icon,
                                  size: 15,
                                  color: def.color,
                                ),
                                label: Text(
                                  def.name,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: def.color.withValues(
                                  alpha: 0.15,
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    dream.text.isNotEmpty
                        ? dream.text
                        : 'No dream narrative recorded for this night.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.4,
                      fontStyle:
                          dream.text.isEmpty ? FontStyle.italic : null,
                      color:
                          dream.text.isEmpty
                              ? theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              )
                              : null,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // AI Dream & Sleep Analysis + Follow-up Chat Card
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: theme.colorScheme.secondary,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'AI Dream & Sleep Analysis',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (dream.aiChat.isEmpty)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.auto_awesome, size: 16),
                          label: const Text('Analyze'),
                          onPressed:
                              _isLoadingAi
                                  ? null
                                  : () => _runAiDreamAnalysis(currentEntry),
                        )
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.refresh, size: 20),
                              tooltip: 'Re-analyze from scratch',
                              onPressed:
                                  _isLoadingAi
                                      ? null
                                      : () => _runAiDreamAnalysis(currentEntry),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_sweep_outlined, size: 20),
                              tooltip: 'Clear AI chat',
                              onPressed:
                                  _isLoadingAi
                                      ? null
                                      : () => _clearAiChat(currentEntry),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ActionChip(
                    visualDensity: VisualDensity.compact,
                    avatar: const Icon(Icons.auto_fix_high_outlined, size: 15),
                    label: Text(
                      'Lens: $_lensLabel',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () async {
                      final updated = await showDreamLensDialog(context);
                      if (updated) {
                        await _loadLensLabel();
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  if (dream.aiChat.isEmpty && !_isLoadingAi && _transientNotice == null)
                    Text(
                      'Generate an AI interpretation of this dream & sleep log, saved directly to this entry so you can ask follow-up questions anytime.',
                      style: theme.textTheme.bodySmall,
                    ),

                  if (_transientNotice != null) ...[
                    const SizedBox(height: 8),
                    MarkdownBody(data: _transientNotice!, selectable: true),
                  ],

                  // Retained conversation messages
                  if (dream.aiChat.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    for (int i = 0; i < dream.aiChat.length; i++) ...[
                      _DreamChatBubble(
                        message: dream.aiChat[i],
                        isInitialAnalysis: i == 0 && !dream.aiChat[i].isUser,
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],

                  if (_isLoadingAi)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Thinking…'),
                          ],
                        ),
                      ),
                    ),

                  // Quick follow-up suggestion chips & chat input
                  if (dream.aiChat.isNotEmpty) ...[
                    if (dream.aiChat.length == 1 && !_isLoadingAi) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final q in _quickQuestions)
                            ActionChip(
                              visualDensity: VisualDensity.compact,
                              avatar: const Icon(
                                Icons.chat_bubble_outline,
                                size: 13,
                              ),
                              label: Text(
                                q,
                                style: const TextStyle(fontSize: 11),
                              ),
                              onPressed: () => _sendFollowUp(currentEntry, q),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                    const Divider(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _questionController,
                            enabled: !_isLoadingAi,
                            minLines: 1,
                            maxLines: 3,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendFollowUp(currentEntry),
                            decoration: InputDecoration(
                              hintText:
                                  'Ask a follow-up question about this dream or sleep…',
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          icon: const Icon(Icons.send_rounded, size: 18),
                          tooltip: 'Send follow-up',
                          onPressed:
                              _isLoadingAi
                                  ? null
                                  : () => _sendFollowUp(currentEntry),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Sleep Bar Graph
          SizedBox(
            height: 260,
            child: Padding(
              padding: const EdgeInsets.only(right: 12, bottom: 16),
              child: BarChart(
                BarChartData(
                  maxY: 10,
                  minY: 0,
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY:
                              ((currentEntry.hoursSlept / 12.0) * 10.0).clamp(
                                0.0,
                                10.0,
                              ),
                          width: 72,
                          color: Colors.indigo,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY:
                              ((currentEntry.quality / 5.0) * 10.0).clamp(
                                0.0,
                                10.0,
                              ),
                          width: 72,
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    ),
                    if (dream.clarity != null)
                      BarChartGroupData(
                        x: 2,
                        barRods: [
                          BarChartRodData(
                            toY:
                                ((dream.clarity! / 5.0) * 10.0).clamp(
                                  0.0,
                                  10.0,
                                ),
                            width: 72,
                            color: Colors.purple,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ],
                      ),
                  ],
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 2,
                        getTitlesWidget: (value, _) {
                          final hours = (value * 1.2);
                          return Text(
                            '${hours.toStringAsFixed(0)}h',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 2,
                        getTitlesWidget: (value, _) {
                          const qualityTicks = {
                            0: '0',
                            2: '1',
                            4: '2',
                            6: '3',
                            8: '4',
                            10: '5',
                          };
                          final iv = value.round();
                          if (qualityTicks.containsKey(iv)) {
                            return Text(
                              qualityTicks[iv]!,
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
                        reservedSize: 32,
                        getTitlesWidget: (value, _) {
                          final labels = [
                            'Hours Slept',
                            'Quality',
                            'Dream Clarity',
                          ];
                          final idx = value.toInt();
                          if (idx < 0 || idx >= labels.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              labels[idx],
                              style: const TextStyle(fontSize: 11),
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
        ],
      ),
    );
  }
}

class _DreamChatBubble extends StatelessWidget {
  const _DreamChatBubble({
    required this.message,
    this.isInitialAnalysis = false,
  });

  final DreamChatMessage message;
  final bool isInitialAnalysis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            message.text,
            style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isInitialAnalysis
                ? theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.45,
                )
                : theme.colorScheme.secondaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isInitialAnalysis) ...[
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 13,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Gemini',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          MarkdownBody(data: message.text, selectable: true),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
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
  late double quality;
  late double clarity;
  late bool includeClarity;
  late TextEditingController hoursController;
  late TextEditingController titleController;
  late TextEditingController journalController;
  late Set<String> selectedTags;

  @override
  void initState() {
    super.initState();
    final parsed = widget.entry.parsedDream;
    hours = widget.entry.hoursSlept;
    quality = widget.entry.quality.toDouble();
    clarity = (parsed.clarity ?? 3).toDouble();
    includeClarity = parsed.clarity != null;
    selectedTags = parsed.tags.toSet();
    hoursController = TextEditingController(text: hours.toString());
    titleController = TextEditingController(text: parsed.title ?? '');
    journalController = TextEditingController(text: parsed.text);
  }

  @override
  void dispose() {
    hoursController.dispose();
    titleController.dispose();
    journalController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final parsedHours = double.tryParse(hoursController.text) ?? hours;
    final hasDream =
        titleController.text.trim().isNotEmpty ||
        journalController.text.trim().isNotEmpty ||
        selectedTags.isNotEmpty ||
        includeClarity;

    final existingAiChat = widget.entry.parsedDream.aiChat;
    final encodedDream =
        ParsedDreamJournal(
          title: titleController.text,
          tags: selectedTags.toList(),
          clarity: hasDream && includeClarity ? clarity.toInt() : null,
          text: journalController.text,
          aiChat: existingAiChat,
        ).encode();

    final db = ref.read(dbProvider);
    await db.updateSleepEntry(
      widget.entry.copyWith(
        hoursSlept: parsedHours,
        quality: quality.toInt(),
        dreamJournal: drift.Value(encodedDream),
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Sleep & Dream Entry')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: hoursController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Hours Slept',
              border: OutlineInputBorder(),
            ),
            onChanged: (val) => hours = double.tryParse(val) ?? hours,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sleep Quality', style: theme.textTheme.titleSmall),
              Text(
                sleepQualityLabel(quality.toInt()),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          Slider(
            min: 1,
            max: 5,
            divisions: 4,
            value: quality,
            label: sleepQualityLabel(quality.toInt()),
            onChanged: (val) => setState(() => quality = val),
          ),
          const Divider(height: 24),
          Text('Dream Journal', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          TextFormField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'Dream Title / Theme',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: journalController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Dream Narrative',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text('Dream Characteristics', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in kDreamTags)
                FilterChip(
                  avatar: Icon(tag.icon, size: 15, color: tag.color),
                  label: Text(tag.name),
                  selected: selectedTags.contains(tag.name),
                  selectedColor: tag.color.withValues(alpha: 0.25),
                  onSelected: (sel) {
                    setState(() {
                      if (sel) {
                        selectedTags.add(tag.name);
                        includeClarity = true;
                      } else {
                        selectedTags.remove(tag.name);
                      }
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Track Dream Recall Clarity'),
            value: includeClarity,
            onChanged: (v) => setState(() => includeClarity = v),
          ),
          if (includeClarity) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recall Clarity'),
                Text(
                  dreamClarityLabel(clarity.toInt()),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
            Slider(
              min: 1,
              max: 5,
              divisions: 4,
              value: clarity,
              label: dreamClarityLabel(clarity.toInt()),
              onChanged: (val) => setState(() => clarity = val),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Save Changes'),
          ),
        ],
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
