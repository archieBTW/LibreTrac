import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:libretrac/core/database/app_database.dart';
import 'package:libretrac/providers/db_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MedicationDoseLog {
  final String id;
  final int substanceId;
  final String substanceName;
  final String? dosage;
  final DateTime takenAt;
  final String? note;

  const MedicationDoseLog({
    required this.id,
    required this.substanceId,
    required this.substanceName,
    this.dosage,
    required this.takenAt,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'substanceId': substanceId,
    'substanceName': substanceName,
    if (dosage != null) 'dosage': dosage,
    'takenAt': takenAt.toIso8601String(),
    if (note != null && note!.isNotEmpty) 'note': note,
  };

  Map<String, dynamic> toExportJson() => {
    'substance': substanceName,
    if (dosage != null) 'dosage': dosage,
    'takenAt': DateFormat('yyyy-MM-dd HH:mm').format(takenAt),
    if (note != null && note!.isNotEmpty) 'note': note,
  };

  factory MedicationDoseLog.fromJson(Map<String, dynamic> json) {
    return MedicationDoseLog(
      id: (json['id'] as String?) ??
          '${json['substanceId']}_${json['takenAt']}',
      substanceId: (json['substanceId'] as num?)?.toInt() ?? 0,
      substanceName: (json['substanceName'] as String?) ?? 'Unknown',
      dosage: json['dosage'] as String?,
      takenAt:
          DateTime.tryParse((json['takenAt'] as String?) ?? '') ??
          DateTime.now(),
      note: json['note'] as String?,
    );
  }
}

final medicationDoseLogsProvider = StateNotifierProvider<
  MedicationDoseNotifier,
  List<MedicationDoseLog>
>((ref) {
  return MedicationDoseNotifier();
});

class MedicationDoseNotifier extends StateNotifier<List<MedicationDoseLog>> {
  static const prefsKey = 'medication_dose_logs';

  MedicationDoseNotifier() : super(const []) {
    _load();
  }

  Future<void> reload() => _load();

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefsKey);
    if (raw == null || raw.isEmpty) {
      state = const [];
      return;
    }
    try {
      final list = jsonDecode(raw) as List;
      final logs =
          list
              .whereType<Map<String, dynamic>>()
              .map(MedicationDoseLog.fromJson)
              .toList()
            ..sort((a, b) => b.takenAt.compareTo(a.takenAt));
      state = logs;
    } catch (_) {
      state = const [];
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(state.map((e) => e.toJson()).toList());
    await prefs.setString(prefsKey, encoded);
  }

  Future<MedicationDoseLog> logDose({
    required Substance substance,
    DateTime? takenAt,
    String? note,
  }) async {
    final timestamp = takenAt ?? DateTime.now();
    final entry = MedicationDoseLog(
      id: '${substance.id}_${timestamp.microsecondsSinceEpoch}',
      substanceId: substance.id,
      substanceName: substance.name,
      dosage: substance.dosage,
      takenAt: timestamp,
      note: note?.trim().isEmpty == true ? null : note?.trim(),
    );
    final updated = [entry, ...state]
      ..sort((a, b) => b.takenAt.compareTo(a.takenAt));
    state = updated;
    await _save();
    return entry;
  }

  Future<void> deleteLog(String id) async {
    state = state.where((e) => e.id != id).toList();
    await _save();
  }

  Future<void> clearAllForSubstance(int substanceId) async {
    state = state.where((e) => e.substanceId != substanceId).toList();
    await _save();
  }
}

