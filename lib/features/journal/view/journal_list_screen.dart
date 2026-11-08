import 'package:drift/drift.dart' as drift;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

enum JournalDatePreset { all, today, last7, last30, custom }

class JournalListScreen extends ConsumerStatefulWidget {
  const JournalListScreen({super.key});

  @override
  ConsumerState<JournalListScreen> createState() => _JournalListScreenState();
}

class _JournalListScreenState extends ConsumerState<JournalListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchOpen = false;
  String _searchQuery = '';
  JournalDatePreset _datePreset = JournalDatePreset.all;
  DateTimeRange? _customDateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  DateTimeRange? get _effectiveDateRange {
    final now = DateTime.now();
    switch (_datePreset) {
      case JournalDatePreset.all:
        return null;
      case JournalDatePreset.today:
        final start = DateTime(now.year, now.month, now.day);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return DateTimeRange(start: start, end: end);
      case JournalDatePreset.last7:
        final start = DateTime(now.year, now.month, now.day).subtract(
          const Duration(days: 6),
        );
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return DateTimeRange(start: start, end: end);
      case JournalDatePreset.last30:
        final start = DateTime(now.year, now.month, now.day).subtract(
          const Duration(days: 29),
        );
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return DateTimeRange(start: start, end: end);
      case JournalDatePreset.custom:
        return _customDateRange;
    }
  }

  bool _matchesDate(DateTime dt, DateTimeRange? range) {
    if (range == null) return true;
    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
      23,
      59,
      59,
    );
    return !dt.isBefore(start) && !dt.isAfter(end);
  }

  String _datePresetLabel() {
    switch (_datePreset) {
      case JournalDatePreset.all:
        return 'All Time';
      case JournalDatePreset.today:
        return 'Today';
      case JournalDatePreset.last7:
        return 'Last 7 Days';
      case JournalDatePreset.last30:
        return 'Last 30 Days';
      case JournalDatePreset.custom:
        if (_customDateRange != null) {
          final f = DateFormat.MMMd();
          return '${f.format(_customDateRange!.start)} – ${f.format(_customDateRange!.end)}';
        }
        return 'Custom';
    }
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange:
          _customDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: now,
          ),
    );
    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _datePreset = JournalDatePreset.custom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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

    final dateRange = _effectiveDateRange;
    final query = _searchQuery.trim().toLowerCase();

    // ── 1. MOOD ROWS ──
    final filter = ref.watch(journalFilterProvider);
    final metricDefs = ref.watch(customMetricsProvider);
    final moodRows = <_JournalRow>[];

    for (final m in moods) {
      if (!_matchesDate(m.timestamp, dateRange)) continue;
      final hasNote = (m.notes?.trim().isNotEmpty ?? false);
      if (filter == JournalFilter.notesOnly && !hasNote) continue;

      if (query.isNotEmpty) {
        final noteMatch = m.notes?.toLowerCase().contains(query) ?? false;
        final metricMatch =
            m.customMetrics?.keys.any((k) => k.toLowerCase().contains(query)) ??
            false;
        if (!noteMatch && !metricMatch) continue;
      }
      moodRows.add(_JournalRow.mood(m, metricDefs));
    }
    moodRows.sort((a, b) => b.date.compareTo(a.date));

    // ── 2. SLEEP ROWS (Only actual sleep check-ins) ──
    final sleepRows = <_JournalRow>[];
    for (final s in sleeps) {
      if (s.hoursSlept <= 0) continue; // Exclude standalone dream entries
      if (!_matchesDate(s.date, dateRange)) continue;

      if (query.isNotEmpty) {
        final dateStr = DateFormat.yMMMd().format(s.date).toLowerCase();
        final hoursStr = '${s.hoursSlept}';
        if (!dateStr.contains(query) && !hoursStr.contains(query)) continue;
      }
      sleepRows.add(_JournalRow.sleep(s));
    }
    sleepRows.sort((a, b) => b.date.compareTo(a.date));

    // ── 3. DREAM ROWS (Only entries with dreams) ──
    final selectedDreamTag = ref.watch(sleepTagFilterProvider);
    final dreamRows = <_JournalRow>[];
    final allDreamEntries = sleeps.where((s) => s.hasDream).toList();

    for (final s in allDreamEntries) {
      if (!_matchesDate(s.date, dateRange)) continue;
      if (selectedDreamTag != null &&
          !s.dreamTags.contains(selectedDreamTag)) {
        continue;
      }

      if (query.isNotEmpty) {
        final parsed = s.parsedDream;
        final titleMatch = parsed.title?.toLowerCase().contains(query) ?? false;
        final textMatch = parsed.text.toLowerCase().contains(query);
        final tagMatch = parsed.tags.any((t) => t.toLowerCase().contains(query));
        final chatMatch = parsed.aiChat.any(
          (m) => m.text.toLowerCase().contains(query),
        );
        if (!titleMatch && !textMatch && !tagMatch && !chatMatch) continue;
      }
      dreamRows.add(_JournalRow.dream(s));
    }
    dreamRows.sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title:
            _isSearchOpen
                ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search check-ins, dreams, notes…',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                )
                : const Text('Check-Ins & Journals'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mood'),
            Tab(text: 'Sleep'),
            Tab(text: 'Dreams'),
            Tab(text: 'Meds'),
          ],
        ),
        actions: [
          if (_isSearchOpen)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _isSearchOpen = false;
                });
              },
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search',
              onPressed: () => setState(() => _isSearchOpen = true),
            ),
            PopupMenuButton<JournalDatePreset>(
              icon: Icon(
                _datePreset == JournalDatePreset.all
                    ? Icons.calendar_month_outlined
                    : Icons.calendar_month,
                color:
                    _datePreset != JournalDatePreset.all
                        ? Theme.of(context).colorScheme.primary
                        : null,
              ),
              tooltip: 'Filter by Date: ${_datePresetLabel()}',
              onSelected: (preset) {
                if (preset == JournalDatePreset.custom) {
                  _pickCustomRange();
                } else {
                  setState(() => _datePreset = preset);
                }
              },
              itemBuilder:
                  (_) => [
                    const PopupMenuItem(
                      value: JournalDatePreset.all,
                      child: Text('All Time'),
                    ),
                    const PopupMenuItem(
                      value: JournalDatePreset.today,
                      child: Text('Today'),
                    ),
                    const PopupMenuItem(
                      value: JournalDatePreset.last7,
                      child: Text('Last 7 Days'),
                    ),
                    const PopupMenuItem(
                      value: JournalDatePreset.last30,
                      child: Text('Last 30 Days'),
                    ),
                    const PopupMenuItem(
                      value: JournalDatePreset.custom,
                      child: Text('Custom Date Range…'),
                    ),
                  ],
            ),
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              tooltip: 'AI Dream & Sleep Insights',
              onPressed:
                  () => _showSleepPatternAnalysisDialog(
                    context,
                    ref,
                    sleeps,
                    moods,
                  ),
            ),
            if (_tabController.index == 0)
              PopupMenuButton<JournalFilter>(
                icon: const Icon(Icons.filter_list),
                onSelected:
                    (val) =>
                        ref.read(journalFilterProvider.notifier).state = val,
                itemBuilder:
                    (_) => [
                      const PopupMenuItem(
                        value: JournalFilter.all,
                        child: Text('All Mood Entries'),
                      ),
                      const PopupMenuItem(
                        value: JournalFilter.notesOnly,
                        child: Text('Entries With Notes Only'),
                      ),
                    ],
              ),
          ],
        ],
      ),
      body: Column(
        children: [
          if (_datePreset != JournalDatePreset.all || _searchQuery.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              child: Row(
                children: [
                  if (_datePreset != JournalDatePreset.all) ...[
                    InputChip(
                      label: Text('Date: ${_datePresetLabel()}'),
                      onDeleted:
                          () =>
                              setState(() => _datePreset = JournalDatePreset.all),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (_searchQuery.isNotEmpty) ...[
                    InputChip(
                      label: Text('Query: "$_searchQuery"'),
                      onDeleted: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _JournalList(
                  rows: moodRows,
                  emptyText:
                      _searchQuery.isNotEmpty
                          ? 'No mood entries matching "$_searchQuery".'
                          : 'No mood entries found.',
                ),
                _JournalList(
                  rows: sleepRows,
                  emptyText:
                      _searchQuery.isNotEmpty
                          ? 'No sleep entries matching "$_searchQuery".'
                          : 'No sleep entries found.',
                ),
                Column(
                  children: [
                    _DreamFilterHeader(
                      allDreams: allDreamEntries,
                      selectedTag: selectedDreamTag,
                      onTagSelected:
                          (tag) =>
                              ref.read(sleepTagFilterProvider.notifier).state =
                                  tag,
                      onAnalyzeTap:
                          () => _showSleepPatternAnalysisDialog(
                            context,
                            ref,
                            sleeps,
                            moods,
                          ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _JournalList(
                        rows: dreamRows,
                        emptyText:
                            _searchQuery.isNotEmpty
                                ? 'No dreams matching "$_searchQuery".'
                                : 'No dreams recorded yet.',
                      ),
                    ),
                  ],
                ),
                MedicationTrackerView(
                  searchQuery: _searchQuery,
                  dateRange: dateRange,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: switch (_tabController.index) {
          0 => 'Add Mood Check-In',
          1 => 'Add Sleep Check-In',
          2 => 'Add Dream Check-In',
          _ => 'Add Medication',
        },
        onPressed: () {
          switch (_tabController.index) {
            case 0:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MoodCheckInScreen()),
              );
              break;
            case 1:
              showDialog(
                context: context,
                builder: (_) => const SleepCheckinDialog(),
              );
              break;
            case 2:
              showDialog(
                context: context,
                builder: (_) => const DreamCheckinDialog(),
              );
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddEditSubstanceScreen(),
                ),
              );
              break;
          }
        },
        child: const Icon(Icons.add),
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
                              'Analyze your sleep consistency, recurring dream themes, dream tags, and correlations.',
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

class _DreamFilterHeader extends StatelessWidget {
  const _DreamFilterHeader({
    required this.allDreams,
    required this.selectedTag,
    required this.onTagSelected,
    required this.onAnalyzeTap,
  });

  final List<SleepEntry> allDreams;
  final String? selectedTag;
  final ValueChanged<String?> onTagSelected;
  final VoidCallback onAnalyzeTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
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
              label: Text('All Dreams (${allDreams.length})'),
              selected: selectedTag == null,
              onSelected: (_) => onTagSelected(null),
            ),
            const SizedBox(width: 6),
            for (final tag in kDreamTags) ...[
              FilterChip(
                avatar: Icon(tag.icon, size: 14, color: tag.color),
                label: Text(tag.name),
                selected: selectedTag == tag.name,
                selectedColor: tag.color.withValues(alpha: 0.25),
                onSelected: (sel) => onTagSelected(sel ? tag.name : null),
              ),
              const SizedBox(width: 6),
            ],
          ],
        ),
      ),
    );
  }
}

class _JournalList extends StatelessWidget {
  const _JournalList({required this.rows, this.emptyText = 'No entries found.'});

  final List<_JournalRow> rows;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            emptyText,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: rows.length,
      separatorBuilder: (_, __) => const Divider(height: 0),
      itemBuilder: (ctx, i) {
        final row = rows[i];
        final theme = Theme.of(ctx);

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                row.isDream
                    ? Icons.nights_stay
                    : (row.isSleep ? Icons.bedtime : Icons.mood),
                color:
                    row.isDream
                        ? Colors.purple
                        : (row.isSleep
                            ? theme.colorScheme.primary
                            : theme.colorScheme.secondary),
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
              row.isDream
                  ? Row(
                    children: [
                      Expanded(
                        child: Text(
                          row.dreamTitle.isNotEmpty
                              ? row.dreamTitle
                              : 'Dream Entry',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (row.dreamClarity != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Clarity ${row.dreamClarity}/5',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ),
                      ],
                    ],
                  )
                  : (row.isSleep && row.sleep != null
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
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        ],
                      )
                      : null),
          subtitle: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              if (row.miniBars.isNotEmpty) MiniBarGraph(row.miniBars),
              if (row.dreamTags.isNotEmpty ||
                  (row.isDream && (row.sleep?.hasAiChat ?? false))) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    if (row.isDream && (row.sleep?.hasAiChat ?? false))
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withValues(
                            alpha: 0.18,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 11,
                              color: theme.colorScheme.secondary,
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
                        builder: (_) {
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
                          row.preview.startsWith('(') ? FontStyle.italic : null,
                      color:
                          row.preview.startsWith('(')
                              ? theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              )
                              : null,
                    ),
                  ),
                ),
            ],
          ),
          onTap: () {
            if (row.isDream) {
              Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) => DreamDetailScreen(entry: row.sleep!),
                ),
              );
            } else if (row.isSleep) {
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
      dreamTitle = '',
      dreamTags = const [],
      dreamClarity = null,
      isSleep = false,
      isDream = false,
      miniBars = _generateMoodBars(mood, metricDefs);

  _JournalRow.sleep(this.sleep)
    : mood = null,
      date = sleep!.date,
      preview = 'Slept ${sleep.hoursSlept.toStringAsFixed(1)}h · Quality ${sleep.quality}/5',
      dreamTitle = '',
      dreamTags = const [],
      dreamClarity = null,
      isSleep = true,
      isDream = false,
      miniBars = _generateSleepBars(sleep);

  _JournalRow.dream(this.sleep)
    : mood = null,
      date = sleep!.date,
      preview = sleep.dreamPreview,
      dreamTitle = sleep.parsedDream.title ?? '',
      dreamTags = sleep.dreamTags,
      dreamClarity = sleep.dreamClarity,
      isSleep = false,
      isDream = true,
      miniBars = const [];

  final MoodEntry? mood;
  final SleepEntry? sleep;
  final DateTime date;
  final String preview;
  final String dreamTitle;
  final List<String> dreamTags;
  final int? dreamClarity;
  final bool isSleep;
  final bool isDream;
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

// ─────────────────────────────────────────────────────────────────────────────
// DREAM DETAIL SCREEN (Selectable Text, Copy Dream Button, AI Dream Analysis)
// ─────────────────────────────────────────────────────────────────────────────

class DreamDetailScreen extends ConsumerStatefulWidget {
  const DreamDetailScreen({required this.entry, super.key});
  final SleepEntry entry;

  @override
  ConsumerState<DreamDetailScreen> createState() => _DreamDetailScreenState();
}

class _DreamDetailScreenState extends ConsumerState<DreamDetailScreen> {
  final TextEditingController _questionController = TextEditingController();
  bool _isLoadingAi = false;
  String? _transientNotice;
  String _lensLabel = 'Psychological & Sleep Science';

  static const _quickQuestions = [
    'What could the key symbols in this dream mean?',
    'What emotional tone or narrative arc stands out?',
    'How does this reflect my current daytime state or subconscious mind?',
    'Any reflection prompts to explore this dream deeper?',
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

  void _copyDreamToClipboard(SleepEntry entry) {
    final parsed = entry.parsedDream;
    final dateStr = DateFormat.yMMMd().format(entry.date);
    final buffer = StringBuffer();

    if (parsed.title != null && parsed.title!.isNotEmpty) {
      buffer.writeln('Dream: ${parsed.title!} ($dateStr)');
    } else {
      buffer.writeln('Dream Entry ($dateStr)');
    }

    if (parsed.tags.isNotEmpty || parsed.clarity != null) {
      final parts = <String>[];
      if (parsed.tags.isNotEmpty) parts.add('Tags: ${parsed.tags.join(', ')}');
      if (parsed.clarity != null) parts.add('Clarity: ${parsed.clarity}/5');
      buffer.writeln(parts.join(' · '));
    }
    buffer.writeln();

    if (parsed.text.isNotEmpty) {
      buffer.writeln(parsed.text);
    } else {
      buffer.writeln('(No narrative recorded)');
    }

    if (parsed.aiChat.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('--- AI Dream Analysis ---');
      for (final msg in parsed.aiChat) {
        buffer.writeln('${msg.isUser ? 'User' : 'Gemini'}: ${msg.text}');
      }
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    showStyledMedToast(context, message: 'Dream copied to clipboard!');
  }

  Future<void> _deleteEntry() async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Delete dream entry?'),
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

    final result = await GeminiAPI.instance.analyzeDreamEntry(
      entry: currentEntry,
    );

    if (!mounted) return;

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

    final withUserMsg = [...existingChat, userMsg];
    await _persistChat(currentEntry, withUserMsg);

    if (!mounted) return;
    setState(() {
      _isLoadingAi = true;
      _transientNotice = null;
    });

    final reply = await GeminiAPI.instance.continueDreamChat(
      entry: currentEntry,
      history: existingChat,
      userQuestion: question,
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
        title: const Text('Dream Entry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'Copy dream to clipboard',
            onPressed: () => _copyDreamToClipboard(currentEntry),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit dream',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditDreamEntryScreen(entry: currentEntry),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateFmt.format(currentEntry.date),
                style: theme.textTheme.titleMedium,
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.copy, size: 15),
                label: const Text('Copy Dream'),
                onPressed: () => _copyDreamToClipboard(currentEntry),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title & badges
          if (dream.title != null && dream.title!.isNotEmpty) ...[
            SelectableText(
              dream.title!,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
          ],

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (dream.clarity != null)
                _StatBadge(
                  icon: Icons.visibility_outlined,
                  label: 'Dream Recall',
                  value: dreamClarityLabel(dream.clarity!),
                  color: Colors.purple,
                ),
              if (currentEntry.hoursSlept > 0)
                _StatBadge(
                  icon: Icons.bedtime_outlined,
                  label: 'Slept',
                  value: '${currentEntry.hoursSlept.toStringAsFixed(1)} hrs',
                  color: Colors.indigo,
                ),
            ],
          ),

          if (dream.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
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
                        avatar: Icon(def.icon, size: 15, color: def.color),
                        label: Text(
                          def.name,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: def.color.withValues(alpha: 0.15),
                      );
                    },
                  ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          // Dream Journal Narrative Card (Selectable text)
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
                      Row(
                        children: [
                          Icon(
                            Icons.nights_stay,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Dream Narrative',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        tooltip: 'Copy narrative text',
                        onPressed: () {
                          if (dream.text.isNotEmpty) {
                            Clipboard.setData(ClipboardData(text: dream.text));
                            showStyledMedToast(
                              context,
                              message: 'Narrative copied!',
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    dream.text.isNotEmpty
                        ? dream.text
                        : 'No dream narrative recorded for this entry.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      fontStyle: dream.text.isEmpty ? FontStyle.italic : null,
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

          // AI Dream Analysis & Chat
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
                                'AI Dream Interpretation',
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
                          label: const Text('Analyze Dream'),
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
                              icon: const Icon(
                                Icons.delete_sweep_outlined,
                                size: 20,
                              ),
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
                  if (dream.aiChat.isEmpty &&
                      !_isLoadingAi &&
                      _transientNotice == null)
                    Text(
                      'Analyze this dream through your selected lens. The interpretation and any follow-up questions you ask are automatically saved to this entry.',
                      style: theme.textTheme.bodySmall,
                    ),

                  if (_transientNotice != null) ...[
                    const SizedBox(height: 8),
                    MarkdownBody(data: _transientNotice!, selectable: true),
                  ],

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
                              hintText: 'Ask a follow-up about this dream…',
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
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SLEEP DETAIL SCREEN (Hours, Quality, Bar Graph, Edit Sleep Only)
// ─────────────────────────────────────────────────────────────────────────────

class SleepDetailScreen extends ConsumerStatefulWidget {
  const SleepDetailScreen({required this.entry, super.key});
  final SleepEntry entry;

  @override
  ConsumerState<SleepDetailScreen> createState() => _SleepDetailScreenState();
}

class _SleepDetailScreenState extends ConsumerState<SleepDetailScreen> {
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep Entry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit sleep',
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
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
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
                value: '${sleepQualityLabel(currentEntry.quality)} (${currentEntry.quality}/5)',
                color: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sleep Overview',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 220,
                    child: BarChart(
                      BarChartData(
                        maxY: 10,
                        minY: 0,
                        barGroups: [
                          BarChartGroupData(
                            x: 0,
                            barRods: [
                              BarChartRodData(
                                toY: ((currentEntry.hoursSlept / 12.0) * 10.0)
                                    .clamp(0.0, 10.0),
                                width: 56,
                                color: Colors.indigo,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 1,
                            barRods: [
                              BarChartRodData(
                                toY: ((currentEntry.quality / 5.0) * 10.0).clamp(
                                  0.0,
                                  10.0,
                                ),
                                width: 56,
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ],
                          ),
                        ],
                        gridData: const FlGridData(show: true),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 34,
                              interval: 2,
                              getTitlesWidget: (v, _) => Text(
                                '${(v * 1.2).toStringAsFixed(0)}h',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (value, _) {
                                final label = value.toInt() == 0 ? 'Hours' : 'Quality';
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(label, style: const TextStyle(fontSize: 11)),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EditDreamEntryScreen extends ConsumerStatefulWidget {
  const EditDreamEntryScreen({required this.entry, super.key});
  final SleepEntry entry;

  @override
  ConsumerState<EditDreamEntryScreen> createState() =>
      _EditDreamEntryScreenState();
}

class _EditDreamEntryScreenState extends ConsumerState<EditDreamEntryScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _journalController;
  late double _clarity;
  late Set<String> _selectedTags;

  @override
  void initState() {
    super.initState();
    final parsed = widget.entry.parsedDream;
    _titleController = TextEditingController(text: parsed.title ?? '');
    _journalController = TextEditingController(text: parsed.text);
    _clarity = (parsed.clarity ?? 3).toDouble();
    _selectedTags = parsed.tags.toSet();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _journalController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final existingChat = widget.entry.parsedDream.aiChat;
    final encodedDream = ParsedDreamJournal(
      title: _titleController.text,
      tags: _selectedTags.toList(),
      clarity: _clarity.toInt(),
      text: _journalController.text,
      aiChat: existingChat,
    ).encode();

    final db = ref.read(dbProvider);
    await db.updateSleepEntry(
      widget.entry.copyWith(dreamJournal: drift.Value(encodedDream)),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Dream')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Dream Title / Theme',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _journalController,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Dream Narrative',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Characteristics', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in kDreamTags)
                FilterChip(
                  avatar: Icon(tag.icon, size: 14, color: tag.color),
                  label: Text(tag.name),
                  selected: _selectedTags.contains(tag.name),
                  selectedColor: tag.color.withValues(alpha: 0.25),
                  onSelected: (sel) {
                    setState(() {
                      if (sel) {
                        _selectedTags.add(tag.name);
                      } else {
                        _selectedTags.remove(tag.name);
                      }
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recall Clarity'),
              Text(
                dreamClarityLabel(_clarity.toInt()),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Slider(
            min: 1,
            max: 5,
            divisions: 4,
            value: _clarity,
            label: dreamClarityLabel(_clarity.toInt()),
            onChanged: (v) => setState(() => _clarity = v),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Save Dream Changes'),
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
  late TextEditingController hoursController;

  @override
  void initState() {
    super.initState();
    hours = widget.entry.hoursSlept;
    quality = widget.entry.quality.toDouble();
    hoursController = TextEditingController(text: hours.toString());
  }

  @override
  void dispose() {
    hoursController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final parsedHours = double.tryParse(hoursController.text) ?? hours;
    final db = ref.read(dbProvider);
    await db.updateSleepEntry(
      widget.entry.copyWith(
        hoursSlept: parsedHours,
        quality: quality.toInt(),
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Sleep Entry')),
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
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Save Sleep Changes'),
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
          child: SelectableText(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
              IconButton(
                icon: const Icon(Icons.copy, size: 14),
                tooltip: 'Copy response',
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: message.text));
                  showStyledMedToast(context, message: 'Response copied!');
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
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
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
        ),
      ),
    );
  }
}
