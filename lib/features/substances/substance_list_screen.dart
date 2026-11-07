import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:libretrac/core/database/app_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const _prefsKey = 'substanceOrder';
  bool _showPast = false;
  List<int> _savedOrder = [];

  @override
  void initState() {
    super.initState();
    _loadSavedOrder();
  }

  Future<void> _loadSavedOrder() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedOrder =
          prefs.getStringList(_prefsKey)?.map(int.parse).toList() ?? [];
    });
  }

  Future<void> _saveOrder(List<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, ids.map((e) => e.toString()).toList());
  }

  List<Substance> _sorted(List<Substance> original) {
    if (_savedOrder.isEmpty) return original;

    final indexOf = <int, int>{
      for (var i = 0; i < _savedOrder.length; i++) _savedOrder[i]: i,
    };

    final sorted = [...original]..sort(
      (a, b) => (indexOf[a.id] ?? 99999).compareTo(indexOf[b.id] ?? 99999),
    );
    return sorted;
  }

  @override
  Widget build(BuildContext ctx) {
    final substances = ref.watch(
      _showPast ? pastSubstancesStreamProvider : activeSubstancesStreamProvider,
    );
    final allLogs = ref.watch(medicationDoseLogsProvider);

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
          final items = _sorted(list);

          if (_showPast) {
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder:
                  (_, i) => _tile(
                    ctx,
                    items[i],
                    allLogs: allLogs,
                    allNames: items.map((e) => e.name).toList(),
                    deletable: true,
                    permaDeletable: true,
                  ),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 32.0),
            child: ReorderableListView.builder(
              itemCount: items.length,
              proxyDecorator: _proxyDecorator,
              onReorder: (oldIndex, newIndex) async {
                if (newIndex > oldIndex) newIndex -= 1;

                setState(() {
                  final item = items.removeAt(oldIndex);
                  items.insert(newIndex, item);
                  _savedOrder = items.map((e) => e.id).toList();
                });
                await _saveOrder(_savedOrder);
              },
              itemBuilder:
                  (_, i) => _tile(
                    ctx,
                    items[i],
                    allLogs: allLogs,
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
    required List<MedicationDoseLog> allLogs,
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

    return ListTile(
      key: key,
      leading:
          !permaDeletable
              ? IconButton(
                tooltip:
                    takenToday
                        ? 'Taken today · Tap to log another dose'
                        : 'Tap to mark taken now',
                icon: Icon(
                  takenToday
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: takenToday ? Colors.green : Colors.amber,
                ),
                onPressed: () async {
                  final entry = await ref
                      .read(medicationDoseLogsProvider.notifier)
                      .logDose(substance: s);
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Logged ${s.name} at ${timeFmt.format(entry.takenAt)}',
                        ),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () {
                            ref
                                .read(medicationDoseLogsProvider.notifier)
                                .deleteLog(entry.id);
                          },
                        ),
                      ),
                    );
                  }
                },
              )
              : const Icon(Icons.history),
      title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (s.dosage != null && s.dosage!.isNotEmpty) Text(s.dosage!),
          if (!permaDeletable)
            Text(
              takenToday
                  ? '✓ Taken today at ${todayLogs.map((l) => timeFmt.format(l.takenAt)).join(', ')}'
                  : (medLogs.isNotEmpty
                      ? 'Not logged today · Last: ${DateFormat.MMMd().add_jm().format(medLogs.first.takenAt)}'
                      : 'Not logged yet today'),
              style: TextStyle(
                fontSize: 12,
                color: takenToday ? Colors.green : Colors.grey,
                fontWeight: takenToday ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
        ],
      ),
      trailing:
          deletable
              ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!permaDeletable)
                    IconButton(
                      icon: const Icon(Icons.more_time, size: 20),
                      tooltip: 'Log dose at custom time',
                      onPressed: () => showLogDoseDialog(ctx, ref, s),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
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
                                    onPressed: () => Navigator.pop(ctx, false),
                                  ),
                                  TextButton(
                                    child: const Text('Delete'),
                                    onPressed: () => Navigator.pop(ctx, true),
                                  ),
                                ],
                              ),
                        );

                        if (confirm == true) {
                          await ref.read(substanceRepoProvider).delete(s.id);
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
              )
              : null,
      onTap:
          () => Navigator.push(
            ctx,
            MaterialPageRoute(
              builder:
                  (_) =>
                      SubstanceDetailScreen(substance: s, substances: allNames),
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
