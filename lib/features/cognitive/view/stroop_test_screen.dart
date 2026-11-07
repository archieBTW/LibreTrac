import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:libretrac/core/database/app_database.dart';
import 'package:libretrac/providers/db_provider.dart';

class _StroopTrial {
  final String word;
  final String inkColorName;
  final Color inkColor;
  final bool isCongruent;

  const _StroopTrial({
    required this.word,
    required this.inkColorName,
    required this.inkColor,
    required this.isCongruent,
  });
}

class StroopTestScreen extends ConsumerStatefulWidget {
  const StroopTestScreen({super.key});

  @override
  ConsumerState<StroopTestScreen> createState() => _StroopTestScreenState();
}

class _StroopTestScreenState extends ConsumerState<StroopTestScreen> {
  static const int totalRounds = 20;
  static const List<String> _colorWords = ['Red', 'Green', 'Blue', 'Yellow'];
  static const Map<String, Color> _colorMap = {
    'Red': Color(0xFFEF4444),
    'Green': Color(0xFF22C55E),
    'Blue': Color(0xFF3B82F6),
    'Yellow': Color(0xFFFACC15),
  };

  bool _showIntro = true;
  int _currentRound = 0;
  int _correct = 0;
  int _incorrect = 0;

  final List<double> _congruentRTs = [];
  final List<double> _incongruentRTs = [];
  final List<double> _allCongruentRTs = [];
  final List<double> _allIncongruentRTs = [];

  late List<_StroopTrial> _trials;
  late _StroopTrial _currentTrial;
  final Stopwatch _sw = Stopwatch();
  bool _awaitingResponse = false;
  String? _feedbackText;
  bool? _lastWasCorrect;
  Timer? _nextTimer;

  @override
  void initState() {
    super.initState();
    _generateBalancedTrials();
    Future.microtask(_showInstructions);
  }

  @override
  void dispose() {
    _nextTimer?.cancel();
    super.dispose();
  }

  /// Generates a balanced 50/50 split of congruent (10) and incongruent (10) trials
  /// and avoids consecutive identical trials.
  void _generateBalancedTrials() {
    final rand = Random();
    final deck = <_StroopTrial>[];

    // 10 congruent trials
    for (int i = 0; i < totalRounds ~/ 2; i++) {
      final word = _colorWords[rand.nextInt(_colorWords.length)];
      deck.add(
        _StroopTrial(
          word: word,
          inkColorName: word,
          inkColor: _colorMap[word]!,
          isCongruent: true,
        ),
      );
    }

    // 10 incongruent trials
    for (int i = 0; i < totalRounds - (totalRounds ~/ 2); i++) {
      final word = _colorWords[rand.nextInt(_colorWords.length)];
      final otherColors = _colorWords.where((c) => c != word).toList();
      final ink = otherColors[rand.nextInt(otherColors.length)];
      deck.add(
        _StroopTrial(
          word: word,
          inkColorName: ink,
          inkColor: _colorMap[ink]!,
          isCongruent: false,
        ),
      );
    }

    deck.shuffle(rand);
    _trials = deck;
  }

