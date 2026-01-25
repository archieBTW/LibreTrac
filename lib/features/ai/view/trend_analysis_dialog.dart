import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:libretrac/features/ai/provider/trend_analysis_provider.dart';
import 'package:flutter_riverpod/src/consumer.dart';

extension on TrendRange {
  String get label => switch (this) {
    TrendRange.week => '7 d',
    TrendRange.month => '1 m',
    TrendRange.threeMonths => '3 m',
    TrendRange.sixMonths => '6 m',
  };
}

String trendLabel(TrendRange r) => r.label;

Future<void> _reportIssue() async {
  final uri = Uri(
    scheme: 'mailto',
    path: 'billy@billyrigdon.dev',
    // queryParameters handles encoding better than manual string concatenation
    queryParameters: {
      'subject': 'LibreTrac AI Issue Report - Trend Analysis',
      'body': 'Please describe the issue with the AI-generated analysis:\n\n',
    },
  );
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint('Could not launch mailto: $e');
  }
}

void showTrendDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      TrendRange selected = ref.read(trendRangeProvider);
      Future<String?>? future;
      final subtleColor = Theme.of(ctx).colorScheme.onSurfaceVariant.withOpacity(0.7);

      return StatefulBuilder(
        builder: (ctx, setState) {
          Widget body;

          if (future == null) {
            body = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  children:
                      TrendRange.values.map((r) {
                        return ChoiceChip(
                          label: Text(trendLabel(r)),
                          selected: selected == r,
                          onSelected: (_) {
                            setState(() {
                              selected = r;
                              ref.read(trendRangeProvider.notifier).state = r;
                            });
                          },
                        );
                      }).toList(),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Run Analysis'),
                  onPressed: () {
                    setState(() {
                      future = ref.read(analysisProvider.future);
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 12, color: subtleColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'AI may contain errors. Not medical advice.',
                        style: TextStyle(
                          fontSize: 11,
                          color: subtleColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          } else {
            body = FutureBuilder<String?>(
              future: future,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Crunching the numbers…'),
                    ],
                  );
                } else if (snap.hasError) {
                  return Text(
                    'Error: ${snap.error}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  );
                } else {
                  final text = snap.data;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: SingleChildScrollView(
                          child:
                              text == null
                                  ? const Text(
                                    'No data available for this period.',
                                    style: TextStyle(color: Colors.grey),
                                  )
                                  : MarkdownBody(
                                    data: text,
                                    selectable: true,
                                  ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, size: 11, color: subtleColor),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'AI-generated · may contain errors',
                              style: TextStyle(
                                fontSize: 10,
                                color: subtleColor,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _reportIssue,
                            icon: Icon(Icons.flag_outlined, size: 12, color: subtleColor),
                            label: Text(
                              'Report',
                              style: TextStyle(fontSize: 10, color: subtleColor),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }
              },
            );
          }

          return AlertDialog(
            title: const Text('AI Trends'),
            content: SizedBox(
              width: 320,
              height: future != null ? 400 : null,
              child: body,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    },
  );
}
