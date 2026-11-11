import 'dart:convert';

import 'package:drift/drift.dart';

// class MetricsConverter extends TypeConverter<Map<String, int>, String> {
//   const MetricsConverter();

//   @override
//   Map<String, int> fromSql(String fromDb) {
//     final map = jsonDecode(fromDb);
//     return Map<String, int>.from(map);
//   }

//   @override
//   String toSql(Map<String, int> value) => jsonEncode(value);
// }

class MetricsConverter extends TypeConverter<Map<String, int>, String> {
  const MetricsConverter();

  @override
  Map<String, int> fromSql(String fromDb) {
    try {
      final rawMap = jsonDecode(fromDb);
      if (rawMap is Map) {
        return rawMap.map((key, value) {
          final intVal = (value is num)
              ? value.toInt()
              : (int.tryParse('$value') ?? 0);
          return MapEntry(key.toString(), intVal);
        });
      }
    } catch (_) {}
    return {};
  }

  @override
  String toSql(Map<String, int> value) {
    return jsonEncode(value);
  }
}
