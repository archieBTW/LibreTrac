// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SubstancesTable extends Substances
    with TableInfo<$SubstancesTable, Substance> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubstancesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dosageMeta = const VerificationMeta('dosage');
  @override
  late final GeneratedColumn<String> dosage = GeneratedColumn<String>(
    'dosage',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _stoppedAtMeta = const VerificationMeta(
    'stoppedAt',
  );
  @override
  late final GeneratedColumn<DateTime> stoppedAt = GeneratedColumn<DateTime>(
    'stopped_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    dosage,
    notes,
    addedAt,
    stoppedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'substances';
  @override
  VerificationContext validateIntegrity(
    Insertable<Substance> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('dosage')) {
      context.handle(
        _dosageMeta,
        dosage.isAcceptableOrUnknown(data['dosage']!, _dosageMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    }
    if (data.containsKey('stopped_at')) {
      context.handle(
        _stoppedAtMeta,
        stoppedAt.isAcceptableOrUnknown(data['stopped_at']!, _stoppedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Substance map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Substance(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      dosage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dosage'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      addedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}added_at'],
          )!,
      stoppedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}stopped_at'],
      ),
    );
  }

  @override
  $SubstancesTable createAlias(String alias) {
    return $SubstancesTable(attachedDatabase, alias);
  }
}

class Substance extends DataClass implements Insertable<Substance> {
  final int id;
  final String name;
  final String? dosage;
  final String? notes;
  final DateTime addedAt;
  final DateTime? stoppedAt;
  const Substance({
    required this.id,
    required this.name,
    this.dosage,
    this.notes,
    required this.addedAt,
    this.stoppedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || dosage != null) {
      map['dosage'] = Variable<String>(dosage);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['added_at'] = Variable<DateTime>(addedAt);
    if (!nullToAbsent || stoppedAt != null) {
      map['stopped_at'] = Variable<DateTime>(stoppedAt);
    }
    return map;
  }

  SubstancesCompanion toCompanion(bool nullToAbsent) {
    return SubstancesCompanion(
      id: Value(id),
      name: Value(name),
      dosage:
          dosage == null && nullToAbsent ? const Value.absent() : Value(dosage),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      addedAt: Value(addedAt),
      stoppedAt:
          stoppedAt == null && nullToAbsent
              ? const Value.absent()
              : Value(stoppedAt),
    );
  }

  factory Substance.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Substance(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      dosage: serializer.fromJson<String?>(json['dosage']),
      notes: serializer.fromJson<String?>(json['notes']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
      stoppedAt: serializer.fromJson<DateTime?>(json['stoppedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'dosage': serializer.toJson<String?>(dosage),
      'notes': serializer.toJson<String?>(notes),
      'addedAt': serializer.toJson<DateTime>(addedAt),
      'stoppedAt': serializer.toJson<DateTime?>(stoppedAt),
    };
  }

  Substance copyWith({
    int? id,
    String? name,
    Value<String?> dosage = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? addedAt,
    Value<DateTime?> stoppedAt = const Value.absent(),
  }) => Substance(
    id: id ?? this.id,
    name: name ?? this.name,
    dosage: dosage.present ? dosage.value : this.dosage,
    notes: notes.present ? notes.value : this.notes,
    addedAt: addedAt ?? this.addedAt,
    stoppedAt: stoppedAt.present ? stoppedAt.value : this.stoppedAt,
  );
  Substance copyWithCompanion(SubstancesCompanion data) {
    return Substance(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      dosage: data.dosage.present ? data.dosage.value : this.dosage,
      notes: data.notes.present ? data.notes.value : this.notes,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      stoppedAt: data.stoppedAt.present ? data.stoppedAt.value : this.stoppedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Substance(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('dosage: $dosage, ')
          ..write('notes: $notes, ')
          ..write('addedAt: $addedAt, ')
          ..write('stoppedAt: $stoppedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, dosage, notes, addedAt, stoppedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Substance &&
          other.id == this.id &&
          other.name == this.name &&
          other.dosage == this.dosage &&
          other.notes == this.notes &&
          other.addedAt == this.addedAt &&
          other.stoppedAt == this.stoppedAt);
}

class SubstancesCompanion extends UpdateCompanion<Substance> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> dosage;
  final Value<String?> notes;
  final Value<DateTime> addedAt;
  final Value<DateTime?> stoppedAt;
  const SubstancesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.dosage = const Value.absent(),
    this.notes = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.stoppedAt = const Value.absent(),
  });
  SubstancesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.dosage = const Value.absent(),
    this.notes = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.stoppedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Substance> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? dosage,
    Expression<String>? notes,
    Expression<DateTime>? addedAt,
    Expression<DateTime>? stoppedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (dosage != null) 'dosage': dosage,
      if (notes != null) 'notes': notes,
      if (addedAt != null) 'added_at': addedAt,
      if (stoppedAt != null) 'stopped_at': stoppedAt,
    });
  }

  SubstancesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? dosage,
    Value<String?>? notes,
    Value<DateTime>? addedAt,
    Value<DateTime?>? stoppedAt,
  }) {
    return SubstancesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      notes: notes ?? this.notes,
      addedAt: addedAt ?? this.addedAt,
      stoppedAt: stoppedAt ?? this.stoppedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (dosage.present) {
      map['dosage'] = Variable<String>(dosage.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (stoppedAt.present) {
      map['stopped_at'] = Variable<DateTime>(stoppedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubstancesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('dosage: $dosage, ')
          ..write('notes: $notes, ')
          ..write('addedAt: $addedAt, ')
          ..write('stoppedAt: $stoppedAt')
          ..write(')'))
        .toString();
  }
}

class $MoodEntriesTable extends MoodEntries
    with TableInfo<$MoodEntriesTable, MoodEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MoodEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Map<String, int>?, String>
  customMetrics = GeneratedColumn<String>(
    'custom_metrics',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<Map<String, int>?>(
    $MoodEntriesTable.$convertercustomMetricsn,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, timestamp, customMetrics, notes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mood_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<MoodEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MoodEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MoodEntry(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      timestamp:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}timestamp'],
          )!,
      customMetrics: $MoodEntriesTable.$convertercustomMetricsn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}custom_metrics'],
        ),
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $MoodEntriesTable createAlias(String alias) {
    return $MoodEntriesTable(attachedDatabase, alias);
  }

  static TypeConverter<Map<String, int>, String> $convertercustomMetrics =
      const MetricsConverter();
  static TypeConverter<Map<String, int>?, String?> $convertercustomMetricsn =
      NullAwareTypeConverter.wrap($convertercustomMetrics);
}

