import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:libretrac/core/database/app_database.dart';
import 'package:libretrac/features/substances/add_edit_substance_screen.dart';
import 'package:libretrac/features/substances/model/medication_dose_log.dart';
import 'package:libretrac/features/ai/service/gemini_api_service.dart';

class SubstanceDetailScreen extends ConsumerStatefulWidget {
  const SubstanceDetailScreen({
    required this.substance,
    required this.substances,
    super.key,
  });
  final Substance substance;
  final List<String> substances;

  @override
  ConsumerState<SubstanceDetailScreen> createState() => _SubstanceDetailState();
}

class _SubstanceDetailState extends ConsumerState<SubstanceDetailScreen> {
  late Future<String> _summary;

  @override
  void initState() {
    super.initState();
    _summary = GeminiAPI.instance.getSubstanceProfile(
      widget.substance.name,
      widget.substances,
      notes: widget.substance.notes,
    );
  }

  Future<void> _reportIssue() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'billy@billyrigdon.dev',
      queryParameters: {
        'subject': 'LibreTrac AI Issue Report - ${widget.substance.name}',
        'body':
            'Please describe the issue with the AI-generated information:\n\n',
      },
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch mailto: $e');
    }
  }

  @override
  Widget build(BuildContext ctx) {
    final dateFmt = DateFormat.yMMMd();
    final dateTimeFmt = DateFormat.yMMMd().add_jm();
    final timeFmt = DateFormat.jm();
    final subtleColor = Theme.of(
      ctx,
    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7);
    final medLogs =
        ref
            .watch(medicationDoseLogsProvider)
            .where((l) => l.substanceId == widget.substance.id)
            .toList();
    final now = DateTime.now();
    final todayLogs =
        medLogs.where((l) => isSameCalendarDay(l.takenAt, now)).toList()
          ..sort((a, b) => a.takenAt.compareTo(b.takenAt));
    final dosesPerDay = (ref.watch(
          medicationDosesPerDayProvider,
        )[widget.substance.id] ??
        1)
        .clamp(1, 6);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.substance.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed:
                () => Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder:
                        (_) => AddEditSubstanceScreen(toEdit: widget.substance),
                  ),
                ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.substance.dosage != null &&
                  widget.substance.dosage!.isNotEmpty)
                Text(
                  'Dosage: ${widget.substance.dosage!}',
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              Text(
                'Daily Frequency: ${dosesPerDay}x / day',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              Text(
                'Started: ${dateFmt.format(widget.substance.addedAt)}',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),

              if (widget.substance.stoppedAt != null)
                Text('Ended: ${dateFmt.format(widget.substance.stoppedAt!)}'),

              if (widget.substance.notes != null &&
                  widget.substance.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(widget.substance.notes!),
              ],
              const SizedBox(height: 20),

              // ── Dose History & 7-Day Adherence Card ──────────────
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '7-Day Adherence & Doses',
                              style: Theme.of(ctx).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_calendar_outlined,
                                  size: 20,
                                ),
                                tooltip: 'Log custom date/time',
                                onPressed:
                                    () => showLogDoseDialog(
                                      ctx,
                                      ref,
                                      widget.substance,
                                    ),
                              ),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.check, size: 16),
                                label: const Text('Take Now'),
                                onPressed: () async {
                                  final entry = await ref
                                      .read(medicationDoseLogsProvider.notifier)
                                      .logDose(substance: widget.substance);
                                  if (ctx.mounted) {
                                    showStyledMedToast(
                                      ctx,
                                      message:
                                          'Logged ${widget.substance.name} at ${timeFmt.format(entry.takenAt)}',
                                      onUndo: () {
                                        ref
                                            .read(
                                              medicationDoseLogsProvider
                                                  .notifier,
                                            )
                                            .deleteLog(entry.id);
                                      },
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DailyDoseMarkersRow(
                        substance: widget.substance,
                        todayLogs: todayLogs,
                        dosesPerDay: dosesPerDay,
                      ),
                      const SizedBox(height: 14),
                      SevenDayAdherenceStrip(
                        substance: widget.substance,
                        logs: medLogs,
                      ),
                      if (medLogs.isNotEmpty) ...[
                        const Divider(height: 24),
                        const Text(
                          'Recent Timestamps (tap to edit time):',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 6),
                        for (final log in medLogs.take(10))
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => showEditDoseDialog(ctx, ref, log),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 4,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '• ${dateTimeFmt.format(log.takenAt)}${log.note != null ? ' — ${log.note}' : ''}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 16,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    tooltip: 'Edit time taken',
                                    onPressed:
                                        () => showEditDoseDialog(ctx, ref, log),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 16,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    tooltip: 'Remove timestamp',
                                    onPressed: () {
                                      ref
                                          .read(
                                            medicationDoseLogsProvider.notifier,
                                          )
                                          .deleteLog(log.id);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Subtle AI section header
              Row(
                children: [
                  Icon(Icons.auto_awesome, size: 14, color: subtleColor),
                  const SizedBox(width: 6),
                  Text(
                    'AI-generated · may contain errors',
                    style: TextStyle(
                      fontSize: 12,
                      color: subtleColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              FutureBuilder<String>(
                future: _summary,
                builder: (_, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Text('⚠️ ${snap.error}');
                  }
                  return MarkdownBody(
                    data: snap.data ?? '',
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(ctx)),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Bottom row with disclaimer and report button
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Not medical advice. Consult a healthcare provider.',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: subtleColor,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _reportIssue,
                    icon: Icon(
                      Icons.flag_outlined,
                      size: 14,
                      color: subtleColor,
                    ),
                    label: Text(
                      'Report issue',
                      style: TextStyle(fontSize: 11, color: subtleColor),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
