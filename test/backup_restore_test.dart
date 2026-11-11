import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libretrac/core/database/app_database.dart';
import 'package:libretrac/features/substances/model/medication_dose_log.dart';
import 'package:libretrac/providers/db_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Date Parsing Resilience', () {
    test('parses unix seconds and milliseconds correctly', () {
      final dtSec = parseDateTime(1731333600);
      expect(dtSec, isNotNull);
      expect(dtSec!.year, equals(2024));

      final dtSecDouble = parseDateTime(1731333600.0);
      expect(dtSecDouble, isNotNull);
      expect(dtSecDouble!.year, equals(2024));

      final dtMs = parseDateTime(1731333600000);
      expect(dtMs, isNotNull);
      expect(dtMs!.year, equals(2024));

      final dtStrNum = parseDateTime('1731333600');
      expect(dtStrNum, isNotNull);
      expect(dtStrNum!.year, equals(2024));
    });

    test('parses ISO8601 and custom formatted dates', () {
      final iso = parseDateTime('2024-11-11T14:30:00.000Z');
      expect(iso, isNotNull);
      expect(iso!.year, equals(2024));
      expect(iso.month, equals(11));

      final custom = parseDateTime('2024-11-11 14:30');
      expect(custom, isNotNull);
      expect(custom!.year, equals(2024));
      expect(custom.hour, equals(14));
      expect(custom.minute, equals(30));

      final dateOnly = parseDateTime('2024-11-11');
      expect(dateOnly, isNotNull);
      expect(dateOnly!.year, equals(2024));
    });

    test('returns null for null or invalid input', () {
      expect(parseDateTime(null), isNull);
      expect(parseDateTime(''), isNull);
      expect(parseDateTime('not a date'), isNull);
    });
  });

  group('MedicationDoseLog Parsing Resilience', () {
    test('parses standard camelCase format', () {
      final json = {
        'id': '1_12345',
        'substanceId': 1,
        'substanceName': 'Aspirin',
        'dosage': '100mg',
        'takenAt': '2024-11-11T12:00:00.000',
        'note': 'With breakfast',
      };
      final log = MedicationDoseLog.fromJson(json);
      expect(log.substanceName, equals('Aspirin'));
      expect(log.substanceId, equals(1));
      expect(log.dosage, equals('100mg'));
      expect(log.takenAt.year, equals(2024));
      expect(log.note, equals('With breakfast'));
    });

    test('parses snake_case and export format', () {
      final json = {
        'substance': 'Ibuprofen',
        'substance_id': 2,
        'dosage': '200mg',
        'taken_at': '2024-11-11 15:00',
      };
      final log = MedicationDoseLog.fromJson(json);
      expect(log.substanceName, equals('Ibuprofen'));
      expect(log.substanceId, equals(2));
      expect(log.dosage, equals('200mg'));
      expect(log.takenAt.year, equals(2024));
      expect(log.takenAt.hour, equals(15));
    });

    test('handles epoch timestamps for takenAt', () {
      final json = {
        'substanceName': 'Vitamin C',
        'substanceId': 3,
        'takenAt': 1731333600, // seconds
      };
      final log = MedicationDoseLog.fromJson(json);
      expect(log.substanceName, equals('Vitamin C'));
      expect(log.takenAt.year, equals(2024));
    });
  });

  group('CustomMetric Parsing Resilience', () {
    test('parses integer, hex string, and num color', () {
      final m1 = CustomMetric.fromJson({'name': 'Joy', 'color': 0xFF4CAF50});
      expect(m1.name, equals('Joy'));
      expect(m1.color.value, equals(0xFF4CAF50));

      final m2 = CustomMetric.fromJson({'name': 'Stress', 'color': '#E91E63'});
      expect(m2.name, equals('Stress'));

      final m3 = CustomMetric.fromJson({'name': 'Focus'});
      expect(m3.name, equals('Focus'));
      expect(m3.color, isNotNull);
    });
  });

  group('Database Export and Import Roundtrip', () {
    late AppDatabase db;

    setUp(() {
      SharedPreferences.setMockInitialValues({
        'user_profile_username': 'TestHero',
        'theme_mode': 'dark',
        'custom_metrics': jsonEncode([
          {'name': 'Energy', 'color': 0xFF2196F3},
        ]),
        'medication_dose_logs': jsonEncode([
          {
            'id': '1_9999',
            'substanceId': 1,
            'substanceName': 'Magnesium',
            'dosage': '400mg',
            'takenAt': '2024-11-11T20:00:00.000',
          }
        ]),
      });
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('exports and imports all 8 tables and settings cleanly', () async {
      // 1. Seed database
      await db.into(db.substances).insert(
            SubstancesCompanion.insert(
              name: 'Magnesium',
              dosage: const Value('400mg'),
            ),
          );

      await db.into(db.moodEntries).insert(
            MoodEntriesCompanion.insert(
              timestamp: DateTime(2024, 11, 11, 10, 0),
              notes: const Value('Feeling great'),
              customMetrics: const Value({'Energy': 8}),
            ),
          );

      await db.into(db.sleepEntries).insert(
            SleepEntriesCompanion.insert(
              date: DateTime(2024, 11, 11),
              hoursSlept: 7.5,
              quality: const Value(4),
              dreamJournal: const Value('Flew over mountains #lucid'),
            ),
          );

      // 2. Export
      final exported = await db.exportData();
      expect(exported['substances'], isNotEmpty);
      expect(exported['moodEntries'], isNotEmpty);
      expect(exported['sleepEntries'], isNotEmpty);
      expect(exported['customMetrics'], isNotEmpty);
      expect(exported['medicationDoseLogs'], isNotEmpty);
      expect(exported['userProfile']['username'], equals('TestHero'));
      expect(exported['settings']['themeMode'], equals('dark'));

      // 3. Test resilient import with snake_case and epoch seconds
      final legacyImport = {
        'substances': [
          {
            'id': 10,
            'name': 'Zinc',
            'dosage': '50mg',
            'added_at': 1731333600, // seconds
          }
        ],
        'mood_entries': [
          {
            'id': 20,
            'timestamp': 1731333600, // seconds
            'custom_metrics': '{"Focus": 9}',
            'notes': 'Imported check-in',
          }
        ],
        'sleep_entries': [
          {
            'id': 30,
            'date': 1731333600, // seconds
            'hours_slept': 8.0,
            'quality': 5,
            'dream_journal': 'Restored dream log',
          }
        ],
        'user_profile': {
          'username': 'RestoredUser',
          'blood_type': 'O+',
        },
        'settings': {
          'theme_mode': 'light',
          'streak_count': 14,
        },
      };

      await db.importData(legacyImport);

      // Verify records are queryable
      final subs = await db.select(db.substances).get();
      expect(subs.any((s) => s.name == 'Zinc'), isTrue);

      final moods = await db.select(db.moodEntries).get();
      final mood = moods.firstWhere((m) => m.notes == 'Imported check-in');
      expect(mood.timestamp.year, equals(2024));
      expect(mood.customMetrics?['Focus'], equals(9));

      final sleeps = await db.select(db.sleepEntries).get();
      final sleep = sleeps.firstWhere((s) => s.dreamJournal == 'Restored dream log');
      expect(sleep.date.year, equals(2024));
      expect(sleep.hoursSlept, equals(8.0));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_profile_username'), equals('RestoredUser'));
      expect(prefs.getString('user_profile_blood_type'), equals('O+'));
      expect(prefs.getString('theme_mode'), equals('light'));
      expect(prefs.getInt('streak_count'), equals(14));
    });

    test('restores legacy v1 mood entries with separate energy/happiness columns', () async {
      // Legacy export from LibreTrac v1 where customMetrics didn't exist yet
      final v1Import = {
        'moodEntries': [
          {
            'id': 101,
            'timestamp': '2024-11-10 09:30',
            'energy': 8,
            'happiness': 9,
            'creativity': 7,
            'focus': 6,
            'irritability': 2,
            'anxiety': 3,
            'notes': 'Great morning!',
          },
          {
            'id': 102,
            'date': '2024-11-10', // using 'date' instead of 'timestamp'
            'energy': 4,
            'happiness': 5,
            'notes': 'Evening check-in',
          }
        ]
      };

      await db.importData(v1Import);

      final moods = await db.select(db.moodEntries).get();
      expect(moods.length, equals(2));

      final m1 = moods.firstWhere((m) => m.id == 101);
      expect(m1.notes, equals('Great morning!'));
      expect(m1.customMetrics, isNotNull);
      expect(m1.customMetrics!['Energy'], equals(8));
      expect(m1.customMetrics!['Happiness'], equals(9));
      expect(m1.customMetrics!['Creativity'], equals(7));
      expect(m1.customMetrics!['Focus'], equals(6));
      expect(m1.customMetrics!['Irritability'], equals(2));
      expect(m1.customMetrics!['Anxiety'], equals(3));

      final m2 = moods.firstWhere((m) => m.id == 102);
      expect(m2.notes, equals('Evening check-in'));
      expect(m2.timestamp.year, equals(2024));
      expect(m2.customMetrics!['Energy'], equals(4));
      expect(m2.customMetrics!['Happiness'], equals(5));

      // Verify custom_metrics in SharedPreferences now contains the discovered metrics
      final prefs = await SharedPreferences.getInstance();
      final savedMetricsRaw = prefs.getString('custom_metrics');
      expect(savedMetricsRaw, isNotNull);
      final List savedList = jsonDecode(savedMetricsRaw!);
      final names = savedList.map((e) => e['name']).toSet();
      expect(names.contains('Energy'), isTrue);
      expect(names.contains('Happiness'), isTrue);
      expect(names.contains('Creativity'), isTrue);
      expect(names.contains('Focus'), isTrue);
      expect(names.contains('Irritability'), isTrue);
      expect(names.contains('Anxiety'), isTrue);

      // Verify exportData now exports these mood entries with customMetrics
      final exported = await db.exportData();
      final exportedMoods = exported['moodEntries'] as List;
      expect(exportedMoods.length, equals(2));
      final exportedM1 = exportedMoods.firstWhere((m) => m['id'] == 101);
      expect(exportedM1['customMetrics']['Energy'], equals(8));
    });
  });
}
