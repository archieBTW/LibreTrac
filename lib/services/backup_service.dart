import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:archive/archive.dart';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/substances/model/medication_dose_log.dart';
import '../providers/db_provider.dart';
import '../providers/theme_provider.dart';
import 'file_download_service.dart';

class BackupService {
  /// Export all database tables, preferences, custom metrics, and dose logs
  /// into an official LibreTrac .zip archive containing data.json and prefs.json.
  static Future<void> exportEverything(BuildContext ctx, WidgetRef ref) async {
    // 1. Show a loading dialog
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder:
          (dialogCtx) => PopScope(
            canPop: false,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        'Packaging backup data…',
                        style: Theme.of(dialogCtx).textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );

    try {
      final db = ref.read(dbProvider);
      final dbJson = await db.exportData();
      final prefs = await SharedPreferences.getInstance();
      final prefsJson = await db.exportSharedPrefs();

      final archive = Archive();

      // Profile picture export
      final profilePath = prefs.getString('user_profile_picture');
      if (!kIsWeb && profilePath != null && File(profilePath).existsSync()) {
        final profileFile = File(profilePath);
        final bytes = profileFile.readAsBytesSync();
        final ext = profilePath.split('.').last;
        final archiveFile = ArchiveFile('profile.$ext', bytes.length, bytes);
        archive.addFile(archiveFile);
        prefsJson['user_profile_picture'] = 'profile.$ext';
      }

      // Add data and prefs JSON with exact byte lengths
      final dataBytes = utf8.encode(jsonEncode(dbJson));
      final prefsBytes = utf8.encode(jsonEncode(prefsJson));
      archive.addFile(ArchiveFile('data.json', dataBytes.length, dataBytes));
      archive.addFile(ArchiveFile('prefs.json', prefsBytes.length, prefsBytes));

      final zipBytes = ZipEncoder().encode(archive);
      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'libretrac_backup_$dateStr.zip';
      final byteList = Uint8List.fromList(zipBytes);

      // Dismiss the loading dialog
      if (ctx.mounted) {
        Navigator.of(ctx, rootNavigator: true).pop();
      }

      // Present the Backup Ready Dialog
      if (ctx.mounted) {
        await showBackupReadyDialog(
          ctx,
          fileName: fileName,
          bytes: byteList,
          rawJsonText: jsonEncode(dbJson),
        );
      }
    } catch (e, stack) {
      debugPrint('Export error: $e\n$stack');
      if (ctx.mounted) {
        Navigator.of(ctx, rootNavigator: true).pop();
      }
      if (ctx.mounted) {
        showDialog(
          context: ctx,
          builder:
              (dialogCtx) => AlertDialog(
                title: const Text('Export Failed'),
                content: Text('An error occurred during export:\n\n$e'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    }
  }

  /// Show the dialog offering Save/Share, Direct Download, or Copy Raw JSON.
  static Future<void> showBackupReadyDialog(
    BuildContext ctx, {
    required String fileName,
    required Uint8List bytes,
    required String rawJsonText,
  }) async {
    final sizeKb = (bytes.lengthInBytes / 1024).toStringAsFixed(1);
    final canShare = kIsWeb ? canShareFilesOnWeb() : true;
    final isMobile =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    await showDialog<void>(
      context: ctx,
      builder: (dialogCtx) {
        final theme = Theme.of(dialogCtx);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              Icon(
                Icons.inventory_2_rounded,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Backup Ready',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.folder_zip_outlined,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              fileName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Size: $sizeKb KB',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'All check-ins, mood & sleep entries, dream interpretations, medication doses, custom metrics, and preferences are packaged.',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                if (canShare) ...[
                  FilledButton.icon(
                    icon: const Icon(Icons.share_rounded, size: 20),
                    label: Text(
                      isMobile
                          ? 'Save to Device / Share'
                          : 'Share Backup File',
                    ),
                    onPressed: () async {
                      Navigator.pop(dialogCtx);
                      if (kIsWeb) {
                        final ok = await shareFileOnWeb(
                          fileName,
                          bytes,
                          title: 'LibreTrac Backup',
                        );
                        if (!ok) {
                          await downloadFileToBrowser(fileName, bytes);
                        }
                      } else {
                        final tmpDir = await getTemporaryDirectory();
                        final file = File('${tmpDir.path}/$fileName');
                        await file.writeAsBytes(bytes);
                        await Share.shareXFiles(
                          [XFile(file.path, mimeType: 'application/zip')],
                          text: 'LibreTrac backup archive: $fileName',
                        );
                      }
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text(
                              isMobile
                                  ? 'Share dialog opened. Select "Save to device" or your desired app.'
                                  : 'Backup shared: $fileName',
                            ),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.download_rounded, size: 20),
                    label: const Text('Direct Download (.zip)'),
                    onPressed: () async {
                      Navigator.pop(dialogCtx);
                      if (kIsWeb) {
                        final success = await downloadFileToBrowser(
                          fileName,
                          bytes,
                        );
                        if (!success) {
                          openFileInNewTabOnWeb(fileName, bytes);
                        }
                      } else {
                        final tmpDir = await getTemporaryDirectory();
                        final file = File('${tmpDir.path}/$fileName');
                        await file.writeAsBytes(bytes);
                        await Share.shareXFiles([XFile(file.path)]);
                      }
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text('Downloading $fileName…'),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                    },
                  ),
                ] else ...[
                  FilledButton.icon(
                    icon: const Icon(Icons.download_rounded, size: 20),
                    label: const Text('Download Backup (.zip)'),
                    onPressed: () async {
                      Navigator.pop(dialogCtx);
                      if (kIsWeb) {
                        await downloadFileToBrowser(fileName, bytes);
                      } else {
                        final tmpDir = await getTemporaryDirectory();
                        final file = File('${tmpDir.path}/$fileName');
                        await file.writeAsBytes(bytes);
                        await Share.shareXFiles([XFile(file.path)]);
                      }
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text('Backup downloaded: $fileName'),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                    },
                  ),
                ],
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.code_rounded, size: 20),
                  label: const Text('Direct Download (.json)'),
                  onPressed: () async {
                    Navigator.pop(dialogCtx);
                    final jsonBytes =
                        Uint8List.fromList(utf8.encode(rawJsonText));
                    final jsonFileName = fileName.replaceAll('.zip', '.json');
                    if (kIsWeb) {
                      await downloadFileToBrowser(
                        jsonFileName,
                        jsonBytes,
                        mimeType: 'application/json',
                      );
                    } else {
                      final tmpDir = await getTemporaryDirectory();
                      final file = File('${tmpDir.path}/$jsonFileName');
                      await file.writeAsBytes(jsonBytes);
                      await Share.shareXFiles([XFile(file.path)]);
                    }
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text('Downloading $jsonFileName…'),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text(
                    'Copy raw JSON to clipboard',
                    style: TextStyle(fontSize: 12),
                  ),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: rawJsonText));
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Raw data JSON copied to clipboard!'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  /// Import backup (.zip or .json) file safely and reload all active providers.
  static Future<void> importEverything(BuildContext ctx, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip', 'json'],
      withData: kIsWeb,
    );
    if (result == null) return;

    final ok = await showDialog<bool>(
      context: ctx,
      builder:
          (confirmCtx) => AlertDialog(
            title: const Text('Confirm Import'),
            content: const Text(
              'This will overwrite all data and preferences with the selected backup file. Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(confirmCtx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(confirmCtx, true),
                child: const Text('Import'),
              ),
            ],
          ),
    );

    if (ok != true) return;

    try {
      final Uint8List fileBytes;
      final String fileName = result.files.single.name;
      if (kIsWeb) {
        fileBytes = result.files.single.bytes!;
      } else {
        final zipFile = File(result.files.single.path!);
        fileBytes = zipFile.readAsBytesSync();
      }

      Map<String, dynamic>? dataJson;
      Map<String, dynamic>? prefsJson;

      final isZip =
          fileBytes.length >= 4 &&
          fileBytes[0] == 0x50 &&
          fileBytes[1] == 0x4B &&
          fileBytes[2] == 0x03 &&
          fileBytes[3] == 0x04;

      if (isZip || fileName.toLowerCase().endsWith('.zip')) {
        final archive = ZipDecoder().decodeBytes(fileBytes);

        final dataFile = archive.files.firstWhereOrNull((f) => f.name == 'data.json');
        final prefsFile = archive.files.firstWhereOrNull((f) => f.name == 'prefs.json');

        if (dataFile != null) {
          dataJson =
              jsonDecode(utf8.decode(dataFile.content as List<int>))
                  as Map<String, dynamic>;
        }
        if (prefsFile != null) {
          prefsJson =
              jsonDecode(utf8.decode(prefsFile.content as List<int>))
                  as Map<String, dynamic>;
        }

        final profileFile = archive.files.firstWhereOrNull(
          (f) => f.name.startsWith('profile.'),
        );

        if (profileFile != null && !kIsWeb) {
          final tmpDir = await getTemporaryDirectory();
          final ext = profileFile.name.split('.').last;
          final newPath = '${tmpDir.path}/restored_profile.$ext';
          File(newPath).writeAsBytesSync(profileFile.content as List<int>);

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_profile_picture', newPath);
        }
      } else {
        // Handle .json backup file
        final rawText = utf8.decode(fileBytes);
        final decoded = jsonDecode(rawText);
        if (decoded is Map<String, dynamic>) {
          if (kIsWeb && decoded.containsKey('indexedDB')) {
            final extractedJsonStr =
                await extractStorageBackupDataOnWeb(rawText);
            if (extractedJsonStr != null && extractedJsonStr.isNotEmpty) {
              try {
                final extractedMap = jsonDecode(extractedJsonStr);
                if (extractedMap is Map<String, dynamic>) {
                  dataJson = extractedMap;
                  if (extractedMap.containsKey('prefs') &&
                      extractedMap['prefs'] is Map) {
                    prefsJson = Map<String, dynamic>.from(
                      extractedMap['prefs'] as Map,
                    );
                  }
                }
              } catch (e) {
                debugPrint('Extracted backup parse warning: $e');
              }
            }

            if (dataJson == null) {
              final ok = await restoreStorageBackupOnWeb(rawText);
              if (ok) {
                await ref.read(customMetricsProvider.notifier).reload();
                await ref.read(userProfileProvider.notifier).reload();
                await ref.read(themeModeProvider.notifier).reload();
                await ref.read(accentColorProvider.notifier).reload();
                await ref.read(medicationDoseLogsProvider.notifier).reload();
                await ref.read(substanceOrderProvider.notifier).reload();
                await ref.read(medicationDosesPerDayProvider.notifier).reload();

                ref.invalidate(journalEntriesStreamProvider);
                ref.invalidate(filteredMoodEntriesProvider);
                ref.invalidate(moodEntriesStreamProvider);
                ref.invalidate(sleepStreamProvider);
                ref.invalidate(substancesStreamProvider);
                ref.invalidate(activeSubstancesStreamProvider);
                ref.invalidate(pastSubstancesStreamProvider);
                ref.invalidate(weeklySleepStatsProvider);
                ref.invalidate(reactionResultsStreamProvider);
                ref.invalidate(stroopResultsStreamProvider);
                ref.invalidate(goNoGoResultsStreamProvider);
                ref.invalidate(digitSpanResultsStreamProvider);
                ref.invalidate(symbolSearchResultsStreamProvider);

                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Storage backup restored successfully with all check-ins and preferences!',
                      ),
                    ),
                  );
                }
                return;
              }
            }
          }

          if (decoded.containsKey('localStorage') &&
              decoded['localStorage'] is Map) {
            prefsJson = Map<String, dynamic>.from(
              decoded['localStorage'] as Map,
            );
          }
          if (decoded.containsKey('prefs') && decoded['prefs'] is Map) {
            prefsJson = Map<String, dynamic>.from(decoded['prefs'] as Map);
          }
          if (decoded.containsKey('data') && decoded['data'] is Map) {
            dataJson = Map<String, dynamic>.from(decoded['data'] as Map);
          } else if (decoded.containsKey('moodEntries') ||
              decoded.containsKey('mood_entries') ||
              decoded.containsKey('substances') ||
              decoded.containsKey('sleepEntries') ||
              decoded.containsKey('sleep_entries')) {
            dataJson = decoded;
          }
          if (dataJson == null && prefsJson == null) {
            prefsJson = decoded;
          }
        }
      }

      // Import SharedPreferences if present
      if (prefsJson != null) {
        final prefs = await SharedPreferences.getInstance();
        for (final entry in prefsJson.entries) {
          var key = entry.key;
          if (key.startsWith('flutter.')) {
            key = key.substring('flutter.'.length);
          }
          final value = entry.value;

          if (value is bool) {
            await prefs.setBool(key, value);
          } else if (value is int) {
            await prefs.setInt(key, value);
          } else if (value is double) {
            await prefs.setDouble(key, value);
          } else if (value is String) {
            await prefs.setString(key, value);
          } else if (value is List && value.every((e) => e is String)) {
            await prefs.setStringList(key, List<String>.from(value));
          } else if (value is Map || value is List) {
            await prefs.setString(key, jsonEncode(value));
          }
        }

        if (dataJson == null) {
          dataJson = {};
          if (prefsJson.containsKey('custom_metrics') ||
              prefsJson.containsKey('flutter.custom_metrics')) {
            final raw =
                prefsJson['custom_metrics'] ?? prefsJson['flutter.custom_metrics'];
            if (raw is String) {
              try {
                dataJson['customMetrics'] = jsonDecode(raw);
              } catch (_) {}
            } else if (raw is List) {
              dataJson['customMetrics'] = raw;
            }
          }
          if (prefsJson.containsKey('medication_dose_logs') ||
              prefsJson.containsKey('flutter.medication_dose_logs')) {
            final raw =
                prefsJson['medication_dose_logs'] ??
                prefsJson['flutter.medication_dose_logs'];
            if (raw is List) {
              dataJson['medicationDoseLogs'] = raw;
            } else if (raw is String && raw.isNotEmpty) {
              try {
                final d = jsonDecode(raw);
                if (d is List) dataJson['medicationDoseLogs'] = d;
              } catch (_) {}
            }
          }
        }
      }

      // Import DB if present
      if (dataJson != null) {
        await ref.read(dbProvider).importData(dataJson);
      }

      // Reload providers AFTER data is in place
      await ref.read(customMetricsProvider.notifier).reload();
      await ref.read(userProfileProvider.notifier).reload();
      await ref.read(themeModeProvider.notifier).reload();
      await ref.read(accentColorProvider.notifier).reload();
      await ref.read(medicationDoseLogsProvider.notifier).reload();
      await ref.read(substanceOrderProvider.notifier).reload();
      await ref.read(medicationDosesPerDayProvider.notifier).reload();

      // Force refresh of all stream data across screens
      ref.invalidate(journalEntriesStreamProvider);
      ref.invalidate(filteredMoodEntriesProvider);
      ref.invalidate(moodEntriesStreamProvider);
      ref.invalidate(sleepStreamProvider);
      ref.invalidate(substancesStreamProvider);
      ref.invalidate(activeSubstancesStreamProvider);
      ref.invalidate(pastSubstancesStreamProvider);
      ref.invalidate(weeklySleepStatsProvider);
      ref.invalidate(reactionResultsStreamProvider);
      ref.invalidate(stroopResultsStreamProvider);
      ref.invalidate(goNoGoResultsStreamProvider);
      ref.invalidate(digitSpanResultsStreamProvider);
      ref.invalidate(symbolSearchResultsStreamProvider);

      if (ctx.mounted) {
        ScaffoldMessenger.of(
          ctx,
        ).showSnackBar(const SnackBar(content: Text('Import complete! All records restored.')));
      }
    } catch (e) {
      if (ctx.mounted) {
        showDialog(
          context: ctx,
          builder:
              (errorCtx) => AlertDialog(
                title: const Text('Import Failed'),
                content: Text('Failed to import backup:\n\n$e'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(errorCtx),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    }
  }
}
