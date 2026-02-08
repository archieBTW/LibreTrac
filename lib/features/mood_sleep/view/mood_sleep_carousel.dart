import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libretrac/core/database/app_database.dart';
import 'package:libretrac/features/mood_sleep/view/mood_chart_page.dart';
import 'package:libretrac/features/mood_sleep/view/sleep_chart_page.dart';
import 'package:libretrac/features/profile/view/profile_view.dart';
import 'package:libretrac/features/shared/onboard/onboard_card.dart';
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

  @override
  Widget build(BuildContext context) {
    final cutoff = window.since;
    final mood = orderedMood.where((e) => e.timestamp.isAfter(cutoff)).toList();
    final sleepsW =
        sleepEntries.where((e) => e.createdAt.isAfter(cutoff)).toList();

    final hasMood = true; // mood.length > 2;
    final hasSleep = true; // sleepsW.length > 2;

    final showMoodOverlay = mood.length <= 1;

    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileView()),
          ),
      child: SizedBox(
        height: 350,
        child: Stack(
          children: [
            PageView(
              physics: const TighterPageScrollPhysics(),
              pageSnapping: true, // default, keeps the snap
              controller: PageController(
                viewportFraction: 1.0, // full-width pages
              ), // padEnds
              children: [
                if (hasMood)
                  MoodChartPage(
                    ordered: mood,
                    selectedMetrics: selectedMetrics,
                    // moodColors: moodColors,
                    allMetrics: allMetrics, //ref.watch(customMetricsProvider),
                    onMetricToggle: onMetricToggle,
                    customMetrics: customMetrics,
                    window: window,
                  )
                else
                  const OnboardCard(
                    icon: Icons.sentiment_satisfied_alt,
                    text: 'Keep checking in daily to see your mood trends!',
                  ),
                if (hasSleep)
                  SleepChartPage(entries: sleepsW)
                else
                  const OnboardCard(
                    icon: Icons.bedtime,
                    text:
                        'Log your sleep for at least 3 nights to unlock trends!',
                  ),
              ],
            ),
            if (showMoodOverlay)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.sentiment_satisfied_alt,
                        color: Colors.white,
                        size: 48,
                      ),
                      SizedBox(height: 16),
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Check in daily to unlock mood insights!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
