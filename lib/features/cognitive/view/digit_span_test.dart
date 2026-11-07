import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:libretrac/core/database/app_database.dart';
import 'package:libretrac/providers/db_provider.dart';

class DigitSpanTestScreen extends ConsumerStatefulWidget {
  const DigitSpanTestScreen({super.key});

  @override
  ConsumerState<DigitSpanTestScreen> createState() =>
      _DigitSpanTestScreenState();
}

class _DigitSpanTestScreenState extends ConsumerState<DigitSpanTestScreen> {
  final _rand = Random();
  int _span = 3; // starting length
  int _bestSpan = 0;
  int _mistakesAtCurrentSpan = 0; // 2 attempts per span level

  List<int> _sequence = [];
  bool _presenting = true;
  int? _currentDigit; // null during brief inter-digit gap
  int _presentingIndex = 0;
  String _userInput = '';
  String? _statusBanner;
  bool? _lastCorrect;
  Timer? _stepTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _showInstructions(initial: true));
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    super.dispose();
  }

  void _showInstructions({bool initial = false}) {
    _stepTimer?.cancel();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogCtx) => AlertDialog(
            title: const Text('Digit Span Instructions'),
            content: const Text(
              'Digits will appear one at a time in the center of the screen.\n\n'
              'Memorize the sequence in order. Once all digits have been shown, enter them using the keypad.\n\n'
              '• Each level adds 1 more digit.\n'
              '• You get 2 chances at each length before the test ends.',
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
      if (initial || _sequence.isEmpty) {
        _nextRound();
      } else if (_presenting) {
        _startSequentialPresentation();
      }
    });
  }

  List<int> _generateSequence(int length) {
    final seq = <int>[];
    for (int i = 0; i < length; i++) {
      int next = _rand.nextInt(10);
      // Avoid 3 identical digits in a row
      if (i >= 2 && seq[i - 1] == next && seq[i - 2] == next) {
        next = (next + 1 + _rand.nextInt(9)) % 10;
      }
      seq.add(next);
    }
    return seq;
  }

  void _nextRound() {
    _stepTimer?.cancel();
    _sequence = _generateSequence(_span);
    _userInput = '';
    _statusBanner = null;
    _lastCorrect = null;
    _startSequentialPresentation();
  }

  void _startSequentialPresentation() {
    _stepTimer?.cancel();
    _presenting = true;
    _presentingIndex = 0;
    _currentDigit = null;
    setState(() {});

    // Brief 400ms pause before first digit
    _stepTimer = Timer(const Duration(milliseconds: 400), _showNextDigitStep);
  }

  void _showNextDigitStep() {
    if (!mounted) return;
    if (_presentingIndex >= _sequence.length) {
      setState(() {
        _presenting = false;
        _currentDigit = null;
      });
      return;
    }

    setState(() {
      _currentDigit = _sequence[_presentingIndex];
    });

    // Show digit for 750ms, then 200ms blank gap so duplicate consecutive digits clearly blink
    _stepTimer = Timer(const Duration(milliseconds: 750), () {
      if (!mounted) return;
      setState(() {
        _currentDigit = null;
      });
      _presentingIndex++;
      _stepTimer = Timer(
        const Duration(milliseconds: 200),
        _showNextDigitStep,
      );
    });
  }

  void _onKeyTap(String key) {
    if (_presenting || _statusBanner != null) return;
    if (key == 'BACK') {
      if (_userInput.isNotEmpty) {
        setState(() {
          _userInput = _userInput.substring(0, _userInput.length - 1);
        });
      }
      return;
    }

    if (_userInput.length < _span) {
      setState(() {
        _userInput += key;
      });
      if (_userInput.length == _span) {
        _submit();
      }
    }
  }

  void _submit() {
    if (_userInput.length != _span || _presenting) return;

    final entered = _userInput.split('').map(int.parse).toList();
    final isCorrect = listEquals(entered, _sequence);

    if (isCorrect) {
      _bestSpan = max(_bestSpan, _span);
      _mistakesAtCurrentSpan = 0;
      setState(() {
        _lastCorrect = true;
        _statusBanner = '✓ Correct! Advancing to ${_span + 1} digits…';
      });
      _span++;
      _stepTimer = Timer(const Duration(milliseconds: 900), _nextRound);
    } else {
      _mistakesAtCurrentSpan++;
      if (_mistakesAtCurrentSpan < 2) {
        setState(() {
          _lastCorrect = false;
          _statusBanner =
              '✗ Sequence was ${_sequence.join(' ')} · 1 retry left at $_span digits';
        });
        _stepTimer = Timer(const Duration(milliseconds: 1400), _nextRound);
      } else {
        setState(() {
          _lastCorrect = false;
          _statusBanner = '✗ Sequence was ${_sequence.join(' ')}';
        });
        _stepTimer = Timer(const Duration(milliseconds: 900), _endTest);
      }
    }
  }

  Future<void> _endTest() async {
    _stepTimer?.cancel();
    final db = ref.read(dbProvider);
    await db
        .into(db.digitSpanResults)
        .insert(DigitSpanResultsCompanion.insert(bestSpan: _bestSpan));

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogCtx) => AlertDialog(
            title: const Text('Digit Span Complete'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Best Span: $_bestSpan digits',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Reached Level: $_span digits'),
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Digit Span'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Instructions',
            onPressed: () => _showInstructions(initial: false),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    avatar: const Icon(Icons.linear_scale, size: 16),
                    label: Text('Length: $_span digits'),
                  ),
                  Chip(
                    avatar: const Icon(Icons.emoji_events_outlined, size: 16),
                    label: Text('Best: $_bestSpan'),
                  ),
                  Row(
                    children: [
                      for (int i = 0; i < 2; i++)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            i < (2 - _mistakesAtCurrentSpan)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 18,
                            color: Colors.redAccent,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const Spacer(),

              if (_presenting) ...[
                Text(
                  'Watch carefully (${min(_presentingIndex + 1, _sequence.length)} / $_span)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 140,
                  height: 140,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    _currentDigit != null ? '$_currentDigit' : '',
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  _statusBanner ?? 'Enter the $_span-digit sequence in order:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color:
                        _lastCorrect == null
                            ? theme.colorScheme.onSurface
                            : (_lastCorrect! ? Colors.green : Colors.redAccent),
                  ),
                ),
                const SizedBox(height: 16),
                // Input slot boxes
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (int i = 0; i < _span; i++)
                      Container(
                        width: 42,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color:
                              i < _userInput.length
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                i == _userInput.length
                                    ? theme.colorScheme.primary
                                    : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          i < _userInput.length ? _userInput[i] : '',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],

              const Spacer(),

              // On-screen numeric keypad
              IgnorePointer(
                ignoring: _presenting || _statusBanner != null,
                child: Opacity(
                  opacity: (_presenting || _statusBanner != null) ? 0.35 : 1.0,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.8,
                      children: [
                        for (final d in [
                          '1',
                          '2',
                          '3',
                          '4',
                          '5',
                          '6',
                          '7',
                          '8',
                          '9',
                        ])
                          _KeypadButton(
                            label: d,
                            onTap: () => _onKeyTap(d),
                          ),
                        const SizedBox.shrink(),
                        _KeypadButton(
                          label: '0',
                          onTap: () => _onKeyTap('0'),
                        ),
                        _KeypadButton(
                          icon: Icons.backspace_outlined,
                          onTap: () => _onKeyTap('BACK'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({this.label, this.icon, required this.onTap});

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: EdgeInsets.zero,
      ),
      child:
          icon != null
              ? Icon(icon, size: 22)
              : Text(
                label!,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
    );
  }
}
