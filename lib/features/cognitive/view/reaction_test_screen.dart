import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../providers/db_provider.dart';

enum _ReactionState { idle, waiting, ready, tooSoon, roundComplete, finished }

class ReactionTestScreen extends ConsumerStatefulWidget {
  const ReactionTestScreen({super.key});

  @override
  ConsumerState<ReactionTestScreen> createState() => _ReactionTestScreenState();
}

class _ReactionTestScreenState extends ConsumerState<ReactionTestScreen> {
  static const int totalRounds = 5;
  final List<double> _reactionTimes = [];
  final Random _rng = Random();

  _ReactionState _state = _ReactionState.idle;
  Timer? _waitTimer;
  final Stopwatch _stopwatch = Stopwatch();
  double? _lastReactionMs;

  void _startRound() {
    _waitTimer?.cancel();
    _stopwatch.reset();

    setState(() {
      _state = _ReactionState.waiting;
      _lastReactionMs = null;
    });

    final delay = Duration(milliseconds: _rng.nextInt(2200) + 1500);
    _waitTimer = Timer(delay, () {
      if (!mounted) return;
      setState(() {
        _state = _ReactionState.ready;
      });
      // Start stopwatch immediately when state flips to ready (no fade animation)
      _stopwatch
        ..reset()
        ..start();
    });
  }

  void _handleTapDown(TapDownDetails _) {
    switch (_state) {
      case _ReactionState.idle:
      case _ReactionState.roundComplete:
      case _ReactionState.tooSoon:
        _startRound();
        break;

      case _ReactionState.waiting:
        _waitTimer?.cancel();
        _stopwatch.stop();
        setState(() {
          _state = _ReactionState.tooSoon;
        });
        break;

      case _ReactionState.ready:
        _stopwatch.stop();
        final elapsedUs = _stopwatch.elapsedMicroseconds;
        final ms = elapsedUs / 1000.0;
        // Guard against impossible <50ms accidental pre-tap
        if (ms < 50) {
          setState(() {
            _state = _ReactionState.tooSoon;
          });
          return;
        }
        _reactionTimes.add(ms);
        _lastReactionMs = ms;

        if (_reactionTimes.length >= totalRounds) {
          _saveResult();
        } else {
          setState(() {
            _state = _ReactionState.roundComplete;
          });
        }
        break;

      case _ReactionState.finished:
        break;
    }
  }

  Future<void> _saveResult() async {
    setState(() {
      _state = _ReactionState.finished;
    });

    final db = ref.read(dbProvider);
    final avg = _reactionTimes.reduce((a, b) => a + b) / _reactionTimes.length;
    final fastest = _reactionTimes.reduce(min);
    final slowest = _reactionTimes.reduce(max);
    final variance =
        _reactionTimes
            .map((t) => pow(t - avg, 2))
            .reduce((a, b) => a + b) /
        _reactionTimes.length;
    final sd = sqrt(variance);

    await db.into(db.reactionResults).insert(
      ReactionResultsCompanion.insert(
        timestamp: DateTime.now(),
        averageTime: avg,
        fastest: fastest,
        slowest: slowest,
      ),
    );

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogCtx) => AlertDialog(
            title: const Text('Reaction Time Complete'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Average: ${avg.toStringAsFixed(1)} ms',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Fastest: ${fastest.toStringAsFixed(1)} ms'),
                Text('Slowest: ${slowest.toStringAsFixed(1)} ms'),
                Text('Consistency (SD): ±${sd.toStringAsFixed(1)} ms'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  _restart();
                },
                child: const Text('Try Again'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  if (mounted) Navigator.pop(context);
                },
                child: const Text('Done'),
              ),
            ],
          ),
    );
  }

  void _restart() {
    _waitTimer?.cancel();
    _stopwatch.reset();
    setState(() {
      _reactionTimes.clear();
      _lastReactionMs = null;
      _state = _ReactionState.idle;
    });
  }

  @override
  void dispose() {
    _waitTimer?.cancel();
    super.dispose();
  }

  Color _backgroundColor(BuildContext context) {
    return switch (_state) {
      _ReactionState.idle => Colors.blueGrey.shade800,
      _ReactionState.waiting => Colors.red.shade700,
      _ReactionState.ready => Colors.green.shade600,
      _ReactionState.tooSoon => Colors.orange.shade800,
      _ReactionState.roundComplete => Colors.indigo.shade700,
      _ReactionState.finished => Colors.teal.shade700,
    };
  }

  IconData _statusIcon() {
    return switch (_state) {
      _ReactionState.idle => Icons.touch_app,
      _ReactionState.waiting => Icons.hourglass_top,
      _ReactionState.ready => Icons.bolt,
      _ReactionState.tooSoon => Icons.warning_amber_rounded,
      _ReactionState.roundComplete => Icons.timer_outlined,
      _ReactionState.finished => Icons.check_circle_outline,
    };
  }

  String _headlineText() {
    return switch (_state) {
      _ReactionState.idle => 'Tap anywhere to start',
      _ReactionState.waiting => 'Wait for GREEN…',
      _ReactionState.ready => 'TAP NOW!',
      _ReactionState.tooSoon => 'Too soon!',
      _ReactionState.roundComplete =>
        '${_lastReactionMs!.toStringAsFixed(0)} ms',
      _ReactionState.finished => 'Test Complete!',
    };
  }

  String _subtitleText() {
    return switch (_state) {
      _ReactionState.idle =>
        'Tap as fast as you can when the screen turns green ($totalRounds rounds).',
      _ReactionState.waiting => 'Keep your finger ready…',
      _ReactionState.ready => 'Tap immediately!',
      _ReactionState.tooSoon =>
        'You tapped before the screen turned green.\nTap anywhere to retry this round.',
      _ReactionState.roundComplete => 'Tap anywhere for the next round.',
      _ReactionState.finished =>
        _reactionTimes.isEmpty
            ? ''
            : 'Average: ${(_reactionTimes.reduce((a, b) => a + b) / _reactionTimes.length).toStringAsFixed(1)} ms',
    };
  }

  @override
  Widget build(BuildContext context) {
    final currentRound = min(_reactionTimes.length + 1, totalRounds);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reaction Time Test'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                'Round $currentRound / $totalRounds',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _handleTapDown,
        // Use plain Container (no AnimatedContainer) so green stimulus appears with 0ms fade lag
        child: Container(
          color: _backgroundColor(context),
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Round history pills
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (int i = 0; i < totalRounds; i++)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color:
                            i < _reactionTimes.length
                                ? Colors.white.withValues(alpha: 0.22)
                                : Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        i < _reactionTimes.length
                            ? '#${i + 1}: ${_reactionTimes[i].toStringAsFixed(0)}ms'
                            : '#${i + 1}: —',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),

              // Main stimulus prompt
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_statusIcon(), size: 64, color: Colors.white),
                  const SizedBox(height: 20),
                  Text(
                    _headlineText(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _subtitleText(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