class MoodEntry extends DataClass implements Insertable<MoodEntry> {
  final int id;
  final DateTime timestamp;
  final Map<String, int>? customMetrics;
  final String? notes;
  const MoodEntry({
    required this.id,
    required this.timestamp,
    this.customMetrics,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['timestamp'] = Variable<DateTime>(timestamp);
    if (!nullToAbsent || customMetrics != null) {
      map['custom_metrics'] = Variable<String>(
        $MoodEntriesTable.$convertercustomMetricsn.toSql(customMetrics),
      );
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  MoodEntriesCompanion toCompanion(bool nullToAbsent) {
    return MoodEntriesCompanion(
      id: Value(id),
      timestamp: Value(timestamp),
      customMetrics:
          customMetrics == null && nullToAbsent
              ? const Value.absent()
              : Value(customMetrics),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
    );
  }

  factory MoodEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MoodEntry(
      id: serializer.fromJson<int>(json['id']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      customMetrics: serializer.fromJson<Map<String, int>?>(
        json['customMetrics'],
      ),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'customMetrics': serializer.toJson<Map<String, int>?>(customMetrics),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  MoodEntry copyWith({
    int? id,
    DateTime? timestamp,
    Value<Map<String, int>?> customMetrics = const Value.absent(),
    Value<String?> notes = const Value.absent(),
  }) => MoodEntry(
    id: id ?? this.id,
    timestamp: timestamp ?? this.timestamp,
    customMetrics:
        customMetrics.present ? customMetrics.value : this.customMetrics,
    notes: notes.present ? notes.value : this.notes,
  );
  MoodEntry copyWithCompanion(MoodEntriesCompanion data) {
    return MoodEntry(
      id: data.id.present ? data.id.value : this.id,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      customMetrics:
          data.customMetrics.present
              ? data.customMetrics.value
              : this.customMetrics,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MoodEntry(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('customMetrics: $customMetrics, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, timestamp, customMetrics, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MoodEntry &&
          other.id == this.id &&
          other.timestamp == this.timestamp &&
          other.customMetrics == this.customMetrics &&
          other.notes == this.notes);
}

class MoodEntriesCompanion extends UpdateCompanion<MoodEntry> {
  final Value<int> id;
  final Value<DateTime> timestamp;
  final Value<Map<String, int>?> customMetrics;
  final Value<String?> notes;
  const MoodEntriesCompanion({
    this.id = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.customMetrics = const Value.absent(),
    this.notes = const Value.absent(),
  });
  MoodEntriesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime timestamp,
    this.customMetrics = const Value.absent(),
    this.notes = const Value.absent(),
  }) : timestamp = Value(timestamp);
  static Insertable<MoodEntry> custom({
    Expression<int>? id,
    Expression<DateTime>? timestamp,
    Expression<String>? customMetrics,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timestamp != null) 'timestamp': timestamp,
      if (customMetrics != null) 'custom_metrics': customMetrics,
      if (notes != null) 'notes': notes,
    });
  }

  MoodEntriesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? timestamp,
    Value<Map<String, int>?>? customMetrics,
    Value<String?>? notes,
  }) {
    return MoodEntriesCompanion(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      customMetrics: customMetrics ?? this.customMetrics,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (customMetrics.present) {
      map['custom_metrics'] = Variable<String>(
        $MoodEntriesTable.$convertercustomMetricsn.toSql(customMetrics.value),
      );
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MoodEntriesCompanion(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('customMetrics: $customMetrics, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $ReactionResultsTable extends ReactionResults
    with TableInfo<$ReactionResultsTable, ReactionResult> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReactionResultsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _averageTimeMeta = const VerificationMeta(
    'averageTime',
  );
  @override
  late final GeneratedColumn<double> averageTime = GeneratedColumn<double>(
    'average_time',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fastestMeta = const VerificationMeta(
    'fastest',
  );
  @override
  late final GeneratedColumn<double> fastest = GeneratedColumn<double>(
    'fastest',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slowestMeta = const VerificationMeta(
    'slowest',
  );
  @override
  late final GeneratedColumn<double> slowest = GeneratedColumn<double>(
    'slowest',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    timestamp,
    averageTime,
    fastest,
    slowest,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reaction_results';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReactionResult> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('average_time')) {
      context.handle(
        _averageTimeMeta,
        averageTime.isAcceptableOrUnknown(
          data['average_time']!,
          _averageTimeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_averageTimeMeta);
    }
    if (data.containsKey('fastest')) {
      context.handle(
        _fastestMeta,
        fastest.isAcceptableOrUnknown(data['fastest']!, _fastestMeta),
      );
    } else if (isInserting) {
      context.missing(_fastestMeta);
    }
    if (data.containsKey('slowest')) {
      context.handle(
        _slowestMeta,
        slowest.isAcceptableOrUnknown(data['slowest']!, _slowestMeta),
      );
    } else if (isInserting) {
      context.missing(_slowestMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReactionResult map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReactionResult(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      timestamp:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}timestamp'],
          )!,
      averageTime:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}average_time'],
          )!,
      fastest:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}fastest'],
          )!,
      slowest:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}slowest'],
          )!,
    );
  }

  @override
  $ReactionResultsTable createAlias(String alias) {
    return $ReactionResultsTable(attachedDatabase, alias);
  }
}

class ReactionResult extends DataClass implements Insertable<ReactionResult> {
  final int id;
  final DateTime timestamp;
  final double averageTime;
  final double fastest;
  final double slowest;
  const ReactionResult({
    required this.id,
    required this.timestamp,
    required this.averageTime,
    required this.fastest,
    required this.slowest,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['average_time'] = Variable<double>(averageTime);
    map['fastest'] = Variable<double>(fastest);
    map['slowest'] = Variable<double>(slowest);
    return map;
  }

  ReactionResultsCompanion toCompanion(bool nullToAbsent) {
    return ReactionResultsCompanion(
      id: Value(id),
      timestamp: Value(timestamp),
      averageTime: Value(averageTime),
      fastest: Value(fastest),
      slowest: Value(slowest),
    );
  }

  factory ReactionResult.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReactionResult(
      id: serializer.fromJson<int>(json['id']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      averageTime: serializer.fromJson<double>(json['averageTime']),
      fastest: serializer.fromJson<double>(json['fastest']),
      slowest: serializer.fromJson<double>(json['slowest']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'averageTime': serializer.toJson<double>(averageTime),
      'fastest': serializer.toJson<double>(fastest),
      'slowest': serializer.toJson<double>(slowest),
    };
  }

  ReactionResult copyWith({
    int? id,
    DateTime? timestamp,
    double? averageTime,
    double? fastest,
    double? slowest,
  }) => ReactionResult(
    id: id ?? this.id,
    timestamp: timestamp ?? this.timestamp,
    averageTime: averageTime ?? this.averageTime,
    fastest: fastest ?? this.fastest,
    slowest: slowest ?? this.slowest,
  );
  ReactionResult copyWithCompanion(ReactionResultsCompanion data) {
    return ReactionResult(
      id: data.id.present ? data.id.value : this.id,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      averageTime:
          data.averageTime.present ? data.averageTime.value : this.averageTime,
      fastest: data.fastest.present ? data.fastest.value : this.fastest,
      slowest: data.slowest.present ? data.slowest.value : this.slowest,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReactionResult(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('averageTime: $averageTime, ')
          ..write('fastest: $fastest, ')
          ..write('slowest: $slowest')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, timestamp, averageTime, fastest, slowest);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReactionResult &&
          other.id == this.id &&
          other.timestamp == this.timestamp &&
          other.averageTime == this.averageTime &&
          other.fastest == this.fastest &&
          other.slowest == this.slowest);
}

class ReactionResultsCompanion extends UpdateCompanion<ReactionResult> {
  final Value<int> id;
  final Value<DateTime> timestamp;
  final Value<double> averageTime;
  final Value<double> fastest;
  final Value<double> slowest;
  const ReactionResultsCompanion({
    this.id = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.averageTime = const Value.absent(),
    this.fastest = const Value.absent(),
    this.slowest = const Value.absent(),
  });
  ReactionResultsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime timestamp,
    required double averageTime,
    required double fastest,
    required double slowest,
  }) : timestamp = Value(timestamp),
       averageTime = Value(averageTime),
       fastest = Value(fastest),
       slowest = Value(slowest);
  static Insertable<ReactionResult> custom({
    Expression<int>? id,
    Expression<DateTime>? timestamp,
    Expression<double>? averageTime,
    Expression<double>? fastest,
    Expression<double>? slowest,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timestamp != null) 'timestamp': timestamp,
      if (averageTime != null) 'average_time': averageTime,
      if (fastest != null) 'fastest': fastest,
      if (slowest != null) 'slowest': slowest,
    });
  }

  ReactionResultsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? timestamp,
    Value<double>? averageTime,
    Value<double>? fastest,
    Value<double>? slowest,
  }) {
    return ReactionResultsCompanion(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      averageTime: averageTime ?? this.averageTime,
      fastest: fastest ?? this.fastest,
      slowest: slowest ?? this.slowest,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (averageTime.present) {
      map['average_time'] = Variable<double>(averageTime.value);
    }
    if (fastest.present) {
      map['fastest'] = Variable<double>(fastest.value);
    }
    if (slowest.present) {
      map['slowest'] = Variable<double>(slowest.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReactionResultsCompanion(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('averageTime: $averageTime, ')
          ..write('fastest: $fastest, ')
          ..write('slowest: $slowest')
          ..write(')'))
        .toString();
  }
}

class $SleepEntriesTable extends SleepEntries
    with TableInfo<$SleepEntriesTable, SleepEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SleepEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hoursSleptMeta = const VerificationMeta(
    'hoursSlept',
  );
  @override
  late final GeneratedColumn<double> hoursSlept = GeneratedColumn<double>(
    'hours_slept',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dreamJournalMeta = const VerificationMeta(
    'dreamJournal',
  );
  @override
  late final GeneratedColumn<String> dreamJournal = GeneratedColumn<String>(
    'dream_journal',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _qualityMeta = const VerificationMeta(
    'quality',
  );
  @override
  late final GeneratedColumn<int> quality = GeneratedColumn<int>(
    'quality',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    hoursSlept,
    dreamJournal,
    quality,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sleep_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SleepEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('hours_slept')) {
      context.handle(
        _hoursSleptMeta,
        hoursSlept.isAcceptableOrUnknown(data['hours_slept']!, _hoursSleptMeta),
      );
    } else if (isInserting) {
      context.missing(_hoursSleptMeta);
    }
    if (data.containsKey('dream_journal')) {
      context.handle(
        _dreamJournalMeta,
        dreamJournal.isAcceptableOrUnknown(
          data['dream_journal']!,
          _dreamJournalMeta,
        ),
      );
    }
    if (data.containsKey('quality')) {
      context.handle(
        _qualityMeta,
        quality.isAcceptableOrUnknown(data['quality']!, _qualityMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SleepEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SleepEntry(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      date:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}date'],
          )!,
      hoursSlept:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}hours_slept'],
          )!,
      dreamJournal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dream_journal'],
      ),
      quality:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}quality'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
    );
  }

  @override
  $SleepEntriesTable createAlias(String alias) {
    return $SleepEntriesTable(attachedDatabase, alias);
  }
}

class SleepEntry extends DataClass implements Insertable<SleepEntry> {
  final int id;

