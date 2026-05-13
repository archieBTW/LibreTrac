import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libretrac/constants/disclaimer.dart';
import 'package:libretrac/features/ai/view/trend_analysis_dialog.dart';
import 'package:libretrac/features/cognitive/view/cognitive_chart.dart';
import 'package:libretrac/features/cognitive/view/digit_span_test.dart';
import 'package:libretrac/features/cognitive/view/go_no_go_test.dart';
import 'package:libretrac/features/cognitive/view/reaction_test_screen.dart';
import 'package:libretrac/features/cognitive/view/stroop_test_screen.dart';
import 'package:libretrac/features/cognitive/view/symbol_search_test.dart';
import 'package:libretrac/features/home/view/main_drawer.dart';
import 'package:libretrac/features/mood_sleep/view/mood_sleep_carousel.dart';
import 'package:libretrac/features/mood_sleep/view/sleep_checkin_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../../core/database/app_database.dart';
import '../../../providers/db_provider.dart';
import '../../mood_sleep/view/mood_checkin_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // final List<String> allMetrics = [
  //   'Energy',
  //   'Happiness',
  //   'Creativity',
  //   'Focus',
  //   'Irritability',
  //   'Anxiety',
  // ];

  // final Set<String> selectedMetrics = {
  //   'Happiness',
  //   'Energy',
  //   'Anxiety',
  //   'Creativity',
  //   'Focus',
  //   'Irritability',
  // };

  // final Map<String, Color> moodColors = {
  //   'Energy': Colors.teal,
  //   'Happiness': Colors.orange,
  //   'Creativity': Colors.purple,
  //   'Focus': Colors.blue,
  //   'Irritability': Colors.red,
  //   'Anxiety': Colors.brown,
  // };

  Set<String> selectedMetrics = {};
  Map<String, int>? customMetrics = {};
  final GlobalKey _sleepPopupKey = GlobalKey();
  bool _showSleepShowcase = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Show first-launch disclaimer if not yet acknowledged
      final disclaimerShown = await DisclaimerPrefs.hasAcknowledged();
      if (!disclaimerShown) {
        await _showFirstLaunchDisclaimer();
      }
      
      final done = await OnboardingPrefs.isComplete();
      if (!done) {
        _startTutorial();
      } else {
        _maybePromptSleep();
      }
    });
  }

  Future<void> _showFirstLaunchDisclaimer() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text(kFirstLaunchDisclaimerTitle),
        content: SingleChildScrollView(
          child: Text(
            kFirstLaunchDisclaimer,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              await DisclaimerPrefs.markAcknowledged();
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }

  void _startTutorial() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            title: const Text('Welcome to LibreTrac!'),
            content: const Text(
              'This is your personalized mood, sleep, and cognition tracker. Let’s take a quick tour!',
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await OnboardingPrefs.markComplete();
                  Navigator.of(context).pop();
                  _maybePromptSleep();
                },
                child: const Text('Skip'),
              ),

              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Future.delayed(
                    const Duration(milliseconds: 300),
                    _showSleepIntro,
                  );
                },
                child: const Text('Start'),
              ),
            ],
          ),
    );
  }

  void _showSleepIntro() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            title: const Text('Daily Sleep Check-In'),
            content: const Text(
              'Each morning when you open LibreTrac, we’ll prompt you to reflect on your sleep. '
              'It’s quick, simple, and helps us spot patterns that matter.\n\nReady to try it out?',
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await Future.delayed(const Duration(milliseconds: 300));
                  await showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const SleepCheckinDialog(),
                  );
                  await Future.delayed(const Duration(milliseconds: 300));
                  _startShowcaseStep2(); // highlights mood check-in
                },
                child: const Text('Continue'),
              ),
            ],
          ),
    );
  }

  void _startShowcaseStep2() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            title: const Text('Nice Work!'),
            content: const Text(
              'Great job! Now let’s start tracking your mood for the day.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EditMetricsScreen(onboarding: true),
                    ),
                  );
                },
                child: const Text('Continue'),
              ),
            ],
          ),
    );
  }

  Future<void> _maybePromptSleep() async {
    final db = ref.read(dbProvider);
    final today = await db.entryFor(DateTime.now());
    if (today != null) return; // already logged
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SleepCheckinDialog(),
    );
  }

  _showSleepTutorial() async {
    return Visibility(
      visible: true, // create a bool flag if needed
      child: Showcase(
        key: _sleepPopupKey,
        title: 'Sleep Check-In',
        description: 'Every morning, LibreTrac will ask how you slept.',
        child: Card(
          child: ListTile(
            title: Text('Sleep Popup Example'),
            trailing: ElevatedButton(onPressed: () {}, child: Text('Log')),
          ),
        ),
      ),
    );
  }

  void _showCheckInSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Choose Check-In Type',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.mood),
                  title: const Text('Mood Check-In'),
                  onTap: () async {
                    Navigator.pop(context);
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MoodCheckInScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.bedtime),
                  title: const Text('Sleep Check-In'),
                  onTap: () async {
                    Navigator.pop(context);
                    await showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const SleepCheckinDialog(),
                    );
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showCognitiveSheet() {
    showModalBottomSheet(
      context: context,
      builder:
          (_) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetItem('Reaction Time', const ReactionTestScreen()),
              _sheetItem('Stroop Test', const StroopTestScreen()),
              _sheetItem('Go / No-Go', const GoNoGoTestScreen()),
              _sheetItem('Digit Span', const DigitSpanTestScreen()),
              _sheetItem('Symbol Search', const SymbolSearchScreen()),
            ],
          ),
    );
  }

  ListTile _sheetItem(String label, Widget screen) {
    return ListTile(
      title: Text(label),
      onTap: () async {
        Navigator.pop(context);
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final window = ref.watch(moodWindowProvider);
    final AsyncValue<List<SleepEntry>> sleeps = ref.watch(sleepStreamProvider);
    final customMetrics = ref.watch(customMetricsProvider);

    final List<String> allMetrics = customMetrics.map((e) => e.name).toList();
    final Map<String, Color> moodColors = {
      for (final metric in customMetrics) metric.name: metric.color,
    };

    if (selectedMetrics.isEmpty && customMetrics.isNotEmpty) {
      selectedMetrics = allMetrics.toSet(); // default: all enabled
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('LibreTrac'),
          actions: [
            IconButton(
              tooltip: 'Analyze Trends',
              icon: Image.asset(
                'assets/icons/ai_analysis.png',
                width: 24,
                height: 24,
                color: Colors.white,
              ),
              onPressed: () => showTrendDialog(context, ref),
            ),
            PopupMenuButton<Object>(
              icon: const Icon(Icons.remove_red_eye_outlined),
              onSelected: (value) {
                if (value is MoodWindow) {
                  ref.read(moodWindowProvider.notifier).state = value;
                } else if (value == 'toggleDetailed') {
                  ref
                      .read(showAllCheckInsProvider.notifier)
                      .update((prev) => !prev);
                }
              },
              itemBuilder: (ctx) {
                final detailed = ref.watch(showAllCheckInsProvider);
                final selectedWindow = ref.watch(moodWindowProvider);

                return [
                  CheckedPopupMenuItem(
                    value: MoodWindow.week,
                    checked: selectedWindow == MoodWindow.week,
                    child: const Text('7 days'),
                  ),
                  CheckedPopupMenuItem(
                    value: MoodWindow.month,
                    checked: selectedWindow == MoodWindow.month,
                    child: const Text('1 month'),
                  ),
                  CheckedPopupMenuItem(
                    value: MoodWindow.threeMonths,
                    checked: selectedWindow == MoodWindow.threeMonths,
                    child: const Text('3 months'),
                  ),
                  CheckedPopupMenuItem(
                    value: MoodWindow.sixMonths,
                    checked: selectedWindow == MoodWindow.sixMonths,
                    child: const Text('6 months'),
                  ),
                  const PopupMenuDivider(),
                  CheckedPopupMenuItem(
                    value: 'toggleDetailed',
                    checked: detailed,
                    child: const Text('Detailed View'),
                  ),
                ];
              },
            ),
          ],
        ),
        drawer: MainDrawer(() => setState(() {})),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 900;

            return Consumer(
              builder: (context, ref, _) {
                final detailed = ref.watch(showAllCheckInsProvider);

                final AsyncValue<List<MoodEntry>> moods = ref.watch(
                  filteredMoodEntriesProvider((
                    window: window,
                    showAllCheckIns: detailed,
                  )),
                );

                return moods.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, __) => Center(child: Text('Error: $e')),
                  data: (entries) {
                    bool hasEnoughData = true;
                    final ordered = [...entries] // copy
                      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (!hasEnoughData)
                            SizedBox(
                              height: 350,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.sentiment_satisfied_alt,
                                    size: 80,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Keep checking in daily to see your mood trends!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.edit),
                                        label: const Text('Mood Check-In'),
                                        onPressed: () async {
                                          await Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder:
                                                  (_) => const MoodCheckInScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 12),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.flash_on),
                                        label: const Text('Cognitive Tests'),
                                        onPressed: _showCognitiveSheet,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          if (hasEnoughData) ...[
                            Expanded(
                              child: MoodSleepCarousel(
                                moodEntries: entries,
                                sleepEntries: sleeps.value ?? const [],
                                orderedMood: ordered,
                                selectedMetrics: selectedMetrics,
                                moodColors: moodColors,
                                allMetrics: ref.watch(customMetricsProvider),
                                window: window,
                                customMetrics: customMetrics,
                                isDesktop: isDesktop,
                                onMetricToggle: (metric, isSelected) {
                                  setState(() {
                                    if (isSelected) {
                                      selectedMetrics.add(metric);
                                    } else if (selectedMetrics.length > 1) {
                                      selectedMetrics.remove(metric);
                                    }
                                  });
                                },
                              ),
                            ),
                            FutureBuilder(
                              future: ref
                                  .read(dbProvider)
                                  .select(ref.read(dbProvider).reactionResults)
                                  .get(),
                              builder: (context, snap) {
                                return CognitiveChart().showCognitiveChart(
                                  ref,
                                  window,
                                  detailed,
                                  isDesktop: isDesktop,
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Check-In'),
                                    onPressed: _showCheckInSheet,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.flash_on),
                                    label: const Text('Cognitive Tests'),
                                    onPressed: _showCognitiveSheet,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class EditMetricsScreen extends ConsumerStatefulWidget {
  final bool onboarding;
  const EditMetricsScreen({super.key, this.onboarding = false});

  @override
  ConsumerState<EditMetricsScreen> createState() => _EditMetricsScreenState();
}

class _EditMetricsScreenState extends ConsumerState<EditMetricsScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.onboarding) {
        _showIntroDialog();
      }
    });
  }

  void _showIntroDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            title: const Text('Customize Your Mood Metrics'),
            content: const Text(
              'LibreTrac lets you customize exactly what aspects of your mood you’d like to track! '
              'Feel free to change the defaults, add your own, or just continue if you like what you see.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Got it!'),
              ),
            ],
          ),
    );
  }

  void _showMetricDialog({CustomMetric? existing, int? index}) {
    final controller = TextEditingController(text: existing?.name ?? '');
    Color selectedColor = existing?.color ?? Colors.blue;

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(existing == null ? 'Add Metric' : 'Edit Metric'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(labelText: 'Metric Name'),
                ),
                const SizedBox(height: 16),
                BlockPicker(
                  pickerColor: selectedColor,
                  onColorChanged: (color) => selectedColor = color,
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: const Text('Save'),
                onPressed: () {
                  final name = controller.text.trim();
                  if (name.isEmpty) return;
                  final metric = CustomMetric(name: name, color: selectedColor);

                  final notifier = ref.read(customMetricsProvider.notifier);
                  if (existing == null) {
                    notifier.addMetric(metric);
                  } else {
                    notifier.updateMetric(index!, metric);
                  }

                  Navigator.pop(context);
                },
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ref.watch(customMetricsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Mood Metrics'),
        automaticallyImplyLeading: !widget.onboarding, // hide back
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Metric',
            onPressed: metrics.length >= 6 ? null : () => _showMetricDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: metrics.length,
              itemBuilder: (context, i) {
                final metric = metrics[i];
                return ListTile(
                  title: Text(metric.name),
                  leading: CircleAvatar(backgroundColor: metric.color),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed:
                            () => _showMetricDialog(existing: metric, index: i),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          ref
                              .read(customMetricsProvider.notifier)
                              .deleteMetric(i);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (widget.onboarding)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {
                  // Next step in onboarding: navigate to mood check-in
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const MoodCheckInScreen(onboarding: true),
                    ),
                  );
                },
                child: const Text('Continue to Mood Tracking'),
              ),
            ),
        ],
      ),
    );
  }
}

class OnboardingPrefs {
  static const _key = 'onboarding_complete';

  static Future<bool> isComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

class DisclaimerPrefs {
  static const _key = 'disclaimer_acknowledged';

  static Future<bool> hasAcknowledged() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> markAcknowledged() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
