import 'dart:async';
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

  MedicationDoseLog copyWith({
    DateTime? takenAt,
    String? note,
    bool clearNote = false,
  }) {
    return MedicationDoseLog(
      id: id,
      substanceId: substanceId,
      substanceName: substanceName,
      dosage: dosage,
      takenAt: takenAt ?? this.takenAt,
      note: clearNote ? null : (note ?? this.note),
    );
  }

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
    final subName = (json['substanceName'] ??
            json['substance'] ??
            json['substance_name'] ??
            'Unknown')
        .toString();
    final rawSubId = json['substanceId'] ?? json['substance_id'];
    final subId = (rawSubId is num)
        ? rawSubId.toInt()
        : (int.tryParse('$rawSubId') ?? 0);
    final rawTime = json['takenAt'] ?? json['taken_at'];
    final taken = parseDateTime(rawTime) ?? DateTime.now();
    final rawId =
        json['id']?.toString() ?? '${subId}_${taken.microsecondsSinceEpoch}';

    return MedicationDoseLog(
      id: rawId,
      substanceId: subId,
      substanceName: subName,
      dosage: json['dosage']?.toString(),
      takenAt: taken,
      note: json['note']?.toString(),
    );
  }
}

/// Shared provider for medication sort order across SubstanceListScreen and MedicationTrackerView.
final substanceOrderProvider =
    StateNotifierProvider<SubstanceOrderNotifier, List<int>>((ref) {
      return SubstanceOrderNotifier();
    });

class SubstanceOrderNotifier extends StateNotifier<List<int>> {
  static const prefsKey = 'substanceOrder';

  SubstanceOrderNotifier() : super(const []) {
    _load();
  }

  Future<void> reload() => _load();

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(prefsKey);
    if (raw == null) {
      state = const [];
      return;
    }
    state = raw.map((e) => int.tryParse(e)).whereType<int>().toList();
  }

  Future<void> setOrder(List<int> ids) async {
    state = ids;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(prefsKey, ids.map((e) => e.toString()).toList());
  }

  List<Substance> sortSubstances(List<Substance> original) {
    if (state.isEmpty) return [...original];
    final indexOf = <int, int>{
      for (var i = 0; i < state.length; i++) state[i]: i,
    };
    return [...original]..sort(
      (a, b) => (indexOf[a.id] ?? 99999).compareTo(indexOf[b.id] ?? 99999),
    );
  }
}

/// Stores how many times per day each medication is scheduled to be taken (default: 1).
final medicationDosesPerDayProvider =
    StateNotifierProvider<MedicationDosesPerDayNotifier, Map<int, int>>((ref) {
      return MedicationDosesPerDayNotifier();
    });

class MedicationDosesPerDayNotifier extends StateNotifier<Map<int, int>> {
  static const prefsKey = 'medication_doses_per_day';

  MedicationDosesPerDayNotifier() : super(const {}) {
    _load();
  }

  Future<void> reload() => _load();

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefsKey);
    if (raw == null || raw.isEmpty) {
      state = const {};
      return;
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      state = {
        for (final entry in decoded.entries)
          if (int.tryParse(entry.key) != null)
            int.parse(entry.key): (entry.value as num).toInt().clamp(1, 12),
      };
    } catch (_) {
      state = const {};
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final map = {for (final e in state.entries) e.key.toString(): e.value};
    await prefs.setString(prefsKey, jsonEncode(map));
  }

  int dosesFor(int substanceId) => state[substanceId] ?? 1;

  Future<void> setDosesPerDay(int substanceId, int count) async {
    final copy = Map<int, int>.from(state);
    copy[substanceId] = count.clamp(1, 12);
    state = copy;
    await _save();
  }
}

