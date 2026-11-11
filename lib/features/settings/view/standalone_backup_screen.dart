import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libretrac/features/home/view/home_screen.dart';
import 'package:libretrac/features/substances/model/medication_dose_log.dart';
import 'package:libretrac/providers/db_provider.dart';
import 'package:libretrac/services/backup_service.dart';
import 'package:libretrac/services/web_cache_service.dart';

class StandaloneBackupScreen extends ConsumerStatefulWidget {
  const StandaloneBackupScreen({super.key});

  @override
  ConsumerState<StandaloneBackupScreen> createState() =>
      _StandaloneBackupScreenState();
}

class _StandaloneBackupScreenState
    extends ConsumerState<StandaloneBackupScreen> {
  int _moodCount = 0;
  int _sleepCount = 0;
  int _substanceCount = 0;
  int _logCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final db = ref.read(dbProvider);
      final moods = await db.select(db.moodEntries).get();
      final sleeps = await db.select(db.sleepEntries).get();
      final subs = await db.select(db.substances).get();
      final logs = ref.read(medicationDoseLogsProvider);

      if (mounted) {
        setState(() {
          _moodCount = moods.length;
          _sleepCount = sleeps.length;
          _substanceCount = subs.length;
          _logCount = logs.length;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = ref.watch(customMetricsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Recovery'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.home),
            label: const Text('Dashboard'),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header Card
              Card(
                elevation: 0,
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.security_rounded,
                          size: 32,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LibreTrac Official Backup',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Full local data protection, migration, and recovery engine.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Current Storage Data Summary
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Current Storage Summary',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_isLoading)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.refresh, size: 18),
                              onPressed: _loadStats,
                              tooltip: 'Refresh stats',
                            ),
                        ],
                      ),
                      const Divider(height: 20),
                      _StatRow(
                        icon: Icons.mood,
                        label: 'Mood Check-Ins',
                        value: '$_moodCount entries',
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 8),
                      _StatRow(
                        icon: Icons.bedtime,
                        label: 'Sleep & Dream Logs',
                        value: '$_sleepCount entries',
                        color: Colors.indigo,
                      ),
                      const SizedBox(height: 8),
                      _StatRow(
                        icon: Icons.medication,
                        label: 'Substances & Meds',
                        value: '$_substanceCount tracked',
                        color: Colors.teal,
                      ),
                      const SizedBox(height: 8),
                      _StatRow(
                        icon: Icons.history,
                        label: 'Medication Dose Logs',
                        value: '$_logCount doses logged',
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 8),
                      _StatRow(
                        icon: Icons.tune,
                        label: 'Custom Mood Metrics',
                        value: '${metrics.length} metrics (${metrics.map((m) => m.name).join(', ')})',
                        color: Colors.purple,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Primary Backup Actions
              FilledButton.icon(
                icon: const Icon(Icons.file_download_rounded, size: 22),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'Export Everything (Official .zip)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  await BackupService.exportEverything(context, ref);
                  _loadStats();
                },
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                icon: const Icon(Icons.file_upload_rounded, size: 22),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'Import Backup (.zip or .json)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  await BackupService.importEverything(context, ref);
                  _loadStats();
                },
              ),

              const SizedBox(height: 24),

              // Web Recovery Helpers
              if (kIsWeb) ...[
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.4,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Troubleshooting & Cache Tools',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'If you experience caching delays or script mismatches on mobile browsers, these tools safely refresh your app without touching your database.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text('Purge Cache & Reload'),
                                onPressed: () {
                                  purgeWebCacheAndReload();
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Back to Home Button
              TextButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to LibreTrac Dashboard'),
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
