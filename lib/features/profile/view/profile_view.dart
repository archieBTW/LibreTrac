import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:libretrac/features/cognitive/model/cog_test_kind.dart';
import 'package:libretrac/providers/db_provider.dart';

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  bool editing = false;
  late TextEditingController nameController;
  late TextEditingController bloodTypeController;
  late TextEditingController birthdayController;
  late TextEditingController heightController;
  late TextEditingController weightController;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);
    nameController = TextEditingController(text: profile.username);
    bloodTypeController = TextEditingController(text: profile.bloodType ?? '');
    birthdayController = TextEditingController(text: profile.birthday ?? '');
    heightController = TextEditingController(text: profile.height ?? '');
    weightController = TextEditingController(text: profile.weight ?? '');
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      ref.read(userProfileProvider.notifier).setPicturePath(picked.path);
    }
  }

  void _toggleEdit() {
    if (editing) {
      // Save changes
      final name = nameController.text.trim();
      final bloodType = bloodTypeController.text.trim();
      final birthday = birthdayController.text.trim();
      final height = heightController.text.trim();
      final weight = weightController.text.trim();

      if (name.isNotEmpty) {
        ref.read(userProfileProvider.notifier).setUsername(name);
      }
      ref.read(userProfileProvider.notifier).setBloodType(bloodType);
      ref.read(userProfileProvider.notifier).setBirthday(birthday);
      ref.read(userProfileProvider.notifier).setHeight(height);
      ref.read(userProfileProvider.notifier).setWeight(weight);
    } else {
      // Entering edit mode — update fields with latest profile data
      final profile = ref.read(userProfileProvider);
      nameController.text = profile.username;
      bloodTypeController.text = profile.bloodType ?? '';
      birthdayController.text = profile.birthday ?? '';
      heightController.text = profile.height ?? '';
      weightController.text = profile.weight ?? '';
    }

    setState(() => editing = !editing);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final streak = ref.watch(streakCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Profile"),
        actions: [
          IconButton(
            icon: Icon(editing ? Icons.check : Icons.edit),
            onPressed: _toggleEdit,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                GestureDetector(
                  onTap: editing ? _pickImage : null,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage:
                        profile.profilePicturePath != null
                            ? (kIsWeb
                                ? NetworkImage(profile.profilePicturePath!)
                                    as ImageProvider
                                : FileImage(File(profile.profilePicturePath!)))
                            : null,
                    child:
                        profile.profilePicturePath == null
                            ? const Icon(Icons.person, size: 50)
                            : null,
                  ),
                ),
                if (editing)
                  const CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.edit, size: 16),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            child:
                editing
                    ? SizedBox(
                      width: 200,
                      child: TextField(
                        controller: nameController,
                        textAlign: TextAlign.left,
                        decoration: const InputDecoration(
                          labelText: "Username",
                        ),
                      ),
                    )
                    : Text(
                      profile.username,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
          ),
          const SizedBox(height: 24),
          if (editing)
            Column(
              children: [
                const SizedBox(height: 8),
                TextField(
                  controller: birthdayController,
                  decoration: const InputDecoration(labelText: "Birthday"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: heightController,
                  decoration: const InputDecoration(
                    labelText: "Height (e.g. 5'10\")",
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: weightController,
                  decoration: const InputDecoration(
                    labelText: "Weight (e.g. 132 lbs)",
                  ),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // if (profile.bloodType?.isNotEmpty ?? false)
                // Text('🩸 Blood Type: ${profile.bloodType}'),
                if (profile.birthday?.isNotEmpty ?? false)
                  Text('🎂 Birthday: ${profile.birthday}'),
                if (profile.height?.isNotEmpty ?? false)
                  Text('📏 Height: ${profile.height}'),
                if (profile.weight?.isNotEmpty ?? false)
                  Text('⚖️ Weight: ${profile.weight}'),
              ],
            ),

          const SizedBox(height: 16),
          streak.when(
            data:
                (count) => Container(
                  child: Text(
                    '🔥 Current Streak: $count day${count == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 32),

          const Divider(height: 40),
          const Text(
            '📈 Weekly Mood Averages',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const WeeklyMoodBarChart(),

          const SizedBox(height: 32),
          const Text(
            '😴 Sleep Stats (Last 7 Days)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Consumer(
            builder: (context, ref, _) {
              final sleep = ref.watch(weeklySleepStatsProvider);
              return sleep.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text("Error loading sleep data"),
                data: (data) {
                  if (data.entryCount == 0) {
                    return const Text("No sleep data this week");
                  }
                  final avg = data.avgDuration;
                  final hours = avg;
                  // final mins = avg.inMinutes.remainder(60);
                  return Text(
                    "Average: ${hours}h of sleep over ${data.entryCount} nights",
                    style: Theme.of(context).textTheme.bodyMedium,
                  );
                },
              );
            },
          ),
          const SizedBox(height: 32),
          const Text(
            '🧠 Cognitive Test Best Scores',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Consumer(
            builder: (context, ref, _) {
              final scores = ref.watch(cognitiveTopScoresProvider);
              return scores.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text("Failed to load test scores"),
                data:
                    (map) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          map.entries
                              .map(
                                (e) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Text('${e.key.label}: ${e.value}'),
                                ),
                              )
                              .toList(),
                    ),
              );
            },
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class WeeklyMoodBarChart extends ConsumerWidget {
  const WeeklyMoodBarChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final averages = ref.watch(weeklyMoodMetricAveragesProvider);
    final customMetrics = ref.watch(customMetricsProvider);

    return averages.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text("Error loading mood data"),
      data: (avgMap) {
        if (avgMap.isEmpty) {
          return const Text("No mood data this week");
        }

        final barGroups = <BarChartGroupData>[];
        final labels = <String>[];

        int i = 0;
        for (final entry in avgMap.entries) {
          final metricName = entry.key;
          final average = entry.value;

          final color =
              customMetrics
                  .firstWhere(
                    (m) => m.name.toLowerCase() == metricName.toLowerCase(),
                    orElse:
                        () =>
                            CustomMetric(name: metricName, color: Colors.grey),
                  )
                  .color;

          barGroups.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: average,
                  color: color,
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          );
          labels.add(metricName);
          i++;
        }

        return SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              maxY: 10,
              barGroups: barGroups,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, _) {
                      final index = value.toInt();
                      if (index < labels.length) {
                        return Text(
                          labels[index],
                          style: const TextStyle(fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ),
              gridData: FlGridData(show: true),
              borderData: FlBorderData(show: false),
            ),
          ),
        );
      },
    );
  }
}
