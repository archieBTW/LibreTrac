import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:libretrac/core/database/app_database.dart';
import 'package:libretrac/features/substances/add_edit_substance_screen.dart';
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
        'body': 'Please describe the issue with the AI-generated information:\n\n',
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
    final subtleColor = Theme.of(ctx).colorScheme.onSurfaceVariant.withOpacity(0.7);

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
              if (widget.substance.dosage != null)
                Text(
                  'Dosage: ${widget.substance.dosage!}',
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              Text(
                'Started: ${dateFmt.format(widget.substance.addedAt)}',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),

              if (widget.substance.stoppedAt != null)
                Text('Ended: ${dateFmt.format(widget.substance.stoppedAt!)}'),

              if (widget.substance.notes != null) ...[
                const SizedBox(height: 12),
                Text(widget.substance.notes!),
              ],
              const SizedBox(height: 24),
              
              // Subtle AI section header
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 14,
                    color: subtleColor,
                  ),
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
                    icon: Icon(Icons.flag_outlined, size: 14, color: subtleColor),
                    label: Text(
                      'Report issue',
                      style: TextStyle(fontSize: 11, color: subtleColor),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
