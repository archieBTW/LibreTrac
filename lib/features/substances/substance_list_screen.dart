import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:libretrac/core/database/app_database.dart';

import 'package:libretrac/features/substances/add_edit_substance_screen.dart';
import 'package:libretrac/features/substances/model/medication_dose_log.dart';
import 'package:libretrac/features/substances/substance_detail_screen.dart';
import 'package:libretrac/providers/db_provider.dart';

class SubstanceListScreen extends ConsumerStatefulWidget {
  const SubstanceListScreen({super.key});

  @override
  ConsumerState<SubstanceListScreen> createState() =>
      _SubstanceListScreenState();
}

class _SubstanceListScreenState extends ConsumerState<SubstanceListScreen> {
  bool _showPast = false;

  @override
  Widget build(BuildContext ctx) {
    final substances = ref.watch(
      _showPast ? pastSubstancesStreamProvider : activeSubstancesStreamProvider,
    );
    final allLogs = ref.watch(medicationDoseLogsProvider);
    final savedOrder = ref.watch(substanceOrderProvider);
    final dosesPerDayMap = ref.watch(medicationDosesPerDayProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medications / Supplements'),
        actions: [
          IconButton(
            tooltip: 'Dose Log & Adherence Tracker',
            icon: const Icon(Icons.event_available),
            onPressed:
                () => Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => const MedicationTrackerScreen(),
                  ),
                ),
          ),
          IconButton(
            tooltip: _showPast ? 'Show current' : 'Show past',
            icon: Icon(_showPast ? Icons.history_toggle_off : Icons.history),
            onPressed: () => setState(() => _showPast = !_showPast),
          ),
        ],
      ),
      body: substances.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (list) {
          final items =
              ref.read(substanceOrderProvider.notifier).sortSubstances(list);

          if (_showPast) {
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder:
                  (_, i) => _tile(
                    ctx,
                    items[i],
                    index: i,
                    allLogs: allLogs,
                    dosesPerDay: (dosesPerDayMap[items[i].id] ?? 1).clamp(1, 6),
                    allNames: items.map((e) => e.name).toList(),
                    deletable: true,
                    permaDeletable: true,
                  ),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 32.0),
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: items.length,
              proxyDecorator: _proxyDecorator,
              onReorder: (oldIndex, newIndex) async {
                if (newIndex > oldIndex) newIndex -= 1;
                final updated = [...items];
                final item = updated.removeAt(oldIndex);
                updated.insert(newIndex, item);
                await ref
                    .read(substanceOrderProvider.notifier)
                    .setOrder(updated.map((e) => e.id).toList());
              },
              itemBuilder:
                  (_, i) => _tile(
                    ctx,
                    items[i],
                    index: i,
                    allLogs: allLogs,
                    dosesPerDay: (dosesPerDayMap[items[i].id] ?? 1).clamp(1, 6),
                    allNames: items.map((e) => e.name).toList(),
                    key: ValueKey(items[i].id),
                  ),
            ),
          );
        },
      ),
      floatingActionButton:
          _showPast
              ? null
              : FloatingActionButton(
                onPressed:
                    () => Navigator.push(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => const AddEditSubstanceScreen(),
                      ),
                    ),
                child: const Icon(Icons.add),
              ),
    );
  }

  Widget _tile(
    BuildContext ctx,
    Substance s, {
    required int index,
    required List<MedicationDoseLog> allLogs,
    required int dosesPerDay,
    required List<String> allNames,
    bool deletable = true,
    bool permaDeletable = false,
    Key? key,
  }) {
    final now = DateTime.now();
    final timeFmt = DateFormat.jm();
    final medLogs = allLogs.where((l) => l.substanceId == s.id).toList();
    final todayLogs =
        medLogs.where((l) => isSameCalendarDay(l.takenAt, now)).toList()
          ..sort((a, b) => a.takenAt.compareTo(b.takenAt));
    final takenToday = todayLogs.isNotEmpty;
    final allDosesComplete = todayLogs.length >= dosesPerDay;

    return Card(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              allDosesComplete
                  ? Colors.green.withValues(alpha: 0.35)
                  : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap:
            () => Navigator.push(
              ctx,
              MaterialPageRoute(
                builder:
                    (_) => SubstanceDetailScreen(
                      substance: s,
                      substances: allNames,
                    ),
              ),
            ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (!permaDeletable)
                    ReorderableDragStartListener(
                      index: index,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.drag_indicator,
                          size: 20,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.history, size: 20),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                s.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            if (dosesPerDay > 1) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(ctx)
                                      .colorScheme
                                      .primaryContainer
                                      .withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${todayLogs.length}/$dosesPerDay today',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(
                                          ctx,
                                        ).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (s.dosage != null && s.dosage!.isNotEmpty)
                          Text(
                            s.dosage!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (deletable)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!permaDeletable)
                          IconButton(
                            icon: const Icon(Icons.more_time, size: 20),
                            tooltip: 'Log dose at custom time',
                            onPressed: () => showLogDoseDialog(ctx, ref, s),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          tooltip:
                              permaDeletable
                                  ? 'Permanently delete'
                                  : 'Move to past medications',
                          onPressed: () async {
                            if (permaDeletable) {
                              final confirm = await showDialog<bool>(
                                context: ctx,
                                builder:
                                    (_) => AlertDialog(
                                      title: const Text('Permanently delete?'),
                                      content: const Text(
                                        'This will completely remove the substance and its history. Are you sure?',
                                      ),
                                      actions: [
                                        TextButton(
                                          child: const Text('Cancel'),
                                          onPressed:
                                              () => Navigator.pop(ctx, false),
                                        ),
                                        TextButton(
                                          child: const Text('Delete'),
                                          onPressed:
                                              () => Navigator.pop(ctx, true),
                                        ),
                                      ],
                                    ),
                              );

                              if (confirm == true) {
                                await ref
                                    .read(substanceRepoProvider)
                                    .delete(s.id);
                                await ref
                                    .read(medicationDoseLogsProvider.notifier)
                                    .clearAllForSubstance(s.id);
                              }
                            } else {
                              await ref.read(substanceRepoProvider).stop(s.id);
                            }
                          },
                        ),
                      ],
                    ),
                ],
              ),
              if (!permaDeletable) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 32, right: 4),
                  child: DailyDoseMarkersRow(
                    substance: s,
                    todayLogs: todayLogs,
                    dosesPerDay: dosesPerDay,
                  ),
                ),
                if (!takenToday && medLogs.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 32, top: 4),
                    child: Text(
                      'Last taken: ${DateFormat.MMMd().add_jm().format(medLogs.first.takenAt)}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  )
                else if (takenToday)
                  Padding(
                    padding: const EdgeInsets.only(left: 32, top: 4),
                    child: Text(
                      'Tap any taken dose marker above to edit time (${todayLogs.map((l) => timeFmt.format(l.takenAt)).join(', ')})',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Widget _proxyDecorator(
    Widget child,
    int index,
    Animation<double> animation,
  ) {
    return Material(
      elevation: 6,
      color: Colors.transparent,
      child: Opacity(opacity: 0.95, child: child),
    );
  }
}
