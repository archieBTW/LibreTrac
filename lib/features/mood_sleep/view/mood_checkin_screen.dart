import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libretrac/features/home/view/home_screen.dart';
import 'package:libretrac/features/mood_sleep/view/streak_dialog.dart';
import 'package:libretrac/services/mood_widget_service.dart';
import 'package:libretrac/services/streak_popup_service.dart';
import '../../../core/database/app_database.dart';
import '../../../providers/db_provider.dart';
import 'package:intl/intl.dart';

class MoodCheckInScreen extends ConsumerStatefulWidget {
  final bool onboarding;
  const MoodCheckInScreen({super.key, this.onboarding = false});

  @override
  ConsumerState<MoodCheckInScreen> createState() => _MoodCheckInScreenState();
}

class _MoodCheckInScreenState extends ConsumerState<MoodCheckInScreen> {
  Map<String, int> _moodValues = {};

  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final customMetrics = ref.read(customMetricsProvider);
    _moodValues = {for (final metric in customMetrics) metric.name: 5};

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.onboarding) {
        _showOnboardingDialog();
      }
    });
  }

  void _showOnboardingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            title: const Text('Time to Check In'),
            content: const Text(
              'Now that your mood metrics are set, take a moment to reflect and log how you’re feeling today. '
              'Move each slider to match your current state, and add any notes if you’d like.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Got it'),
              ),
            ],
          ),
    );
  }

  void _submitMood() async {
    final db = ref.read(dbProvider);

    await db
        .into(db.moodEntries)
        .insert(
          MoodEntriesCompanion.insert(
            timestamp: DateTime.now(),
            customMetrics: drift.Value(_moodValues),
            notes: drift.Value(
              _notesController.text.isEmpty ? null : _notesController.text,
            ),
          ),
        );

    ref.invalidate(journalEntriesStreamProvider);
    ref.invalidate(moodEntriesStreamProvider);
    ref.invalidate(filteredMoodEntriesProvider);
    ref.invalidate(weeklyMoodAverageProvider);
    ref.invalidate(weeklyMoodMetricAveragesProvider);

    await MoodWidgetService.update();

    final shown = await StreakService.hasShownToday();
    if (!shown) {
      final streak = await StreakService.updateStreak();
      await StreakService.markShownToday();

      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (_) => StreakDialog(streakCount: streak),
        );
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Mood entry saved!')));

      if (widget.onboarding) {
        await showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                title: const Text('🎉 All Done!'),
                content: const Text(
                  'You’ve completed your first check-in! LibreTrac is now ready to help you track your mental clarity, rest, and overall well-being each day.',
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Let’s Go!'),
                  ),
                ],
              ),
        );

        await OnboardingPrefs.markComplete();

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateFormat.yMMMMd().add_jm().format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Check-In'),
        automaticallyImplyLeading: !widget.onboarding,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('Today: $now', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            ...ref.watch(customMetricsProvider).map((metric) {
              final name = metric.name;
              final color = metric.color;
              final value = _moodValues.putIfAbsent(name, () => 5);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$name: $value'),
                  Slider(
                    value: value.toDouble(),
                    min: 0,
                    max: 10,
                    divisions: 10,
                    label: value.toString(),
                    activeColor: color,
                    onChanged: (v) {
                      setState(() => _moodValues[name] = v.round());
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              );
            }),

            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Optional Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _submitMood,
              icon: const Icon(Icons.check),
              label: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
