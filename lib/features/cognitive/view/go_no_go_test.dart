import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:libretrac/core/database/app_database.dart';
import 'package:libretrac/providers/db_provider.dart';

class GoNoGoTestScreen extends ConsumerStatefulWidget {
  const GoNoGoTestScreen({super.key});

  @override
  ConsumerState<GoNoGoTestScreen> createState() => _GoNoGoTestScreenState();
}

class _GoNoGoTestScreenState extends ConsumerState<GoNoGoTestScreen> {
  static const _stimDuration = Duration(milliseconds: 750);
  static const _trials = 40;
  static const _goProb = 0.7; // 70% GO trials (28 Go, 12 No-Go)

  final _rand = Random();
  late List<bool> _trialSchedule;
  int _trial = 0;
  bool _isGo = false;
  bool _showStim = false;
  bool _testRunning = false;

  final Stopwatch _rtWatch = Stopwatch();
  final List<double> _responseTimes = [];
  int _commissionErrors = 0; // tapped on NO-GO
  int _omissionErrors = 0; // missed GO

  Timer? _timer;
  bool _responded = false;
  String? _feedbackText;
  Color _feedbackColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _buildSchedule();
    Future.microtask(() => _showInstructions(initial: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _buildSchedule() {
    final goCount = (_trials * _goProb).round();
    final noGoCount = _trials - goCount;
    _trialSchedule = [
      ...List.filled(goCount, true),
      ...List.filled(noGoCount, false),
    ]..shuffle(_rand);
  }

  void _showInstructions({bool initial = false}) {
    _timer?.cancel();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogCtx) => AlertDialog(
            title: const Text('Go / No-Go Instructions'),
            content: const Text(
              '• Tap the screen immediately when you see a GREEN CIRCLE (GO).\n\n'
              '• Do NOT tap when a RED STOP octagon appears (NO-GO).\n\n'
              '• Focus on the center fixation cross (+) between stimuli.\n\n'
              'There are 40 trials total.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text(initial ? 'Start' : 'Resume'),
              ),
            ],
          ),
    ).then((_) {
      if (!mounted) return;
      _testRunning = true;
      _nextTrial();
    });
  }

  void _nextTrial() {
    if (!mounted) return;
    if (_trial >= _trials) {
      _endTest();
      return;
    }

    _isGo = _trialSchedule[_trial];
    _responded = false;
    _showStim = true;
    _feedbackText = null;
    setState(() {});

    _rtWatch
      ..reset()
      ..start();

    _timer?.cancel();
    _timer = Timer(_stimDuration, () {
      if (!mounted) return;
      _rtWatch.stop();
      if (_isGo && !_responded) {
        _omissionErrors++;
        _feedbackText = 'Missed GO!';
        _feedbackColor = Colors.orangeAccent;
      }
      _showStim = false;
      setState(() {});

      _trial++;
      // Jittered inter-stimulus interval (500ms - 900ms) to prevent rhythmic tapping
      final jitterMs = 500 + _rand.nextInt(401);
      _timer = Timer(Duration(milliseconds: jitterMs), _nextTrial);
    });
  }

  void _handleTapDown(TapDownDetails _) {
    if (!_testRunning || !_showStim || _responded) return;

    final rt = _rtWatch.elapsedMicroseconds / 1000.0;
    _rtWatch.stop();
    _responded = true;

    if (_isGo) {
      _responseTimes.add(rt);
      _feedbackText = '✓ ${rt.toStringAsFixed(0)} ms';
      _feedbackColor = Colors.green;
    } else {
      _commissionErrors++;
      _feedbackText = '✗ False alarm (NO-GO)!';
      _feedbackColor = Colors.redAccent;
    }

    _showStim = false;
    setState(() {});
  }

  Future<void> _endTest() async {
    _timer?.cancel();
    _testRunning = false;

    final meanRt =
        _responseTimes.isEmpty
            ? 0.0
            : _responseTimes.reduce((a, b) => a + b) / _responseTimes.length;

    final db = ref.read(dbProvider);
    await db.into(db.goNoGoResults).insert(
      GoNoGoResultsCompanion.insert(
        meanRt: meanRt,
        commissionErrors: _commissionErrors,
        omissionErrors: _omissionErrors,
      ),
    );

    if (!mounted) return;
    final accuracy =
        (((_trials - _commissionErrors - _omissionErrors) / _trials) * 100)
            .clamp(0, 100);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogCtx) => AlertDialog(
            title: const Text('Go / No-Go Complete'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mean RT (Go Hits): ${meanRt.toStringAsFixed(1)} ms',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Overall Accuracy: ${accuracy.toStringAsFixed(0)}%'),
                Text('Commission Errors (False Taps): $_commissionErrors'),
                Text('Omission Errors (Missed Go): $_omissionErrors'),
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
    final progress = (_trial / _trials).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Go / No-Go'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Instructions',
            onPressed: () => _showInstructions(initial: false),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _handleTapDown,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: progress,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Trial ${min(_trial + 1, _trials)} / $_trials',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Hits: ${_responseTimes.length} · Errors: ${_commissionErrors + _omissionErrors}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                height: 180,
                width: 180,
                child: Center(
                  child:
                      _showStim
                          ? Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color:
                                  _isGo
                                      ? Colors.green.shade500
                                      : Colors.red.shade600,
                              shape:
                                  _isGo ? BoxShape.circle : BoxShape.rectangle,
                              borderRadius:
                                  _isGo ? null : BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isGo ? Colors.green : Colors.red)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 24,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              _isGo ? Icons.touch_app : Icons.pan_tool_rounded,
                              size: 64,
                              color: Colors.white,
                            ),
                          )
                          : const Text(
                            '+',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w300,
                              color: Colors.grey,
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 28,
                child:
                    _feedbackText != null
                        ? Text(
                          _feedbackText!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _feedbackColor,
                          ),
                        )
                        : const Text(
                          'Tap ONLY when GREEN appears',
                          style: TextStyle(fontSize: 15, color: Colors.grey),
                        ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
