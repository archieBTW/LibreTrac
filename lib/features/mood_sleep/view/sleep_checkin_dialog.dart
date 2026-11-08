import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libretrac/core/database/app_database.dart';
import 'package:libretrac/features/mood_sleep/model/dream_metadata.dart';
import 'package:libretrac/providers/db_provider.dart';

/// Standalone Sleep Check-In Dialog (Hours Slept + Sleep Quality only).
class SleepCheckinDialog extends ConsumerStatefulWidget {
  const SleepCheckinDialog({super.key});

  @override
  ConsumerState<SleepCheckinDialog> createState() => _SleepCheckinDialogState();
}

class _SleepCheckinDialogState extends ConsumerState<SleepCheckinDialog> {
  final _formKey = GlobalKey<FormState>();
  final _hours = TextEditingController(text: '7.5');
  double _quality = 3;

  static const _quickHours = [6.0, 7.0, 7.5, 8.0, 9.0];

  @override
  void dispose() {
    _hours.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.bedtime_outlined),
          SizedBox(width: 8),
          Expanded(child: Text('Sleep Check-In')),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _hours,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Hours slept',
                    suffixText: 'hrs',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) {
                    final parsed = double.tryParse(v ?? '');
                    if (parsed == null || parsed <= 0 || parsed > 24) {
                      return 'Enter valid hours (0.5 – 24)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final h in _quickHours)
                      ActionChip(
                        visualDensity: VisualDensity.compact,
                        label: Text(
                          h == h.roundToDouble() ? '${h.toInt()}h' : '${h}h',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () {
                          setState(() {
                            _hours.text =
                                h == h.roundToDouble()
                                    ? h.toInt().toString()
                                    : h.toString();
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Sleep quality', style: theme.textTheme.titleSmall),
                    Text(
                      sleepQualityLabel(_quality.toInt()),
                      style: theme.textTheme.bodySmall?.copyWith(
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
                  value: _quality,
                  label: sleepQualityLabel(_quality.toInt()),
                  onChanged: (v) => setState(() => _quality = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            final db = ref.read(dbProvider);
            await db.insertSleep(
              SleepEntriesCompanion.insert(
                date: DateTime.now(),
                hoursSlept: double.parse(_hours.text),
                quality: drift.Value(_quality.toInt()),
                dreamJournal: const drift.Value(null),
              ),
            );
            if (mounted) Navigator.pop(context);
          },
          child: const Text('Save Sleep'),
        ),
      ],
    );
  }
}

/// Standalone Dream Check-In Dialog (Dream Title, Narrative, Characteristics, Clarity only — no sleep input required).
class DreamCheckinDialog extends ConsumerStatefulWidget {
  const DreamCheckinDialog({super.key});

  @override
  ConsumerState<DreamCheckinDialog> createState() => _DreamCheckinDialogState();
}

class _DreamCheckinDialogState extends ConsumerState<DreamCheckinDialog> {
  final _formKey = GlobalKey<FormState>();
  final _dreamTitle = TextEditingController();
  final _dreams = TextEditingController();
  double _dreamClarity = 3;
  final Set<String> _selectedTags = {};

  @override
  void dispose() {
    _dreamTitle.dispose();
    _dreams.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.nights_stay_outlined),
          SizedBox(width: 8),
          Expanded(child: Text('Dream Check-In')),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _dreamTitle,
                  decoration: const InputDecoration(
                    labelText: 'Dream title / theme',
                    hintText: 'e.g., Flying over crystal mountains',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dreams,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Dream narrative & symbols',
                    hintText:
                        'What happened? How did it feel? Any recurring people or symbols?',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if ((v == null || v.trim().isEmpty) &&
                        _dreamTitle.text.trim().isEmpty &&
                        _selectedTags.isEmpty) {
                      return 'Please enter a dream narrative, title, or tag';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  'Dream characteristics',
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final tag in kDreamTags)
                      FilterChip(
                        visualDensity: VisualDensity.compact,
                        avatar: Icon(tag.icon, size: 14, color: tag.color),
                        label: Text(
                          tag.name,
                          style: const TextStyle(fontSize: 12),
                        ),
                        selected: _selectedTags.contains(tag.name),
                        selectedColor: tag.color.withValues(alpha: 0.25),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTags.add(tag.name);
                            } else {
                              _selectedTags.remove(tag.name);
                            }
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dream recall clarity',
                      style: theme.textTheme.labelMedium,
                    ),
                    Text(
                      dreamClarityLabel(_dreamClarity.toInt()),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Slider(
                  min: 1,
                  max: 5,
                  divisions: 4,
                  value: _dreamClarity,
                  label: dreamClarityLabel(_dreamClarity.toInt()),
                  onChanged: (v) {
                    setState(() {
                      _dreamClarity = v;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            final encodedDream =
                ParsedDreamJournal(
                  title: _dreamTitle.text,
                  tags: _selectedTags.toList(),
                  clarity: _dreamClarity.toInt(),
                  text: _dreams.text,
                ).encode();

            final db = ref.read(dbProvider);
            await db.insertSleep(
              SleepEntriesCompanion.insert(
                date: DateTime.now(),
                hoursSlept: 0.0,
                quality: const drift.Value(3),
                dreamJournal: drift.Value(encodedDream),
              ),
            );
            if (mounted) Navigator.pop(context);
          },
          child: const Text('Save Dream'),
        ),
      ],
    );
  }
}
