import 'package:flutter/material.dart';
import 'package:libretrac/core/database/app_database.dart';
import 'package:libretrac/features/mood_sleep/view/mood_chart_page.dart';
import 'package:libretrac/features/mood_sleep/view/sleep_chart_page.dart';
import 'package:libretrac/features/profile/view/profile_view.dart';
import 'package:libretrac/features/shared/physics/scroll_physics.dart';
import 'package:libretrac/providers/db_provider.dart';

class MoodSleepCarousel extends StatelessWidget {
  const MoodSleepCarousel({
    required this.moodEntries,
    required this.sleepEntries,
    required this.orderedMood,
    required this.selectedMetrics,
    required this.moodColors,
    required this.allMetrics,
    required this.onMetricToggle,
    required this.customMetrics,
    required this.window,
    this.isDesktop = false,
    super.key,
  });

  final List<MoodEntry> moodEntries;
  final List<SleepEntry> sleepEntries;
  final List<MoodEntry> orderedMood;
  final Set<String> selectedMetrics;
  final List<CustomMetric>? customMetrics;

  final Map<String, Color> moodColors;
  final List<CustomMetric> allMetrics;
  final void Function(String metric, bool isSelected) onMetricToggle;
  final MoodWindow window;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final cutoff = window.since;
    final mood = orderedMood.where((e) => e.timestamp.isAfter(cutoff)).toList();
    final sleepsW =
        sleepEntries
            .where((e) => e.date.isAfter(cutoff) || e.createdAt.isAfter(cutoff))
            .toList();

    final showMoodOverlay = mood.isEmpty;
    final showSleepOverlay = sleepsW.isEmpty;

    Widget buildMoodSection() {
      return Stack(
        children: [
          MoodChartPage(
            ordered: mood,
            selectedMetrics: selectedMetrics,
            allMetrics: allMetrics,
            onMetricToggle: onMetricToggle,
            customMetrics: customMetrics,
            window: window,
          ),
          if (showMoodOverlay)
            _buildOverlay(
              context,
              icon: Icons.sentiment_satisfied_alt,
              text: 'Check in to see your mood insights!',
            ),
        ],
      );
    }

    Widget buildSleepSection() {
      return Stack(
        children: [
          SleepChartPage(entries: sleepsW),
          if (showSleepOverlay)
            _buildOverlay(
              context,
              icon: Icons.bedtime,
              text: 'Log your sleep to see your sleep & dream trends!',
            ),
        ],
      );
    }

    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileView()),
          ),
      child: SizedBox(
        height: isDesktop ? 450 : 350,
        child: isDesktop
            ? Row(
                children: [
                  Expanded(child: buildMoodSection()),
                  const SizedBox(width: 24),
                  Expanded(child: buildSleepSection()),
                ],
              )
            : PageView(
                physics: const TighterPageScrollPhysics(),
                pageSnapping: true,
                controller: PageController(
                  viewportFraction: 1.0,
                ),
                children: [
                  buildMoodSection(),
                  buildSleepSection(),
                ],
              ),
      ),
    );
  }

  Widget _buildOverlay(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    return Positioned.fill(
      child: Container(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.78),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.onSurface,
              size: 48,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