bool isSameCalendarDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Helper dialog to log a dose either right now or at a custom date/time with an optional note.
Future<MedicationDoseLog?> showLogDoseDialog(
  BuildContext context,
  WidgetRef ref,
  Substance substance,
) async {
  DateTime selectedDateTime = DateTime.now();
  final noteController = TextEditingController();
  final dateFmt = DateFormat.yMMMd();
  final timeFmt = DateFormat.jm();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.medication_outlined),
                const SizedBox(width: 8),
                Expanded(child: Text('Log ${substance.name}')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (substance.dosage != null && substance.dosage!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Dosage: ${substance.dosage}',
                      style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const Text(
                  'Timestamp:',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          dateFmt.format(selectedDateTime),
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDateTime,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(
                              const Duration(days: 1),
                            ),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              selectedDateTime = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                selectedDateTime.hour,
                                selectedDateTime.minute,
                              );
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time, size: 16),
                        label: Text(
                          timeFmt.format(selectedDateTime),
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () async {
                          final pickedTime = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.fromDateTime(
                              selectedDateTime,
                            ),
                          );
                          if (pickedTime != null) {
                            setState(() {
                              selectedDateTime = DateTime(
                                selectedDateTime.year,
                                selectedDateTime.month,
                                selectedDateTime.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    hintText: 'e.g., Taken with breakfast',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Save Dose'),
                onPressed: () => Navigator.pop(dialogCtx, true),
              ),
            ],
          );
        },
      );
    },
  );

  if (confirmed == true) {
    return ref
        .read(medicationDoseLogsProvider.notifier)
        .logDose(
          substance: substance,
          takenAt: selectedDateTime,
          note: noteController.text,
        );
  }
  return null;
}

/// Widget showing a 7-day adherence lookback strip for a single medication,
/// highlighting which days it was taken (with times) and which days were missed.
class SevenDayAdherenceStrip extends StatelessWidget {
  const SevenDayAdherenceStrip({
    required this.substance,
    required this.logs,
    super.key,
  });

  final Substance substance;
  final List<MedicationDoseLog> logs;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDay = DateTime(
      substance.addedAt.year,
      substance.addedAt.month,
      substance.addedAt.day,
    );
    final stopDay =
        substance.stoppedAt != null
            ? DateTime(
              substance.stoppedAt!.year,
              substance.stoppedAt!.month,
              substance.stoppedAt!.day,
            )
            : null;