final medicationDoseLogsProvider =
    StateNotifierProvider<MedicationDoseNotifier, List<MedicationDoseLog>>((
      ref,
    ) {
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
    List<dynamic>? rawList;

    // 1. Try reading as JSON string
    final raw = prefs.getString(prefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) rawList = decoded;
      } catch (_) {}
    }

    // 2. Fallback: try reading as StringList
    if (rawList == null) {
      final listRaw = prefs.getStringList(prefsKey);
      if (listRaw != null && listRaw.isNotEmpty) {
        rawList = [];
        for (final item in listRaw) {
          try {
            rawList.add(jsonDecode(item));
          } catch (_) {
            rawList.add(item);
          }
        }
      }
    }

    if (rawList == null || rawList.isEmpty) {
      state = const [];
      return;
    }

    try {
      final logs = <MedicationDoseLog>[];
      for (final item in rawList) {
        if (item is Map) {
          logs.add(MedicationDoseLog.fromJson(Map<String, dynamic>.from(item)));
        }
      }
      logs.sort((a, b) => b.takenAt.compareTo(a.takenAt));
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

  Future<void> updateLog(
    String id, {
    required DateTime takenAt,
    String? note,
  }) async {
    final cleanNote = (note != null && note.trim().isNotEmpty) ? note.trim() : null;
    final updated = [
      for (final item in state)
        if (item.id == id)
          item.copyWith(
            takenAt: takenAt,
            note: cleanNote,
            clearNote: cleanNote == null,
          )
        else
          item,
    ]..sort((a, b) => b.takenAt.compareTo(a.takenAt));
    state = updated;
    await _save();
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

/// Styled, auto-dismissing floating toast for medication actions.
/// Explicitly hides itself after 2.8 seconds so `SnackBarAction` never prevents auto-dismissal on web/mobile.
void showStyledMedToast(
  BuildContext context, {
  required String message,
  VoidCallback? onUndo,
}) {
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  final theme = Theme.of(context);

  messenger.clearSnackBars();
  final controller = messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      backgroundColor: theme.colorScheme.inverseSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      duration: const Duration(milliseconds: 2800),
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: theme.colorScheme.onInverseSurface,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          if (onUndo != null)
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.amberAccent,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                messenger.hideCurrentSnackBar();
                onUndo();
              },
              child: const Text(
                'UNDO',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
        ],
      ),
    ),
  );

  Timer(const Duration(milliseconds: 2800), () {
    try {
      controller.close();
    } catch (_) {}
  });
}

/// Dialog to log a new dose at a custom date/time with an optional note.
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
    final entry = await ref
        .read(medicationDoseLogsProvider.notifier)
        .logDose(
          substance: substance,
          takenAt: selectedDateTime,
          note: noteController.text,
        );
    if (context.mounted) {
      showStyledMedToast(
        context,
        message:
            'Logged ${substance.name} at ${timeFmt.format(entry.takenAt)}',
        onUndo: () {
          ref.read(medicationDoseLogsProvider.notifier).deleteLog(entry.id);
        },
      );
    }
    return entry;
  }
  return null;
}

/// Dialog to edit the timestamp or note of an existing logged dose, or delete it.
Future<void> showEditDoseDialog(
  BuildContext context,
  WidgetRef ref,
  MedicationDoseLog log,
) async {
  DateTime selectedDateTime = log.takenAt;
  final noteController = TextEditingController(text: log.note ?? '');
  final dateFmt = DateFormat.yMMMd();
  final timeFmt = DateFormat.jm();

  final action = await showDialog<String>(
    context: context,
    builder: (dialogCtx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.edit_calendar_outlined),
                const SizedBox(width: 8),
                Expanded(child: Text('Edit ${log.substanceName} Dose')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Time Taken:',
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
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton.icon(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                  size: 18,
                ),
                label: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onPressed: () => Navigator.pop(dialogCtx, 'delete'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, 'cancel'),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogCtx, 'save'),
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );

  if (action == 'delete') {
    await ref.read(medicationDoseLogsProvider.notifier).deleteLog(log.id);
    if (context.mounted) {
      showStyledMedToast(
        context,
        message: 'Removed ${log.substanceName} dose log',
      );
    }
  } else if (action == 'save') {
    await ref
        .read(medicationDoseLogsProvider.notifier)
        .updateLog(
          log.id,
          takenAt: selectedDateTime,
          note: noteController.text,
        );
    if (context.mounted) {
      showStyledMedToast(
        context,
        message:
            'Updated ${log.substanceName} time to ${timeFmt.format(selectedDateTime)}',
      );
    }
  }
}

/// Interactive row of individual dose markers for a medication on a given day.
/// Shows one marker per scheduled daily dose (e.g. Dose 1, Dose 2, Dose 3) plus any extra logged doses.
/// Tapping an untaken marker logs that dose; tapping a taken marker opens the edit-time dialog!
class DailyDoseMarkersRow extends ConsumerWidget {
  const DailyDoseMarkersRow({
    required this.substance,
    required this.todayLogs,
    required this.dosesPerDay,
    super.key,
  });