  /// Date you WOKE UP (so each night maps to the following day)
  final DateTime date;
  final double hoursSlept;
  final String? dreamJournal;
  final int quality;
  final DateTime createdAt;
  const SleepEntry({
    required this.id,
    required this.date,
    required this.hoursSlept,
    this.dreamJournal,
    required this.quality,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['hours_slept'] = Variable<double>(hoursSlept);
    if (!nullToAbsent || dreamJournal != null) {
      map['dream_journal'] = Variable<String>(dreamJournal);
    }
    map['quality'] = Variable<int>(quality);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SleepEntriesCompanion toCompanion(bool nullToAbsent) {
    return SleepEntriesCompanion(
      id: Value(id),
      date: Value(date),
      hoursSlept: Value(hoursSlept),
      dreamJournal:
          dreamJournal == null && nullToAbsent
              ? const Value.absent()
              : Value(dreamJournal),
      quality: Value(quality),
      createdAt: Value(createdAt),
    );
  }

  factory SleepEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SleepEntry(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      hoursSlept: serializer.fromJson<double>(json['hoursSlept']),
      dreamJournal: serializer.fromJson<String?>(json['dreamJournal']),
      quality: serializer.fromJson<int>(json['quality']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'hoursSlept': serializer.toJson<double>(hoursSlept),
      'dreamJournal': serializer.toJson<String?>(dreamJournal),
      'quality': serializer.toJson<int>(quality),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SleepEntry copyWith({
    int? id,
    DateTime? date,
    double? hoursSlept,
    Value<String?> dreamJournal = const Value.absent(),
    int? quality,
    DateTime? createdAt,
  }) => SleepEntry(
    id: id ?? this.id,
    date: date ?? this.date,
    hoursSlept: hoursSlept ?? this.hoursSlept,
    dreamJournal: dreamJournal.present ? dreamJournal.value : this.dreamJournal,
    quality: quality ?? this.quality,
    createdAt: createdAt ?? this.createdAt,
  );
  SleepEntry copyWithCompanion(SleepEntriesCompanion data) {
    return SleepEntry(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      hoursSlept:
          data.hoursSlept.present ? data.hoursSlept.value : this.hoursSlept,
      dreamJournal:
          data.dreamJournal.present
              ? data.dreamJournal.value
              : this.dreamJournal,
      quality: data.quality.present ? data.quality.value : this.quality,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SleepEntry(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('hoursSlept: $hoursSlept, ')
          ..write('dreamJournal: $dreamJournal, ')
          ..write('quality: $quality, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, date, hoursSlept, dreamJournal, quality, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SleepEntry &&
          other.id == this.id &&
          other.date == this.date &&
          other.hoursSlept == this.hoursSlept &&
          other.dreamJournal == this.dreamJournal &&
          other.quality == this.quality &&
          other.createdAt == this.createdAt);
}

class SleepEntriesCompanion extends UpdateCompanion<SleepEntry> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<double> hoursSlept;
  final Value<String?> dreamJournal;
  final Value<int> quality;
  final Value<DateTime> createdAt;
  const SleepEntriesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.hoursSlept = const Value.absent(),
    this.dreamJournal = const Value.absent(),
    this.quality = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SleepEntriesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required double hoursSlept,
    this.dreamJournal = const Value.absent(),
    this.quality = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : date = Value(date),
       hoursSlept = Value(hoursSlept);
  static Insertable<SleepEntry> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<double>? hoursSlept,
    Expression<String>? dreamJournal,
    Expression<int>? quality,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (hoursSlept != null) 'hours_slept': hoursSlept,
      if (dreamJournal != null) 'dream_journal': dreamJournal,
      if (quality != null) 'quality': quality,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SleepEntriesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? date,
    Value<double>? hoursSlept,
    Value<String?>? dreamJournal,
    Value<int>? quality,
    Value<DateTime>? createdAt,
  }) {
    return SleepEntriesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      hoursSlept: hoursSlept ?? this.hoursSlept,
      dreamJournal: dreamJournal ?? this.dreamJournal,
      quality: quality ?? this.quality,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (hoursSlept.present) {
      map['hours_slept'] = Variable<double>(hoursSlept.value);
    }
    if (dreamJournal.present) {
      map['dream_journal'] = Variable<String>(dreamJournal.value);
    }
    if (quality.present) {
      map['quality'] = Variable<int>(quality.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SleepEntriesCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('hoursSlept: $hoursSlept, ')
          ..write('dreamJournal: $dreamJournal, ')
          ..write('quality: $quality, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $StroopResultsTable extends StroopResults
    with TableInfo<$StroopResultsTable, StroopResult> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StroopResultsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _congruentMsMeta = const VerificationMeta(
    'congruentMs',
  );
  @override
  late final GeneratedColumn<double> congruentMs = GeneratedColumn<double>(
    'congruent_ms',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _incongruentMsMeta = const VerificationMeta(
    'incongruentMs',
  );
  @override
  late final GeneratedColumn<double> incongruentMs = GeneratedColumn<double>(
    'incongruent_ms',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deltaMsMeta = const VerificationMeta(
    'deltaMs',
  );
  @override
  late final GeneratedColumn<double> deltaMs = GeneratedColumn<double>(
    'delta_ms',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    timestamp,
    congruentMs,
    incongruentMs,
    deltaMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stroop_results';
  @override
  VerificationContext validateIntegrity(
    Insertable<StroopResult> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    }
    if (data.containsKey('congruent_ms')) {
      context.handle(
        _congruentMsMeta,
        congruentMs.isAcceptableOrUnknown(
          data['congruent_ms']!,
          _congruentMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_congruentMsMeta);
    }
    if (data.containsKey('incongruent_ms')) {
      context.handle(
        _incongruentMsMeta,
        incongruentMs.isAcceptableOrUnknown(
          data['incongruent_ms']!,
          _incongruentMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_incongruentMsMeta);
    }
    if (data.containsKey('delta_ms')) {
      context.handle(
        _deltaMsMeta,
        deltaMs.isAcceptableOrUnknown(data['delta_ms']!, _deltaMsMeta),
      );
    } else if (isInserting) {
      context.missing(_deltaMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StroopResult map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StroopResult(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      timestamp:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}timestamp'],
          )!,
      congruentMs:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}congruent_ms'],
          )!,
      incongruentMs:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}incongruent_ms'],
          )!,
      deltaMs:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}delta_ms'],
          )!,
    );
  }

  @override
  $StroopResultsTable createAlias(String alias) {
    return $StroopResultsTable(attachedDatabase, alias);
  }
}

class StroopResult extends DataClass implements Insertable<StroopResult> {
  final int id;
  final DateTime timestamp;
  final double congruentMs;
  final double incongruentMs;
  final double deltaMs;
  const StroopResult({
    required this.id,
    required this.timestamp,
    required this.congruentMs,
    required this.incongruentMs,
    required this.deltaMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['congruent_ms'] = Variable<double>(congruentMs);
    map['incongruent_ms'] = Variable<double>(incongruentMs);
    map['delta_ms'] = Variable<double>(deltaMs);
    return map;
  }

  StroopResultsCompanion toCompanion(bool nullToAbsent) {
    return StroopResultsCompanion(
      id: Value(id),
      timestamp: Value(timestamp),
      congruentMs: Value(congruentMs),
      incongruentMs: Value(incongruentMs),
      deltaMs: Value(deltaMs),
    );
  }

  factory StroopResult.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StroopResult(
      id: serializer.fromJson<int>(json['id']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      congruentMs: serializer.fromJson<double>(json['congruentMs']),
      incongruentMs: serializer.fromJson<double>(json['incongruentMs']),
      deltaMs: serializer.fromJson<double>(json['deltaMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'congruentMs': serializer.toJson<double>(congruentMs),
      'incongruentMs': serializer.toJson<double>(incongruentMs),
      'deltaMs': serializer.toJson<double>(deltaMs),
    };
  }

  StroopResult copyWith({
    int? id,
    DateTime? timestamp,
    double? congruentMs,
    double? incongruentMs,
    double? deltaMs,
  }) => StroopResult(
    id: id ?? this.id,
    timestamp: timestamp ?? this.timestamp,
    congruentMs: congruentMs ?? this.congruentMs,
    incongruentMs: incongruentMs ?? this.incongruentMs,
    deltaMs: deltaMs ?? this.deltaMs,
  );
  StroopResult copyWithCompanion(StroopResultsCompanion data) {
    return StroopResult(
      id: data.id.present ? data.id.value : this.id,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      congruentMs:
          data.congruentMs.present ? data.congruentMs.value : this.congruentMs,
      incongruentMs:
          data.incongruentMs.present
              ? data.incongruentMs.value
              : this.incongruentMs,
      deltaMs: data.deltaMs.present ? data.deltaMs.value : this.deltaMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StroopResult(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('congruentMs: $congruentMs, ')
          ..write('incongruentMs: $incongruentMs, ')
          ..write('deltaMs: $deltaMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, timestamp, congruentMs, incongruentMs, deltaMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StroopResult &&
          other.id == this.id &&
          other.timestamp == this.timestamp &&
          other.congruentMs == this.congruentMs &&
          other.incongruentMs == this.incongruentMs &&
          other.deltaMs == this.deltaMs);
}

class StroopResultsCompanion extends UpdateCompanion<StroopResult> {
  final Value<int> id;
  final Value<DateTime> timestamp;
  final Value<double> congruentMs;
  final Value<double> incongruentMs;
  final Value<double> deltaMs;
  const StroopResultsCompanion({
    this.id = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.congruentMs = const Value.absent(),
    this.incongruentMs = const Value.absent(),
    this.deltaMs = const Value.absent(),
  });
  StroopResultsCompanion.insert({
    this.id = const Value.absent(),
    this.timestamp = const Value.absent(),
    required double congruentMs,
    required double incongruentMs,
    required double deltaMs,
  }) : congruentMs = Value(congruentMs),
       incongruentMs = Value(incongruentMs),
       deltaMs = Value(deltaMs);
  static Insertable<StroopResult> custom({
    Expression<int>? id,
    Expression<DateTime>? timestamp,
    Expression<double>? congruentMs,
    Expression<double>? incongruentMs,
    Expression<double>? deltaMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timestamp != null) 'timestamp': timestamp,
      if (congruentMs != null) 'congruent_ms': congruentMs,
      if (incongruentMs != null) 'incongruent_ms': incongruentMs,
      if (deltaMs != null) 'delta_ms': deltaMs,
    });
  }

  StroopResultsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? timestamp,
    Value<double>? congruentMs,
    Value<double>? incongruentMs,
    Value<double>? deltaMs,
  }) {
    return StroopResultsCompanion(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      congruentMs: congruentMs ?? this.congruentMs,
      incongruentMs: incongruentMs ?? this.incongruentMs,
      deltaMs: deltaMs ?? this.deltaMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (congruentMs.present) {
      map['congruent_ms'] = Variable<double>(congruentMs.value);
    }
    if (incongruentMs.present) {
      map['incongruent_ms'] = Variable<double>(incongruentMs.value);
    }
    if (deltaMs.present) {
      map['delta_ms'] = Variable<double>(deltaMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StroopResultsCompanion(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('congruentMs: $congruentMs, ')
          ..write('incongruentMs: $incongruentMs, ')
          ..write('deltaMs: $deltaMs')
          ..write(')'))
        .toString();
  }
}

class $GoNoGoResultsTable extends GoNoGoResults
    with TableInfo<$GoNoGoResultsTable, GoNoGoResult> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoNoGoResultsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _meanRtMeta = const VerificationMeta('meanRt');
  @override
  late final GeneratedColumn<double> meanRt = GeneratedColumn<double>(
    'mean_rt',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _commissionErrorsMeta = const VerificationMeta(
    'commissionErrors',
  );
  @override
  late final GeneratedColumn<int> commissionErrors = GeneratedColumn<int>(
    'commission_errors',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _omissionErrorsMeta = const VerificationMeta(
    'omissionErrors',
  );
  @override
  late final GeneratedColumn<int> omissionErrors = GeneratedColumn<int>(
    'omission_errors',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    timestamp,
    meanRt,
    commissionErrors,
    omissionErrors,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'go_no_go_results';
  @override
  VerificationContext validateIntegrity(
    Insertable<GoNoGoResult> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    }
    if (data.containsKey('mean_rt')) {
      context.handle(
        _meanRtMeta,
        meanRt.isAcceptableOrUnknown(data['mean_rt']!, _meanRtMeta),
      );
    } else if (isInserting) {
      context.missing(_meanRtMeta);
    }
    if (data.containsKey('commission_errors')) {
      context.handle(
        _commissionErrorsMeta,
        commissionErrors.isAcceptableOrUnknown(
          data['commission_errors']!,
          _commissionErrorsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_commissionErrorsMeta);
    }
    if (data.containsKey('omission_errors')) {
      context.handle(
        _omissionErrorsMeta,
        omissionErrors.isAcceptableOrUnknown(
          data['omission_errors']!,
          _omissionErrorsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_omissionErrorsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GoNoGoResult map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GoNoGoResult(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      timestamp:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}timestamp'],
          )!,
      meanRt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}mean_rt'],
          )!,
      commissionErrors:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}commission_errors'],
          )!,
      omissionErrors:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}omission_errors'],
          )!,
    );
  }

  @override
  $GoNoGoResultsTable createAlias(String alias) {
    return $GoNoGoResultsTable(attachedDatabase, alias);
  }
}

class GoNoGoResult extends DataClass implements Insertable<GoNoGoResult> {
  final int id;
  final DateTime timestamp;
  final double meanRt;
  final int commissionErrors;
  final int omissionErrors;
  const GoNoGoResult({
    required this.id,
    required this.timestamp,
    required this.meanRt,
    required this.commissionErrors,
    required this.omissionErrors,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['mean_rt'] = Variable<double>(meanRt);
    map['commission_errors'] = Variable<int>(commissionErrors);
    map['omission_errors'] = Variable<int>(omissionErrors);
    return map;
  }

  GoNoGoResultsCompanion toCompanion(bool nullToAbsent) {
    return GoNoGoResultsCompanion(
      id: Value(id),
      timestamp: Value(timestamp),
      meanRt: Value(meanRt),
      commissionErrors: Value(commissionErrors),
      omissionErrors: Value(omissionErrors),
    );
  }

  factory GoNoGoResult.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GoNoGoResult(
      id: serializer.fromJson<int>(json['id']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      meanRt: serializer.fromJson<double>(json['meanRt']),
      commissionErrors: serializer.fromJson<int>(json['commissionErrors']),
      omissionErrors: serializer.fromJson<int>(json['omissionErrors']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'meanRt': serializer.toJson<double>(meanRt),
      'commissionErrors': serializer.toJson<int>(commissionErrors),
      'omissionErrors': serializer.toJson<int>(omissionErrors),
    };
  }

  GoNoGoResult copyWith({
    int? id,
    DateTime? timestamp,
    double? meanRt,
    int? commissionErrors,
    int? omissionErrors,
  }) => GoNoGoResult(
    id: id ?? this.id,
    timestamp: timestamp ?? this.timestamp,
    meanRt: meanRt ?? this.meanRt,
    commissionErrors: commissionErrors ?? this.commissionErrors,
    omissionErrors: omissionErrors ?? this.omissionErrors,
  );
  GoNoGoResult copyWithCompanion(GoNoGoResultsCompanion data) {
    return GoNoGoResult(
      id: data.id.present ? data.id.value : this.id,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      meanRt: data.meanRt.present ? data.meanRt.value : this.meanRt,
      commissionErrors:
          data.commissionErrors.present
              ? data.commissionErrors.value
              : this.commissionErrors,
      omissionErrors:
          data.omissionErrors.present
              ? data.omissionErrors.value
              : this.omissionErrors,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GoNoGoResult(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('meanRt: $meanRt, ')
          ..write('commissionErrors: $commissionErrors, ')
          ..write('omissionErrors: $omissionErrors')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, timestamp, meanRt, commissionErrors, omissionErrors);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GoNoGoResult &&
          other.id == this.id &&
          other.timestamp == this.timestamp &&
          other.meanRt == this.meanRt &&
          other.commissionErrors == this.commissionErrors &&
          other.omissionErrors == this.omissionErrors);
}

class GoNoGoResultsCompanion extends UpdateCompanion<GoNoGoResult> {
  final Value<int> id;
  final Value<DateTime> timestamp;
  final Value<double> meanRt;
  final Value<int> commissionErrors;
  final Value<int> omissionErrors;
  const GoNoGoResultsCompanion({
    this.id = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.meanRt = const Value.absent(),
    this.commissionErrors = const Value.absent(),
    this.omissionErrors = const Value.absent(),
  });
  GoNoGoResultsCompanion.insert({
    this.id = const Value.absent(),
    this.timestamp = const Value.absent(),
    required double meanRt,
    required int commissionErrors,
    required int omissionErrors,
  }) : meanRt = Value(meanRt),
       commissionErrors = Value(commissionErrors),
       omissionErrors = Value(omissionErrors);
  static Insertable<GoNoGoResult> custom({
    Expression<int>? id,
    Expression<DateTime>? timestamp,
    Expression<double>? meanRt,
    Expression<int>? commissionErrors,
    Expression<int>? omissionErrors,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timestamp != null) 'timestamp': timestamp,
      if (meanRt != null) 'mean_rt': meanRt,
      if (commissionErrors != null) 'commission_errors': commissionErrors,
      if (omissionErrors != null) 'omission_errors': omissionErrors,
    });
  }

  GoNoGoResultsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? timestamp,
    Value<double>? meanRt,
    Value<int>? commissionErrors,
    Value<int>? omissionErrors,
  }) {
    return GoNoGoResultsCompanion(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      meanRt: meanRt ?? this.meanRt,
      commissionErrors: commissionErrors ?? this.commissionErrors,
      omissionErrors: omissionErrors ?? this.omissionErrors,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (meanRt.present) {
      map['mean_rt'] = Variable<double>(meanRt.value);
    }
    if (commissionErrors.present) {
      map['commission_errors'] = Variable<int>(commissionErrors.value);
    }
    if (omissionErrors.present) {
      map['omission_errors'] = Variable<int>(omissionErrors.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoNoGoResultsCompanion(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('meanRt: $meanRt, ')
          ..write('commissionErrors: $commissionErrors, ')
          ..write('omissionErrors: $omissionErrors')
          ..write(')'))
        .toString();
  }
}

class $DigitSpanResultsTable extends DigitSpanResults
    with TableInfo<$DigitSpanResultsTable, DigitSpanResult> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DigitSpanResultsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _bestSpanMeta = const VerificationMeta(
    'bestSpan',
  );
  @override
  late final GeneratedColumn<int> bestSpan = GeneratedColumn<int>(
    'best_span',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, timestamp, bestSpan];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'digit_span_results';
  @override
  VerificationContext validateIntegrity(
    Insertable<DigitSpanResult> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    }
    if (data.containsKey('best_span')) {
      context.handle(
        _bestSpanMeta,
        bestSpan.isAcceptableOrUnknown(data['best_span']!, _bestSpanMeta),
      );
    } else if (isInserting) {
      context.missing(_bestSpanMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DigitSpanResult map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DigitSpanResult(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      timestamp:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}timestamp'],
          )!,
      bestSpan:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}best_span'],
          )!,
    );
  }

  @override
  $DigitSpanResultsTable createAlias(String alias) {
    return $DigitSpanResultsTable(attachedDatabase, alias);
  }
}

class DigitSpanResult extends DataClass implements Insertable<DigitSpanResult> {
  final int id;
  final DateTime timestamp;
  final int bestSpan;
  const DigitSpanResult({
    required this.id,
    required this.timestamp,
    required this.bestSpan,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['best_span'] = Variable<int>(bestSpan);
    return map;
  }

  DigitSpanResultsCompanion toCompanion(bool nullToAbsent) {
    return DigitSpanResultsCompanion(
      id: Value(id),
      timestamp: Value(timestamp),
      bestSpan: Value(bestSpan),
    );
  }

  factory DigitSpanResult.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DigitSpanResult(
      id: serializer.fromJson<int>(json['id']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      bestSpan: serializer.fromJson<int>(json['bestSpan']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'bestSpan': serializer.toJson<int>(bestSpan),
    };
  }

  DigitSpanResult copyWith({int? id, DateTime? timestamp, int? bestSpan}) =>
      DigitSpanResult(
        id: id ?? this.id,
        timestamp: timestamp ?? this.timestamp,
        bestSpan: bestSpan ?? this.bestSpan,
      );
  DigitSpanResult copyWithCompanion(DigitSpanResultsCompanion data) {
    return DigitSpanResult(
      id: data.id.present ? data.id.value : this.id,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      bestSpan: data.bestSpan.present ? data.bestSpan.value : this.bestSpan,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DigitSpanResult(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('bestSpan: $bestSpan')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, timestamp, bestSpan);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DigitSpanResult &&
          other.id == this.id &&
          other.timestamp == this.timestamp &&
          other.bestSpan == this.bestSpan);
}

class DigitSpanResultsCompanion extends UpdateCompanion<DigitSpanResult> {
  final Value<int> id;
  final Value<DateTime> timestamp;
  final Value<int> bestSpan;
  const DigitSpanResultsCompanion({
    this.id = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.bestSpan = const Value.absent(),
  });
  DigitSpanResultsCompanion.insert({
    this.id = const Value.absent(),
    this.timestamp = const Value.absent(),
    required int bestSpan,
  }) : bestSpan = Value(bestSpan);
  static Insertable<DigitSpanResult> custom({
    Expression<int>? id,
    Expression<DateTime>? timestamp,
    Expression<int>? bestSpan,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timestamp != null) 'timestamp': timestamp,
      if (bestSpan != null) 'best_span': bestSpan,
    });
  }

  DigitSpanResultsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? timestamp,
    Value<int>? bestSpan,
  }) {
    return DigitSpanResultsCompanion(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      bestSpan: bestSpan ?? this.bestSpan,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (bestSpan.present) {
      map['best_span'] = Variable<int>(bestSpan.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DigitSpanResultsCompanion(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('bestSpan: $bestSpan')
          ..write(')'))
        .toString();
  }
}

class $SymbolSearchResultsTable extends SymbolSearchResults
    with TableInfo<$SymbolSearchResultsTable, SymbolSearchResult> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SymbolSearchResultsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _hitsMeta = const VerificationMeta('hits');
  @override
  late final GeneratedColumn<int> hits = GeneratedColumn<int>(
    'hits',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<int> total = GeneratedColumn<int>(
    'total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _meanRtMeta = const VerificationMeta('meanRt');
  @override
  late final GeneratedColumn<double> meanRt = GeneratedColumn<double>(
    'mean_rt',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, timestamp, hits, total, meanRt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'symbol_search_results';
  @override
  VerificationContext validateIntegrity(
    Insertable<SymbolSearchResult> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    }
    if (data.containsKey('hits')) {
      context.handle(
        _hitsMeta,
        hits.isAcceptableOrUnknown(data['hits']!, _hitsMeta),
      );
    } else if (isInserting) {
      context.missing(_hitsMeta);
    }
    if (data.containsKey('total')) {
      context.handle(
        _totalMeta,
        total.isAcceptableOrUnknown(data['total']!, _totalMeta),
      );
    } else if (isInserting) {
      context.missing(_totalMeta);
    }
    if (data.containsKey('mean_rt')) {
      context.handle(
        _meanRtMeta,
        meanRt.isAcceptableOrUnknown(data['mean_rt']!, _meanRtMeta),
      );
    } else if (isInserting) {
      context.missing(_meanRtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SymbolSearchResult map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SymbolSearchResult(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      timestamp:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}timestamp'],
          )!,
      hits:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}hits'],
          )!,
      total:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}total'],
          )!,
      meanRt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}mean_rt'],
          )!,
    );
  }

  @override
  $SymbolSearchResultsTable createAlias(String alias) {
    return $SymbolSearchResultsTable(attachedDatabase, alias);
  }
}

class SymbolSearchResult extends DataClass
    implements Insertable<SymbolSearchResult> {
  final int id;
  final DateTime timestamp;
  final int hits;
  final int total;
  final double meanRt;
  const SymbolSearchResult({
    required this.id,
    required this.timestamp,
    required this.hits,
    required this.total,
    required this.meanRt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['hits'] = Variable<int>(hits);
    map['total'] = Variable<int>(total);
    map['mean_rt'] = Variable<double>(meanRt);
    return map;
  }

  SymbolSearchResultsCompanion toCompanion(bool nullToAbsent) {
    return SymbolSearchResultsCompanion(
      id: Value(id),
      timestamp: Value(timestamp),
      hits: Value(hits),
      total: Value(total),
      meanRt: Value(meanRt),
    );
  }

  factory SymbolSearchResult.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SymbolSearchResult(
      id: serializer.fromJson<int>(json['id']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      hits: serializer.fromJson<int>(json['hits']),
      total: serializer.fromJson<int>(json['total']),
      meanRt: serializer.fromJson<double>(json['meanRt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'hits': serializer.toJson<int>(hits),
      'total': serializer.toJson<int>(total),
      'meanRt': serializer.toJson<double>(meanRt),
    };
  }

  SymbolSearchResult copyWith({
    int? id,
    DateTime? timestamp,
    int? hits,
    int? total,
    double? meanRt,
  }) => SymbolSearchResult(
    id: id ?? this.id,
    timestamp: timestamp ?? this.timestamp,
    hits: hits ?? this.hits,
    total: total ?? this.total,
    meanRt: meanRt ?? this.meanRt,
  );
  SymbolSearchResult copyWithCompanion(SymbolSearchResultsCompanion data) {
    return SymbolSearchResult(
      id: data.id.present ? data.id.value : this.id,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      hits: data.hits.present ? data.hits.value : this.hits,
      total: data.total.present ? data.total.value : this.total,
      meanRt: data.meanRt.present ? data.meanRt.value : this.meanRt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SymbolSearchResult(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('hits: $hits, ')
          ..write('total: $total, ')
          ..write('meanRt: $meanRt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, timestamp, hits, total, meanRt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SymbolSearchResult &&
          other.id == this.id &&
          other.timestamp == this.timestamp &&
          other.hits == this.hits &&
          other.total == this.total &&
          other.meanRt == this.meanRt);
}

class SymbolSearchResultsCompanion extends UpdateCompanion<SymbolSearchResult> {
  final Value<int> id;
  final Value<DateTime> timestamp;
  final Value<int> hits;
  final Value<int> total;
  final Value<double> meanRt;
  const SymbolSearchResultsCompanion({
    this.id = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.hits = const Value.absent(),
    this.total = const Value.absent(),
    this.meanRt = const Value.absent(),
  });
  SymbolSearchResultsCompanion.insert({
    this.id = const Value.absent(),
    this.timestamp = const Value.absent(),
    required int hits,
    required int total,
    required double meanRt,
  }) : hits = Value(hits),
       total = Value(total),
       meanRt = Value(meanRt);
  static Insertable<SymbolSearchResult> custom({
    Expression<int>? id,
    Expression<DateTime>? timestamp,
    Expression<int>? hits,
    Expression<int>? total,
    Expression<double>? meanRt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timestamp != null) 'timestamp': timestamp,
      if (hits != null) 'hits': hits,
      if (total != null) 'total': total,
      if (meanRt != null) 'mean_rt': meanRt,
    });
  }

  SymbolSearchResultsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? timestamp,
    Value<int>? hits,
    Value<int>? total,
    Value<double>? meanRt,
  }) {
    return SymbolSearchResultsCompanion(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      hits: hits ?? this.hits,
      total: total ?? this.total,
      meanRt: meanRt ?? this.meanRt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (hits.present) {
      map['hits'] = Variable<int>(hits.value);
    }
    if (total.present) {
      map['total'] = Variable<int>(total.value);
    }
    if (meanRt.present) {
      map['mean_rt'] = Variable<double>(meanRt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SymbolSearchResultsCompanion(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('hits: $hits, ')
          ..write('total: $total, ')
          ..write('meanRt: $meanRt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SubstancesTable substances = $SubstancesTable(this);
  late final $MoodEntriesTable moodEntries = $MoodEntriesTable(this);
  late final $ReactionResultsTable reactionResults = $ReactionResultsTable(
    this,
  );
  late final $SleepEntriesTable sleepEntries = $SleepEntriesTable(this);
  late final $StroopResultsTable stroopResults = $StroopResultsTable(this);
  late final $GoNoGoResultsTable goNoGoResults = $GoNoGoResultsTable(this);
  late final $DigitSpanResultsTable digitSpanResults = $DigitSpanResultsTable(
    this,
  );
  late final $SymbolSearchResultsTable symbolSearchResults =
      $SymbolSearchResultsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    substances,
    moodEntries,
    reactionResults,
    sleepEntries,
    stroopResults,
    goNoGoResults,
    digitSpanResults,
    symbolSearchResults,
  ];
}

typedef $$SubstancesTableCreateCompanionBuilder =
    SubstancesCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> dosage,
      Value<String?> notes,
      Value<DateTime> addedAt,
      Value<DateTime?> stoppedAt,
    });
typedef $$SubstancesTableUpdateCompanionBuilder =
    SubstancesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> dosage,
      Value<String?> notes,
      Value<DateTime> addedAt,
      Value<DateTime?> stoppedAt,
    });

class $$SubstancesTableFilterComposer
    extends Composer<_$AppDatabase, $SubstancesTable> {
  $$SubstancesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dosage => $composableBuilder(
    column: $table.dosage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get stoppedAt => $composableBuilder(
    column: $table.stoppedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SubstancesTableOrderingComposer
    extends Composer<_$AppDatabase, $SubstancesTable> {
  $$SubstancesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dosage => $composableBuilder(
    column: $table.dosage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get stoppedAt => $composableBuilder(
    column: $table.stoppedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SubstancesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubstancesTable> {
  $$SubstancesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get dosage =>
      $composableBuilder(column: $table.dosage, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get stoppedAt =>
      $composableBuilder(column: $table.stoppedAt, builder: (column) => column);
}

class $$SubstancesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SubstancesTable,
          Substance,
          $$SubstancesTableFilterComposer,
          $$SubstancesTableOrderingComposer,
          $$SubstancesTableAnnotationComposer,
          $$SubstancesTableCreateCompanionBuilder,
          $$SubstancesTableUpdateCompanionBuilder,
          (
            Substance,
            BaseReferences<_$AppDatabase, $SubstancesTable, Substance>,
          ),
          Substance,
          PrefetchHooks Function()
        > {
  $$SubstancesTableTableManager(_$AppDatabase db, $SubstancesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$SubstancesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$SubstancesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$SubstancesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> dosage = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<DateTime?> stoppedAt = const Value.absent(),
              }) => SubstancesCompanion(
                id: id,
                name: name,
                dosage: dosage,
                notes: notes,
                addedAt: addedAt,
                stoppedAt: stoppedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> dosage = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<DateTime?> stoppedAt = const Value.absent(),
              }) => SubstancesCompanion.insert(
                id: id,
                name: name,
                dosage: dosage,
                notes: notes,
                addedAt: addedAt,
                stoppedAt: stoppedAt,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SubstancesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SubstancesTable,
      Substance,
      $$SubstancesTableFilterComposer,
      $$SubstancesTableOrderingComposer,
      $$SubstancesTableAnnotationComposer,
      $$SubstancesTableCreateCompanionBuilder,
      $$SubstancesTableUpdateCompanionBuilder,
      (Substance, BaseReferences<_$AppDatabase, $SubstancesTable, Substance>),
      Substance,
      PrefetchHooks Function()
    >;
typedef $$MoodEntriesTableCreateCompanionBuilder =
    MoodEntriesCompanion Function({
      Value<int> id,
      required DateTime timestamp,
      Value<Map<String, int>?> customMetrics,
      Value<String?> notes,
    });
typedef $$MoodEntriesTableUpdateCompanionBuilder =
    MoodEntriesCompanion Function({
      Value<int> id,
      Value<DateTime> timestamp,
      Value<Map<String, int>?> customMetrics,
      Value<String?> notes,
    });

class $$MoodEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $MoodEntriesTable> {
  $$MoodEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Map<String, int>?, Map<String, int>, String>
  get customMetrics => $composableBuilder(
    column: $table.customMetrics,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MoodEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $MoodEntriesTable> {
  $$MoodEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customMetrics => $composableBuilder(
    column: $table.customMetrics,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MoodEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MoodEntriesTable> {
  $$MoodEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Map<String, int>?, String>
  get customMetrics => $composableBuilder(
    column: $table.customMetrics,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$MoodEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MoodEntriesTable,
          MoodEntry,
          $$MoodEntriesTableFilterComposer,
          $$MoodEntriesTableOrderingComposer,
          $$MoodEntriesTableAnnotationComposer,
          $$MoodEntriesTableCreateCompanionBuilder,
          $$MoodEntriesTableUpdateCompanionBuilder,
          (
            MoodEntry,
            BaseReferences<_$AppDatabase, $MoodEntriesTable, MoodEntry>,
          ),
          MoodEntry,
          PrefetchHooks Function()
        > {
  $$MoodEntriesTableTableManager(_$AppDatabase db, $MoodEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$MoodEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$MoodEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$MoodEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<Map<String, int>?> customMetrics = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => MoodEntriesCompanion(
                id: id,
                timestamp: timestamp,
                customMetrics: customMetrics,
                notes: notes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime timestamp,
                Value<Map<String, int>?> customMetrics = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => MoodEntriesCompanion.insert(
                id: id,
                timestamp: timestamp,
                customMetrics: customMetrics,
                notes: notes,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MoodEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MoodEntriesTable,
      MoodEntry,
      $$MoodEntriesTableFilterComposer,
      $$MoodEntriesTableOrderingComposer,
      $$MoodEntriesTableAnnotationComposer,
      $$MoodEntriesTableCreateCompanionBuilder,
      $$MoodEntriesTableUpdateCompanionBuilder,
      (MoodEntry, BaseReferences<_$AppDatabase, $MoodEntriesTable, MoodEntry>),
      MoodEntry,
      PrefetchHooks Function()
    >;
typedef $$ReactionResultsTableCreateCompanionBuilder =
    ReactionResultsCompanion Function({
      Value<int> id,
      required DateTime timestamp,
      required double averageTime,
      required double fastest,
      required double slowest,
    });
typedef $$ReactionResultsTableUpdateCompanionBuilder =
    ReactionResultsCompanion Function({
      Value<int> id,
      Value<DateTime> timestamp,
      Value<double> averageTime,
      Value<double> fastest,
      Value<double> slowest,
    });

class $$ReactionResultsTableFilterComposer
    extends Composer<_$AppDatabase, $ReactionResultsTable> {
  $$ReactionResultsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get averageTime => $composableBuilder(
    column: $table.averageTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fastest => $composableBuilder(
    column: $table.fastest,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get slowest => $composableBuilder(
    column: $table.slowest,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReactionResultsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReactionResultsTable> {
  $$ReactionResultsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get averageTime => $composableBuilder(
    column: $table.averageTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fastest => $composableBuilder(
    column: $table.fastest,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get slowest => $composableBuilder(
    column: $table.slowest,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReactionResultsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReactionResultsTable> {
  $$ReactionResultsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<double> get averageTime => $composableBuilder(
    column: $table.averageTime,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fastest =>
      $composableBuilder(column: $table.fastest, builder: (column) => column);

  GeneratedColumn<double> get slowest =>
      $composableBuilder(column: $table.slowest, builder: (column) => column);
}

class $$ReactionResultsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReactionResultsTable,
          ReactionResult,
          $$ReactionResultsTableFilterComposer,
          $$ReactionResultsTableOrderingComposer,
          $$ReactionResultsTableAnnotationComposer,
          $$ReactionResultsTableCreateCompanionBuilder,
          $$ReactionResultsTableUpdateCompanionBuilder,
          (
            ReactionResult,
            BaseReferences<
              _$AppDatabase,
              $ReactionResultsTable,
              ReactionResult
            >,
          ),
          ReactionResult,
          PrefetchHooks Function()
        > {
  $$ReactionResultsTableTableManager(
    _$AppDatabase db,
    $ReactionResultsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () =>
                  $$ReactionResultsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$ReactionResultsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$ReactionResultsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<double> averageTime = const Value.absent(),
                Value<double> fastest = const Value.absent(),
                Value<double> slowest = const Value.absent(),
              }) => ReactionResultsCompanion(
                id: id,
                timestamp: timestamp,
                averageTime: averageTime,
                fastest: fastest,
                slowest: slowest,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime timestamp,
                required double averageTime,
                required double fastest,
                required double slowest,
              }) => ReactionResultsCompanion.insert(
                id: id,
                timestamp: timestamp,
                averageTime: averageTime,
                fastest: fastest,
                slowest: slowest,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReactionResultsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReactionResultsTable,
      ReactionResult,
      $$ReactionResultsTableFilterComposer,
      $$ReactionResultsTableOrderingComposer,
      $$ReactionResultsTableAnnotationComposer,
      $$ReactionResultsTableCreateCompanionBuilder,
      $$ReactionResultsTableUpdateCompanionBuilder,
      (
        ReactionResult,
        BaseReferences<_$AppDatabase, $ReactionResultsTable, ReactionResult>,
      ),
      ReactionResult,
      PrefetchHooks Function()
    >;
typedef $$SleepEntriesTableCreateCompanionBuilder =
    SleepEntriesCompanion Function({
      Value<int> id,
      required DateTime date,
      required double hoursSlept,
      Value<String?> dreamJournal,
      Value<int> quality,
      Value<DateTime> createdAt,
    });
typedef $$SleepEntriesTableUpdateCompanionBuilder =
    SleepEntriesCompanion Function({
      Value<int> id,
      Value<DateTime> date,
      Value<double> hoursSlept,
      Value<String?> dreamJournal,
      Value<int> quality,
      Value<DateTime> createdAt,
    });

class $$SleepEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SleepEntriesTable> {
  $$SleepEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get hoursSlept => $composableBuilder(
    column: $table.hoursSlept,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dreamJournal => $composableBuilder(
    column: $table.dreamJournal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quality => $composableBuilder(
    column: $table.quality,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SleepEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SleepEntriesTable> {
  $$SleepEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get hoursSlept => $composableBuilder(
    column: $table.hoursSlept,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dreamJournal => $composableBuilder(
    column: $table.dreamJournal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quality => $composableBuilder(
    column: $table.quality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SleepEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SleepEntriesTable> {
  $$SleepEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get hoursSlept => $composableBuilder(
    column: $table.hoursSlept,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dreamJournal => $composableBuilder(
    column: $table.dreamJournal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quality =>
      $composableBuilder(column: $table.quality, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SleepEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SleepEntriesTable,
          SleepEntry,
          $$SleepEntriesTableFilterComposer,
          $$SleepEntriesTableOrderingComposer,
          $$SleepEntriesTableAnnotationComposer,
          $$SleepEntriesTableCreateCompanionBuilder,
          $$SleepEntriesTableUpdateCompanionBuilder,
          (
            SleepEntry,
            BaseReferences<_$AppDatabase, $SleepEntriesTable, SleepEntry>,
          ),
          SleepEntry,
          PrefetchHooks Function()
        > {
  $$SleepEntriesTableTableManager(_$AppDatabase db, $SleepEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$SleepEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$SleepEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$SleepEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<double> hoursSlept = const Value.absent(),
                Value<String?> dreamJournal = const Value.absent(),
                Value<int> quality = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SleepEntriesCompanion(
                id: id,
                date: date,
                hoursSlept: hoursSlept,
                dreamJournal: dreamJournal,
                quality: quality,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime date,
                required double hoursSlept,
                Value<String?> dreamJournal = const Value.absent(),
                Value<int> quality = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SleepEntriesCompanion.insert(
                id: id,
                date: date,
                hoursSlept: hoursSlept,
                dreamJournal: dreamJournal,
                quality: quality,
                createdAt: createdAt,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SleepEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SleepEntriesTable,
      SleepEntry,
      $$SleepEntriesTableFilterComposer,
      $$SleepEntriesTableOrderingComposer,
      $$SleepEntriesTableAnnotationComposer,
      $$SleepEntriesTableCreateCompanionBuilder,
      $$SleepEntriesTableUpdateCompanionBuilder,
      (
        SleepEntry,
        BaseReferences<_$AppDatabase, $SleepEntriesTable, SleepEntry>,
      ),
      SleepEntry,
      PrefetchHooks Function()
    >;
typedef $$StroopResultsTableCreateCompanionBuilder =
    StroopResultsCompanion Function({
      Value<int> id,
      Value<DateTime> timestamp,
      required double congruentMs,
      required double incongruentMs,
      required double deltaMs,
    });
typedef $$StroopResultsTableUpdateCompanionBuilder =
    StroopResultsCompanion Function({
      Value<int> id,
      Value<DateTime> timestamp,
      Value<double> congruentMs,
      Value<double> incongruentMs,
      Value<double> deltaMs,
    });

class $$StroopResultsTableFilterComposer
    extends Composer<_$AppDatabase, $StroopResultsTable> {
  $$StroopResultsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get congruentMs => $composableBuilder(
    column: $table.congruentMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get incongruentMs => $composableBuilder(
    column: $table.incongruentMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get deltaMs => $composableBuilder(
    column: $table.deltaMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StroopResultsTableOrderingComposer
    extends Composer<_$AppDatabase, $StroopResultsTable> {
  $$StroopResultsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get congruentMs => $composableBuilder(
    column: $table.congruentMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get incongruentMs => $composableBuilder(
    column: $table.incongruentMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get deltaMs => $composableBuilder(
    column: $table.deltaMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StroopResultsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StroopResultsTable> {
  $$StroopResultsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<double> get congruentMs => $composableBuilder(
    column: $table.congruentMs,
    builder: (column) => column,
  );

  GeneratedColumn<double> get incongruentMs => $composableBuilder(
    column: $table.incongruentMs,
    builder: (column) => column,
  );

  GeneratedColumn<double> get deltaMs =>
      $composableBuilder(column: $table.deltaMs, builder: (column) => column);
}

class $$StroopResultsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StroopResultsTable,
          StroopResult,
          $$StroopResultsTableFilterComposer,
          $$StroopResultsTableOrderingComposer,
          $$StroopResultsTableAnnotationComposer,
          $$StroopResultsTableCreateCompanionBuilder,
          $$StroopResultsTableUpdateCompanionBuilder,
          (
            StroopResult,
            BaseReferences<_$AppDatabase, $StroopResultsTable, StroopResult>,
          ),
          StroopResult,
          PrefetchHooks Function()
        > {
  $$StroopResultsTableTableManager(_$AppDatabase db, $StroopResultsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$StroopResultsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$StroopResultsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$StroopResultsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<double> congruentMs = const Value.absent(),
                Value<double> incongruentMs = const Value.absent(),
                Value<double> deltaMs = const Value.absent(),
              }) => StroopResultsCompanion(
                id: id,
                timestamp: timestamp,
                congruentMs: congruentMs,
                incongruentMs: incongruentMs,
                deltaMs: deltaMs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                required double congruentMs,
                required double incongruentMs,
                required double deltaMs,
              }) => StroopResultsCompanion.insert(
                id: id,
                timestamp: timestamp,
                congruentMs: congruentMs,
                incongruentMs: incongruentMs,
                deltaMs: deltaMs,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StroopResultsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StroopResultsTable,
      StroopResult,
      $$StroopResultsTableFilterComposer,
      $$StroopResultsTableOrderingComposer,
      $$StroopResultsTableAnnotationComposer,
      $$StroopResultsTableCreateCompanionBuilder,
      $$StroopResultsTableUpdateCompanionBuilder,
      (
        StroopResult,
        BaseReferences<_$AppDatabase, $StroopResultsTable, StroopResult>,
      ),
      StroopResult,
      PrefetchHooks Function()
    >;
typedef $$GoNoGoResultsTableCreateCompanionBuilder =
    GoNoGoResultsCompanion Function({
      Value<int> id,
      Value<DateTime> timestamp,
      required double meanRt,
      required int commissionErrors,
      required int omissionErrors,
    });
typedef $$GoNoGoResultsTableUpdateCompanionBuilder =
    GoNoGoResultsCompanion Function({
      Value<int> id,
      Value<DateTime> timestamp,
      Value<double> meanRt,
      Value<int> commissionErrors,
      Value<int> omissionErrors,
    });

class $$GoNoGoResultsTableFilterComposer
    extends Composer<_$AppDatabase, $GoNoGoResultsTable> {
  $$GoNoGoResultsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get meanRt => $composableBuilder(
    column: $table.meanRt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get commissionErrors => $composableBuilder(
    column: $table.commissionErrors,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get omissionErrors => $composableBuilder(
    column: $table.omissionErrors,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GoNoGoResultsTableOrderingComposer
    extends Composer<_$AppDatabase, $GoNoGoResultsTable> {
  $$GoNoGoResultsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get meanRt => $composableBuilder(
    column: $table.meanRt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get commissionErrors => $composableBuilder(
    column: $table.commissionErrors,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get omissionErrors => $composableBuilder(
    column: $table.omissionErrors,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GoNoGoResultsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoNoGoResultsTable> {
  $$GoNoGoResultsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<double> get meanRt =>
      $composableBuilder(column: $table.meanRt, builder: (column) => column);

  GeneratedColumn<int> get commissionErrors => $composableBuilder(
    column: $table.commissionErrors,
    builder: (column) => column,
  );

  GeneratedColumn<int> get omissionErrors => $composableBuilder(
    column: $table.omissionErrors,
    builder: (column) => column,
  );
}

class $$GoNoGoResultsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GoNoGoResultsTable,
          GoNoGoResult,
          $$GoNoGoResultsTableFilterComposer,
          $$GoNoGoResultsTableOrderingComposer,
          $$GoNoGoResultsTableAnnotationComposer,
          $$GoNoGoResultsTableCreateCompanionBuilder,
          $$GoNoGoResultsTableUpdateCompanionBuilder,
          (
            GoNoGoResult,
            BaseReferences<_$AppDatabase, $GoNoGoResultsTable, GoNoGoResult>,
          ),
          GoNoGoResult,
          PrefetchHooks Function()
        > {
  $$GoNoGoResultsTableTableManager(_$AppDatabase db, $GoNoGoResultsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$GoNoGoResultsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$GoNoGoResultsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$GoNoGoResultsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<double> meanRt = const Value.absent(),
                Value<int> commissionErrors = const Value.absent(),
                Value<int> omissionErrors = const Value.absent(),
              }) => GoNoGoResultsCompanion(
                id: id,
                timestamp: timestamp,
                meanRt: meanRt,
                commissionErrors: commissionErrors,
                omissionErrors: omissionErrors,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                required double meanRt,
                required int commissionErrors,
                required int omissionErrors,
              }) => GoNoGoResultsCompanion.insert(
                id: id,
                timestamp: timestamp,
                meanRt: meanRt,
                commissionErrors: commissionErrors,
                omissionErrors: omissionErrors,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GoNoGoResultsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GoNoGoResultsTable,
      GoNoGoResult,
      $$GoNoGoResultsTableFilterComposer,
      $$GoNoGoResultsTableOrderingComposer,
      $$GoNoGoResultsTableAnnotationComposer,
      $$GoNoGoResultsTableCreateCompanionBuilder,
      $$GoNoGoResultsTableUpdateCompanionBuilder,
      (
        GoNoGoResult,
        BaseReferences<_$AppDatabase, $GoNoGoResultsTable, GoNoGoResult>,
      ),
      GoNoGoResult,
      PrefetchHooks Function()
    >;
typedef $$DigitSpanResultsTableCreateCompanionBuilder =
    DigitSpanResultsCompanion Function({
      Value<int> id,
      Value<DateTime> timestamp,
      required int bestSpan,
    });
typedef $$DigitSpanResultsTableUpdateCompanionBuilder =
    DigitSpanResultsCompanion Function({
      Value<int> id,
      Value<DateTime> timestamp,
      Value<int> bestSpan,
    });

class $$DigitSpanResultsTableFilterComposer
    extends Composer<_$AppDatabase, $DigitSpanResultsTable> {
  $$DigitSpanResultsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bestSpan => $composableBuilder(
    column: $table.bestSpan,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DigitSpanResultsTableOrderingComposer
    extends Composer<_$AppDatabase, $DigitSpanResultsTable> {
  $$DigitSpanResultsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bestSpan => $composableBuilder(
    column: $table.bestSpan,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DigitSpanResultsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DigitSpanResultsTable> {
  $$DigitSpanResultsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<int> get bestSpan =>
      $composableBuilder(column: $table.bestSpan, builder: (column) => column);
}

class $$DigitSpanResultsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DigitSpanResultsTable,
          DigitSpanResult,
          $$DigitSpanResultsTableFilterComposer,
          $$DigitSpanResultsTableOrderingComposer,
          $$DigitSpanResultsTableAnnotationComposer,
          $$DigitSpanResultsTableCreateCompanionBuilder,
          $$DigitSpanResultsTableUpdateCompanionBuilder,
          (
            DigitSpanResult,
            BaseReferences<
              _$AppDatabase,
              $DigitSpanResultsTable,
              DigitSpanResult
            >,
          ),
          DigitSpanResult,
          PrefetchHooks Function()
        > {
  $$DigitSpanResultsTableTableManager(
    _$AppDatabase db,
    $DigitSpanResultsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () =>
                  $$DigitSpanResultsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$DigitSpanResultsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$DigitSpanResultsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<int> bestSpan = const Value.absent(),
              }) => DigitSpanResultsCompanion(
                id: id,
                timestamp: timestamp,
                bestSpan: bestSpan,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                required int bestSpan,
              }) => DigitSpanResultsCompanion.insert(
                id: id,
                timestamp: timestamp,
                bestSpan: bestSpan,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DigitSpanResultsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DigitSpanResultsTable,
      DigitSpanResult,
      $$DigitSpanResultsTableFilterComposer,
      $$DigitSpanResultsTableOrderingComposer,
      $$DigitSpanResultsTableAnnotationComposer,
      $$DigitSpanResultsTableCreateCompanionBuilder,
      $$DigitSpanResultsTableUpdateCompanionBuilder,
      (
        DigitSpanResult,
        BaseReferences<_$AppDatabase, $DigitSpanResultsTable, DigitSpanResult>,
      ),
      DigitSpanResult,
      PrefetchHooks Function()
    >;
typedef $$SymbolSearchResultsTableCreateCompanionBuilder =
    SymbolSearchResultsCompanion Function({
      Value<int> id,
      Value<DateTime> timestamp,
      required int hits,
      required int total,
      required double meanRt,
    });
typedef $$SymbolSearchResultsTableUpdateCompanionBuilder =
    SymbolSearchResultsCompanion Function({
      Value<int> id,
      Value<DateTime> timestamp,
      Value<int> hits,
      Value<int> total,
      Value<double> meanRt,
    });

class $$SymbolSearchResultsTableFilterComposer
    extends Composer<_$AppDatabase, $SymbolSearchResultsTable> {
  $$SymbolSearchResultsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hits => $composableBuilder(
    column: $table.hits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get meanRt => $composableBuilder(
    column: $table.meanRt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SymbolSearchResultsTableOrderingComposer
    extends Composer<_$AppDatabase, $SymbolSearchResultsTable> {
  $$SymbolSearchResultsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hits => $composableBuilder(
    column: $table.hits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get meanRt => $composableBuilder(
    column: $table.meanRt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SymbolSearchResultsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SymbolSearchResultsTable> {
  $$SymbolSearchResultsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<int> get hits =>
      $composableBuilder(column: $table.hits, builder: (column) => column);

  GeneratedColumn<int> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<double> get meanRt =>
      $composableBuilder(column: $table.meanRt, builder: (column) => column);
}

class $$SymbolSearchResultsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SymbolSearchResultsTable,
          SymbolSearchResult,
          $$SymbolSearchResultsTableFilterComposer,
          $$SymbolSearchResultsTableOrderingComposer,
          $$SymbolSearchResultsTableAnnotationComposer,
          $$SymbolSearchResultsTableCreateCompanionBuilder,
          $$SymbolSearchResultsTableUpdateCompanionBuilder,
          (
            SymbolSearchResult,
            BaseReferences<
              _$AppDatabase,
              $SymbolSearchResultsTable,
              SymbolSearchResult
            >,
          ),
          SymbolSearchResult,
          PrefetchHooks Function()
        > {
  $$SymbolSearchResultsTableTableManager(
    _$AppDatabase db,
    $SymbolSearchResultsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$SymbolSearchResultsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$SymbolSearchResultsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$SymbolSearchResultsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<int> hits = const Value.absent(),
                Value<int> total = const Value.absent(),
                Value<double> meanRt = const Value.absent(),
              }) => SymbolSearchResultsCompanion(
                id: id,
                timestamp: timestamp,
                hits: hits,
                total: total,
                meanRt: meanRt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                required int hits,
                required int total,
                required double meanRt,
              }) => SymbolSearchResultsCompanion.insert(
                id: id,
                timestamp: timestamp,
                hits: hits,
                total: total,
                meanRt: meanRt,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SymbolSearchResultsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SymbolSearchResultsTable,
      SymbolSearchResult,
      $$SymbolSearchResultsTableFilterComposer,
      $$SymbolSearchResultsTableOrderingComposer,
      $$SymbolSearchResultsTableAnnotationComposer,
      $$SymbolSearchResultsTableCreateCompanionBuilder,
      $$SymbolSearchResultsTableUpdateCompanionBuilder,
      (
        SymbolSearchResult,
        BaseReferences<
          _$AppDatabase,
          $SymbolSearchResultsTable,
          SymbolSearchResult
        >,
      ),
      SymbolSearchResult,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SubstancesTableTableManager get substances =>
      $$SubstancesTableTableManager(_db, _db.substances);
  $$MoodEntriesTableTableManager get moodEntries =>
      $$MoodEntriesTableTableManager(_db, _db.moodEntries);
  $$ReactionResultsTableTableManager get reactionResults =>
      $$ReactionResultsTableTableManager(_db, _db.reactionResults);
  $$SleepEntriesTableTableManager get sleepEntries =>
      $$SleepEntriesTableTableManager(_db, _db.sleepEntries);
  $$StroopResultsTableTableManager get stroopResults =>
      $$StroopResultsTableTableManager(_db, _db.stroopResults);
  $$GoNoGoResultsTableTableManager get goNoGoResults =>
      $$GoNoGoResultsTableTableManager(_db, _db.goNoGoResults);
  $$DigitSpanResultsTableTableManager get digitSpanResults =>
      $$DigitSpanResultsTableTableManager(_db, _db.digitSpanResults);
  $$SymbolSearchResultsTableTableManager get symbolSearchResults =>
      $$SymbolSearchResultsTableTableManager(_db, _db.symbolSearchResults);
}