    final days = [
      for (int i = 6; i >= 0; i--) today.subtract(Duration(days: i)),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children:
          days.map((day) {
            final dayLogs =
                logs.where((l) => isSameCalendarDay(l.takenAt, day)).toList()
                  ..sort((a, b) => a.takenAt.compareTo(b.takenAt));
            final taken = dayLogs.isNotEmpty;
            final isToday = isSameCalendarDay(day, today);
            final wasActiveOnDay =
                !day.isBefore(startDay) &&
                (stopDay == null || !day.isAfter(stopDay));
            final isMissed = !taken && !isToday && wasActiveOnDay;

            final Color bgColor;
            final Color iconColor;
            final IconData icon;

            if (taken) {
              bgColor = Colors.green.withValues(alpha: 0.18);
              iconColor = Colors.green;
              icon = Icons.check_circle;
            } else if (isMissed) {
              bgColor = Colors.redAccent.withValues(alpha: 0.15);
              iconColor = Colors.redAccent;
              icon = Icons.cancel_outlined;
            } else if (isToday && wasActiveOnDay) {
              bgColor = Colors.amber.withValues(alpha: 0.18);
              iconColor = Colors.amber.shade700;
              icon = Icons.schedule;
            } else {
              bgColor = Colors.grey.withValues(alpha: 0.1);
              iconColor = Colors.grey;
              icon = Icons.remove;
            }

            final tooltipMsg =
                taken
                    ? '${DateFormat.MMMd().format(day)}: Taken at ${dayLogs.map((l) => DateFormat.jm().format(l.takenAt)).join(', ')}'
                    : (isMissed
                        ? '${DateFormat.MMMd().format(day)}: Missed'
                        : (isToday
                            ? 'Today: Not logged yet'
                            : '${DateFormat.MMMd().format(day)}: Inactive'));

            return Tooltip(
              message: tooltipMsg,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isToday ? 'Today' : DateFormat.E().format(day),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                      border:
                          isToday
                              ? Border.all(color: iconColor, width: 1.5)
                              : null,
                    ),
                    child: Icon(icon, size: 18, color: iconColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    taken
                        ? DateFormat('h:mma')
                            .format(dayLogs.last.takenAt)
                            .toLowerCase()
                        : (isMissed ? 'Missed' : ''),
                    style: TextStyle(
                      fontSize: 9,
                      color: taken ? Colors.green : Colors.redAccent,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }
}

/// Full-featured Medication Check-in & Adherence History view (usable as a tab or standalone screen).
class MedicationTrackerView extends ConsumerWidget {
  const MedicationTrackerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAsync = ref.watch(activeSubstancesStreamProvider);
    final allLogs = ref.watch(medicationDoseLogsProvider);
    final now = DateTime.now();
    final timeFmt = DateFormat.jm();
    final dateTimeFmt = DateFormat.yMMMd().add_jm();

    return activeAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (activeMeds) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Today's Active Medications Checklist
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today’s Medications (${DateFormat.MMMd().format(now)})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (activeMeds.isNotEmpty)
                  Text(
                    '${activeMeds.where((m) => allLogs.any((l) => l.substanceId == m.id && isSameCalendarDay(l.takenAt, now))).length}/${activeMeds.length} taken',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (activeMeds.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No active medications or supplements. Add them in Medications/Supplements to track daily doses.',
                  ),
                ),
              )
            else
              for (final med in activeMeds)
                Builder(
                  builder: (ctx) {
                    final medLogs =
                        allLogs
                            .where((l) => l.substanceId == med.id)
                            .toList();
                    final todayLogs =
                        medLogs
                            .where((l) => isSameCalendarDay(l.takenAt, now))
                            .toList()
                          ..sort((a, b) => a.takenAt.compareTo(b.takenAt));
                    final takenToday = todayLogs.isNotEmpty;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  takenToday
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color:
                                      takenToday ? Colors.green : Colors.amber,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        med.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (med.dosage != null &&
                                          med.dosage!.isNotEmpty)
                                        Text(
                                          med.dosage!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      const SizedBox(height: 2),
                                      Text(
                                        takenToday
                                            ? 'Taken today at ${todayLogs.map((l) => timeFmt.format(l.takenAt)).join(', ')}'
                                            : 'Not logged yet today',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              takenToday
                                                  ? Colors.green
                                                  : Colors.orangeAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_calendar_outlined),
                                  tooltip: 'Log custom time',
                                  onPressed:
                                      () => showLogDoseDialog(ctx, ref, med),
                                ),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.check, size: 16),
                                  label: Text(takenToday ? 'Take +1' : 'Take Now'),
                                  onPressed: () async {
                                    final entry = await ref
                                        .read(
                                          medicationDoseLogsProvider.notifier,
                                        )
                                        .logDose(substance: med);
                                    if (ctx.mounted) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Logged ${med.name} at ${timeFmt.format(entry.takenAt)}',
                                          ),
                                          action: SnackBarAction(
                                            label: 'Undo',
                                            onPressed: () {
                                              ref
                                                  .read(
                                                    medicationDoseLogsProvider
                                                        .notifier,
                                                  )
                                                  .deleteLog(entry.id);
                                            },
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            SevenDayAdherenceStrip(
                              substance: med,
                              logs: medLogs,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

            const SizedBox(height: 20),
            Text(
              'Recent Dose Timestamp History',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (allLogs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No medication doses logged yet.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              for (final log in allLogs.take(50))
                Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.medication_liquid,
                      color: Colors.teal,
                    ),
                    title: Text(
                      '${log.substanceName}${log.dosage != null && log.dosage!.isNotEmpty ? ' (${log.dosage})' : ''}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${dateTimeFmt.format(log.takenAt)}${log.note != null ? '\nNote: ${log.note}' : ''}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      tooltip: 'Delete log entry',
                      onPressed: () {
                        ref
                            .read(medicationDoseLogsProvider.notifier)
                            .deleteLog(log.id);
                      },
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}

class MedicationTrackerScreen extends StatelessWidget {
  const MedicationTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medication Dose Tracker')),
      body: const MedicationTrackerView(),
    );
  }
}