  final Substance substance;
  final List<MedicationDoseLog> todayLogs;
  final int dosesPerDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeFmt = DateFormat.jm();
    final totalSlots =
        todayLogs.length > dosesPerDay ? todayLogs.length : dosesPerDay;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (int i = 0; i < totalSlots; i++)
          if (i < todayLogs.length)
            // Taken slot — tap to edit time or delete!
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => showEditDoseDialog(context, ref, todayLogs[i]),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      totalSlots > 1
                          ? 'Dose ${i + 1}: ${timeFmt.format(todayLogs[i].takenAt)}'
                          : 'Taken ${timeFmt.format(todayLogs[i].takenAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.edit, size: 12, color: Colors.green),
                  ],
                ),
              ),
            )
          else
            // Untaken scheduled slot — tap to mark taken now!
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () async {
                final entry = await ref
                    .read(medicationDoseLogsProvider.notifier)
                    .logDose(substance: substance);
                if (context.mounted) {
                  showStyledMedToast(
                    context,
                    message:
                        'Logged ${substance.name} (Dose ${i + 1}) at ${timeFmt.format(entry.takenAt)}',
                    onUndo: () {
                      ref
                          .read(medicationDoseLogsProvider.notifier)
                          .deleteLog(entry.id);
                    },
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.radio_button_unchecked,
                      size: 16,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      totalSlots > 1 ? 'Take Dose ${i + 1}' : 'Take Now',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

        // Button to log an additional dose or custom time
        ActionChip(
          visualDensity: VisualDensity.compact,
          avatar: const Icon(Icons.more_time, size: 14),
          label: const Text('Custom Time', style: TextStyle(fontSize: 11)),
          onPressed: () => showLogDoseDialog(context, ref, substance),
        ),
      ],
    );
  }
}

/// Widget showing a 7-day adherence lookback strip for a single medication,
/// highlighting which days it was taken (including multi-dose counts) and which days were missed.
class SevenDayAdherenceStrip extends ConsumerWidget {
  const SevenDayAdherenceStrip({
    required this.substance,
    required this.logs,
    super.key,
  });

  final Substance substance;
  final List<MedicationDoseLog> logs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dosesPerDay =
        ref.watch(medicationDosesPerDayProvider)[substance.id] ?? 1;
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
            final takenCount = dayLogs.length;
            final fullyTaken = takenCount >= dosesPerDay;
            final partiallyTaken = takenCount > 0 && takenCount < dosesPerDay;
            final isToday = isSameCalendarDay(day, today);
            final wasActiveOnDay =
                !day.isBefore(startDay) &&
                (stopDay == null || !day.isAfter(stopDay));
            final isMissed = takenCount == 0 && !isToday && wasActiveOnDay;

            final Color bgColor;
            final Color iconColor;
            final IconData icon;