  void _showInstructions() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogCtx) => AlertDialog(
            title: const Text('Stroop Test Instructions'),
            content: const Text(
              'You will see a color WORD displayed in a colored font.\n\n'
              'Tap the button that matches the FONT COLOR (ink color), ignoring what the word says.\n\n'
              'React as quickly and accurately as you can across 20 rounds.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  if (_showIntro) {
                    setState(() => _showIntro = false);
                    _nextRound();
                  }
                },
                child: Text(_showIntro ? 'Start' : 'Resume'),
              ),
            ],
          ),
    );
  }

  void _nextRound() {
    if (!mounted) return;
    if (_currentRound >= totalRounds) {
      _endTest();
      return;
    }

    setState(() {
      _currentTrial = _trials[_currentRound];
      _currentRound++;
      _feedbackText = null;
      _lastWasCorrect = null;
      _awaitingResponse = true;
    });

    _sw
      ..reset()
      ..start();
  }

  void _handleAnswer(String chosenColor) {
    if (!_awaitingResponse) return;
    _sw.stop();
    _awaitingResponse = false;

    final rt = _sw.elapsedMicroseconds / 1000.0;
    final isCorrect = chosenColor == _currentTrial.inkColorName;

    if (_currentTrial.isCongruent) {
      _allCongruentRTs.add(rt);
      if (isCorrect) _congruentRTs.add(rt);
    } else {
      _allIncongruentRTs.add(rt);
      if (isCorrect) _incongruentRTs.add(rt);
    }

    setState(() {
      if (isCorrect) {
        _correct++;
        _lastWasCorrect = true;
        _feedbackText = '✓ ${rt.toStringAsFixed(0)} ms';
      } else {
        _incorrect++;
        _lastWasCorrect = false;
        _feedbackText = '✗ Was ${_currentTrial.inkColorName}';
      }
    });

    _nextTimer?.cancel();
    _nextTimer = Timer(const Duration(milliseconds: 350), _nextRound);
  }

  double _mean(List<double> primary, List<double> fallback) {
    final list = primary.isNotEmpty ? primary : fallback;
    if (list.isEmpty) return 0.0;
    return list.reduce((a, b) => a + b) / list.length;
  }

  Future<void> _endTest() async {
    final avgCong = _mean(_congruentRTs, _allCongruentRTs);
    final avgIncong = _mean(_incongruentRTs, _allIncongruentRTs);
    final delta = avgIncong - avgCong;
    final accuracy = (_correct / totalRounds) * 100;

    final db = ref.read(dbProvider);
    await db.into(db.stroopResults).insert(
      StroopResultsCompanion.insert(
        congruentMs: avgCong,
        incongruentMs: avgIncong,
        deltaMs: delta,
      ),
    );

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogCtx) => AlertDialog(
            title: const Text('Stroop Test Complete'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stroop Interference (Δ): ${delta.toStringAsFixed(1)} ms',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Accuracy: ${accuracy.toStringAsFixed(0)}% ($_correct / $totalRounds)',
                ),
                Text('Congruent RT: ${avgCong.toStringAsFixed(1)} ms'),
                Text('Incongruent RT: ${avgIncong.toStringAsFixed(1)} ms'),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Done'),
              ),
            ],
          ),
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_showIntro) {
      return Scaffold(
        appBar: AppBar(title: const Text('Stroop Test')),
        body: Center(
          child: ElevatedButton(
            onPressed: _showInstructions,
            child: const Text('Start Stroop Test'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stroop Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInstructions,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: _currentRound / totalRounds,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Round $_currentRound / $totalRounds',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Correct: $_correct · Errors: $_incorrect',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const Spacer(),
            // High-contrast dark stimulus box so Yellow, Red, Green, Blue are equally legible
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      _lastWasCorrect == null
                          ? Colors.white24
                          : (_lastWasCorrect!
                              ? Colors.greenAccent
                              : Colors.redAccent),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 100),
                    child: Text(
                      _awaitingResponse ? _currentTrial.word.toUpperCase() : '',
                      key: ValueKey('$_currentRound-$_awaitingResponse'),
                      style: TextStyle(
                        fontSize: 52,
                        color: _currentTrial.inkColor,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 24,
                    child:
                        _feedbackText != null
                            ? Text(
                              _feedbackText!,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color:
                                    _lastWasCorrect == true
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
                              ),
                            )
                            : const Text(
                              'Tap the INK color below',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white54,
                              ),
                            ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 2.6,
              children:
                  _colorWords.map((colorName) {
                    final bgColor = _colorMap[colorName]!;
                    final textColor =
                        colorName == 'Yellow' ? Colors.black : Colors.white;
                    return ElevatedButton(
                      onPressed:
                          _awaitingResponse
                              ? () => _handleAnswer(colorName)
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: bgColor,
                        disabledBackgroundColor: bgColor.withValues(alpha: 0.5),
                        foregroundColor: textColor,
                        disabledForegroundColor: textColor.withValues(
                          alpha: 0.7,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        colorName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
