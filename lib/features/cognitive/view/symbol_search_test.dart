import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:libretrac/core/database/app_database.dart';
import 'package:libretrac/providers/db_provider.dart';

class SymbolSearchScreen extends ConsumerStatefulWidget {
  const SymbolSearchScreen({super.key});

  @override
  ConsumerState<SymbolSearchScreen> createState() => _SymbolSearchScreenState();
}

class _SymbolSearchScreenState extends ConsumerState<SymbolSearchScreen> {
  // 8 visually distinct geometric symbols (no duplicate diamonds)
  static const _symbols = ['△', '□', '○', '☆', '◇', '✚', '⬡', '▽'];
  final _rand = Random();
  static const int _trials = 20;

  late String _target;
  late List<String> _row;
  int _trial = 0;
  int _hits = 0;
  final List<double> _rts = [];
  final Stopwatch _sw = Stopwatch();
  bool _showIntro = true;
  bool _inputLocked = false;
  int? _tappedIndex;
  bool? _tappedCorrect;
  Timer? _nextTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(_showInstructions);
  }

  @override
  void dispose() {
    _nextTimer?.cancel();
    super.dispose();
  }

  void _showInstructions() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogCtx) => AlertDialog(
            title: const Text('Symbol Search Instructions'),
            content: const Text(
              'A target symbol appears in the top card.\n\n'
              'Below it, six distinct symbols are shown in a 3×2 grid.\n\n'
              'Tap the cell that matches the target symbol as quickly and accurately as you can across 20 trials.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  if (_showIntro) {
                    setState(() => _showIntro = false);
                    _startTest();
                  }
                },
                child: Text(_showIntro ? 'Start' : 'Resume'),
              ),
            ],
          ),
    );
  }

  void _startTest() {
    _hits = 0;
    _trial = 0;
    _rts.clear();
    _next();
  }

  void _next() {
    if (!mounted) return;
    if (_trial >= _trials) {
      _end();
      return;
    }

    // Pick 1 target and 5 unique distractors so every grid has exactly 1 match
    final pool = [..._symbols]..shuffle(_rand);
    _target = pool.first;
    _row = pool.take(6).toList()..shuffle(_rand);

    _tappedIndex = null;
    _tappedCorrect = null;
    _inputLocked = false;
    setState(() {});

    _sw
      ..reset()
      ..start();
  }

  void _tap(int index) {
    if (_inputLocked) return;
    _sw.stop();
    _inputLocked = true;

    final rt = _sw.elapsedMicroseconds / 1000.0;
    final isHit = _row[index] == _target;

    if (isHit) {
      _hits++;
      _rts.add(rt);
    }

    setState(() {
      _tappedIndex = index;
      _tappedCorrect = isHit;
    });

    _trial++;
    _nextTimer?.cancel();
    _nextTimer = Timer(
      Duration(milliseconds: isHit ? 180 : 350),
      _next,
    );
  }

  Future<void> _end() async {
    final meanRT =
        _rts.isEmpty
            ? 0.0
            : _rts.reduce((a, b) => a + b) / _rts.length;
    final accuracy = (_hits / _trials) * 100;

    final db = ref.read(dbProvider);
    await db.into(db.symbolSearchResults).insert(
      SymbolSearchResultsCompanion.insert(
        hits: _hits,
        total: _trials,
        meanRt: meanRT,
      ),
    );

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogCtx) => AlertDialog(
            title: const Text('Symbol Search Complete'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mean RT (Hits): ${meanRT.toStringAsFixed(0)} ms',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Accuracy: ${accuracy.toStringAsFixed(0)}% ($_hits / $_trials)',
                ),
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
        appBar: AppBar(title: const Text('Symbol Search')),
        body: const SizedBox.shrink(),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Symbol Search'),
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
              value: (_trial / _trials).clamp(0.0, 1.0),
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
                  'Hits: $_hits / $_trial',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Target card
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'TARGET SYMBOL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _target,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 6,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 1.15,
                        ),
                    itemBuilder: (_, i) {
                      final isSelected = _tappedIndex == i;
                      Color? bgColor;
                      if (isSelected) {
                        bgColor =
                            _tappedCorrect == true
                                ? Colors.green.withValues(alpha: 0.35)
                                : Colors.red.withValues(alpha: 0.35);
                      }

                      return ElevatedButton(
                        onPressed: () => _tap(i),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: bgColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _row[i],
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