            if (fullyTaken) {
              bgColor = Colors.green.withValues(alpha: 0.18);
              iconColor = Colors.green;
              icon = Icons.check_circle;
            } else if (partiallyTaken) {
              bgColor = Colors.amber.withValues(alpha: 0.2);
              iconColor = Colors.amber.shade700;
              icon = Icons.timelapse;
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
                takenCount > 0
                    ? '${DateFormat.MMMd().format(day)} ($takenCount/$dosesPerDay): ${dayLogs.map((l) => DateFormat.jm().format(l.takenAt)).join(', ')}'
                    : (isMissed
                        ? '${DateFormat.MMMd().format(day)}: Missed'
                        : (isToday
                            ? 'Today: 0/$dosesPerDay logged'
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
                    child:
                        dosesPerDay > 1 && takenCount > 0
                            ? Center(
                              child: Text(
                                '$takenCount/$dosesPerDay',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: iconColor,
                                ),
                              ),
                            )
                            : Icon(icon, size: 18, color: iconColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    takenCount > 0
                        ? DateFormat('h:mma')
                            .format(dayLogs.last.takenAt)
                            .toLowerCase()
                        : (isMissed ? 'Missed' : ''),
                    style: TextStyle(
                      fontSize: 9,
                      color:
                          fullyTaken
                              ? Colors.green
                              : (partiallyTaken
                                  ? Colors.amber.shade700
                                  : Colors.redAccent),
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
/// Supports optional searchQuery and dateRange filtering.
class MedicationTrackerView extends ConsumerWidget {
  const MedicationTrackerView({
    this.searchQuery = '',
    this.dateRange,
    super.key,
  });

  final String searchQuery;
  final DateTimeRange? dateRange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAsync = ref.watch(activeSubstancesStreamProvider);
    final allLogs = ref.watch(medicationDoseLogsProvider);
    final dosesMap = ref.watch(medicationDosesPerDayProvider);
    ref.watch(substanceOrderProvider);
    final orderNotifier = ref.read(substanceOrderProvider.notifier);

    final now = DateTime.now();
    final dateTimeFmt = DateFormat.yMMMd().add_jm();
    final q = searchQuery.trim().toLowerCase();

    return activeAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (rawMeds) {
        final orderedMeds = orderNotifier.sortSubstances(rawMeds);
        final activeMeds =
            q.isEmpty
                ? orderedMeds
                : orderedMeds
                    .where(
                      (m) =>
                          m.name.toLowerCase().contains(q) ||
                          (m.dosage?.toLowerCase().contains(q) ?? false) ||
                          (m.notes?.toLowerCase().contains(q) ?? false),
                    )
                    .toList();

        final filteredLogs =
            allLogs.where((log) {
              if (dateRange != null) {
                final start = DateTime(
                  dateRange!.start.year,
                  dateRange!.start.month,
                  dateRange!.start.day,
                );
                final end = DateTime(
                  dateRange!.end.year,
                  dateRange!.end.month,
                  dateRange!.end.day,
                  23,
                  59,
                  59,
                );
                if (log.takenAt.isBefore(start) || log.takenAt.isAfter(end)) {
                  return false;
                }
              }
              if (q.isNotEmpty) {
                final matchesName = log.substanceName.toLowerCase().contains(q);
                final matchesDose =
                    log.dosage?.toLowerCase().contains(q) ?? false;
                final matchesNote =
                    log.note?.toLowerCase().contains(q) ?? false;
                if (!matchesName && !matchesDose && !matchesNote) return false;
              }
              return true;
            }).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today’s Medications (${DateFormat.MMMd().format(now)})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (activeMeds.isNotEmpty && q.isEmpty)
                  TextButton.icon(
                    icon: const Icon(Icons.swap_vert, size: 16),
                    label: const Text(
                      'Reorder',
                      style: TextStyle(fontSize: 12),
                    ),
                    onPressed:
                        () => _showReorderDialog(context, ref, orderedMeds),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (activeMeds.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No matching active medications or supplements.',
                  ),
                ),
              )
            else
              for (final med in activeMeds)
                Builder(
                  builder: (ctx) {
                    final dosesPerDay = dosesMap[med.id] ?? 1;
                    final medLogs =
                        allLogs
                            .where((l) => l.substanceId == med.id)
                            .toList();
                    final todayLogs =
                        medLogs
                            .where((l) => isSameCalendarDay(l.takenAt, now))
                            .toList()
                          ..sort((a, b) => a.takenAt.compareTo(b.takenAt));

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Text(
                                        med.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (med.dosage != null &&
                                          med.dosage!.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          med.dosage!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                ActionChip(
                                  visualDensity: VisualDensity.compact,
                                  label: Text(
                                    '${todayLogs.length}/$dosesPerDay today ($dosesPerDay×/day)',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  onPressed:
                                      () => _showDosesPerDayDialog(
                                        ctx,
                                        ref,
                                        med,
                                        dosesPerDay,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            DailyDoseMarkersRow(
                              substance: med,
                              todayLogs: todayLogs,
                              dosesPerDay: dosesPerDay,
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
              'Dose Timestamp History (Tap any entry to edit time)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (filteredLogs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No medication doses found.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              for (final log in filteredLogs.take(60))
                Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    dense: true,
                    onTap: () => showEditDoseDialog(context, ref, log),
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: 'Edit time taken',
                          onPressed:
                              () => showEditDoseDialog(context, ref, log),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          tooltip: 'Delete log entry',
                          onPressed: () {
                            ref
                                .read(medicationDoseLogsProvider.notifier)
                                .deleteLog(log.id);
                            showStyledMedToast(
                              context,
                              message: 'Removed ${log.substanceName} dose log',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }

  Future<void> _showDosesPerDayDialog(
    BuildContext context,
    WidgetRef ref,
    Substance med,
    int currentDoses,
  ) async {
    int selected = currentDoses;
    final result = await showDialog<int>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: Text('${med.name} Daily Frequency'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('How many times per day do you take this?'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (int n = 1; n <= 6; n++)
                        ChoiceChip(
                          label: Text('${n}× / day'),
                          selected: selected == n,
                          onSelected: (_) => setState(() => selected = n),
                        ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogCtx, selected),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      await ref
          .read(medicationDosesPerDayProvider.notifier)
          .setDosesPerDay(med.id, result);
    }
  }

  Future<void> _showReorderDialog(
    BuildContext context,
    WidgetRef ref,
    List<Substance> currentItems,
  ) async {
    final items = [...currentItems];
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Reorder Medications'),
              content: SizedBox(
                width: 340,
                height: 360,
                child: ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  itemCount: items.length,
                  onReorder: (oldIndex, newIndex) {
                    if (newIndex > oldIndex) newIndex -= 1;
                    setState(() {
                      final moved = items.removeAt(oldIndex);
                      items.insert(newIndex, moved);
                    });
                    ref
                        .read(substanceOrderProvider.notifier)
                        .setOrder(items.map((e) => e.id).toList());
                  },
                  itemBuilder: (ctx, i) {
                    final s = items[i];
                    return ListTile(
                      key: ValueKey(s.id),
                      contentPadding: EdgeInsets.zero,
                      leading: ReorderableDragStartListener(
                        index: i,
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.drag_handle),
                        ),
                      ),
                      title: Text(s.name),
                      subtitle: s.dosage != null ? Text(s.dosage!) : null,
                    );
                  },
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Done'),
                ),
              ],
            );
          },
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
