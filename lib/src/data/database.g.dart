// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ProjectsTable extends Projects with TableInfo<$ProjectsTable, ProjectRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 200),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0xFF5C6BC0),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, color, sortOrder, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projects';
  @override
  VerificationContext validateIntegrity(Insertable<ProjectRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(_colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta, sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProjectRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProjectRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      color: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}color'])!,
      sortOrder: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ProjectsTable createAlias(String alias) {
    return $ProjectsTable(attachedDatabase, alias);
  }
}

class ProjectRow extends DataClass implements Insertable<ProjectRow> {
  final int id;
  final String name;
  final int color;
  final int sortOrder;
  final int createdAt;
  final int updatedAt;
  const ProjectRow({
    required this.id,
    required this.name,
    required this.color,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['color'] = Variable<int>(color);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ProjectsCompanion toCompanion(bool nullToAbsent) {
    return ProjectsCompanion(
      id: Value(id),
      name: Value(name),
      color: Value(color),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProjectRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProjectRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<int>(json['color']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<int>(color),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ProjectRow copyWith({int? id, String? name, int? color, int? sortOrder, int? createdAt, int? updatedAt}) =>
      ProjectRow(
        id: id ?? this.id,
        name: name ?? this.name,
        color: color ?? this.color,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ProjectRow copyWithCompanion(ProjectsCompanion data) {
    return ProjectRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProjectRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, color, sortOrder, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProjectRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProjectsCompanion extends UpdateCompanion<ProjectRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> color;
  final Value<int> sortOrder;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const ProjectsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ProjectsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.color = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ProjectRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? color,
    Expression<int>? sortOrder,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ProjectsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? color,
    Value<int>? sortOrder,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return ProjectsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TasksTable extends Tasks with TableInfo<$TasksTable, TaskRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta('parentId');
  @override
  late final GeneratedColumn<int> parentId = GeneratedColumn<int>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES tasks (id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<int> projectId = GeneratedColumn<int>(
    'project_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES projects (id) ON DELETE SET NULL'),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<int> type = GeneratedColumn<int>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta('priority');
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<int> dueDate = GeneratedColumn<int>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueMinuteMeta = const VerificationMeta('dueMinute');
  @override
  late final GeneratedColumn<int> dueMinute = GeneratedColumn<int>(
    'due_minute',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recurrenceMeta = const VerificationMeta('recurrence');
  @override
  late final GeneratedColumn<String> recurrence = GeneratedColumn<String>(
    'recurrence',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recurrenceGeneratedUntilMeta = const VerificationMeta('recurrenceGeneratedUntil');
  @override
  late final GeneratedColumn<int> recurrenceGeneratedUntil = GeneratedColumn<int>(
    'recurrence_generated_until',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    parentId,
    projectId,
    title,
    description,
    type,
    status,
    priority,
    dueDate,
    dueMinute,
    recurrence,
    recurrenceGeneratedUntil,
    position,
    createdAt,
    updatedAt,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(Insertable<TaskRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('parent_id')) {
      context.handle(_parentIdMeta, parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta));
    }
    if (data.containsKey('project_id')) {
      context.handle(_projectIdMeta, projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta));
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(_descriptionMeta, description.isAcceptableOrUnknown(data['description']!, _descriptionMeta));
    }
    if (data.containsKey('type')) {
      context.handle(_typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta, status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta, priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    }
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta, dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
    }
    if (data.containsKey('due_minute')) {
      context.handle(_dueMinuteMeta, dueMinute.isAcceptableOrUnknown(data['due_minute']!, _dueMinuteMeta));
    }
    if (data.containsKey('recurrence')) {
      context.handle(_recurrenceMeta, recurrence.isAcceptableOrUnknown(data['recurrence']!, _recurrenceMeta));
    }
    if (data.containsKey('recurrence_generated_until')) {
      context.handle(
        _recurrenceGeneratedUntilMeta,
        recurrenceGeneratedUntil.isAcceptableOrUnknown(
          data['recurrence_generated_until']!,
          _recurrenceGeneratedUntilMeta,
        ),
      );
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta, position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(_completedAtMeta, completedAt.isAcceptableOrUnknown(data['completed_at']!, _completedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      parentId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}parent_id']),
      projectId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}project_id']),
      title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      type: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}type'])!,
      status: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}status'])!,
      priority: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}priority'])!,
      dueDate: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}due_date']),
      dueMinute: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}due_minute']),
      recurrence: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}recurrence']),
      recurrenceGeneratedUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recurrence_generated_until'],
      ),
      position: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}position'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      completedAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}completed_at']),
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class TaskRow extends DataClass implements Insertable<TaskRow> {
  final int id;
  final int? parentId;
  final int? projectId;
  final String title;
  final String description;
  final int type;
  final int status;
  final int priority;
  final int? dueDate;
  final int? dueMinute;

  /// JSON-encoded RecurrenceRule for recurring tasks.
  final String? recurrence;

  /// Last epoch-day for which occurrences have been materialised.
  final int? recurrenceGeneratedUntil;
  final int position;
  final int createdAt;
  final int updatedAt;
  final int? completedAt;
  const TaskRow({
    required this.id,
    this.parentId,
    this.projectId,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.priority,
    this.dueDate,
    this.dueMinute,
    this.recurrence,
    this.recurrenceGeneratedUntil,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<int>(parentId);
    }
    if (!nullToAbsent || projectId != null) {
      map['project_id'] = Variable<int>(projectId);
    }
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['type'] = Variable<int>(type);
    map['status'] = Variable<int>(status);
    map['priority'] = Variable<int>(priority);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<int>(dueDate);
    }
    if (!nullToAbsent || dueMinute != null) {
      map['due_minute'] = Variable<int>(dueMinute);
    }
    if (!nullToAbsent || recurrence != null) {
      map['recurrence'] = Variable<String>(recurrence);
    }
    if (!nullToAbsent || recurrenceGeneratedUntil != null) {
      map['recurrence_generated_until'] = Variable<int>(recurrenceGeneratedUntil);
    }
    map['position'] = Variable<int>(position);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(completedAt);
    }
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      parentId: parentId == null && nullToAbsent ? const Value.absent() : Value(parentId),
      projectId: projectId == null && nullToAbsent ? const Value.absent() : Value(projectId),
      title: Value(title),
      description: Value(description),
      type: Value(type),
      status: Value(status),
      priority: Value(priority),
      dueDate: dueDate == null && nullToAbsent ? const Value.absent() : Value(dueDate),
      dueMinute: dueMinute == null && nullToAbsent ? const Value.absent() : Value(dueMinute),
      recurrence: recurrence == null && nullToAbsent ? const Value.absent() : Value(recurrence),
      recurrenceGeneratedUntil: recurrenceGeneratedUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceGeneratedUntil),
      position: Value(position),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      completedAt: completedAt == null && nullToAbsent ? const Value.absent() : Value(completedAt),
    );
  }

  factory TaskRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskRow(
      id: serializer.fromJson<int>(json['id']),
      parentId: serializer.fromJson<int?>(json['parentId']),
      projectId: serializer.fromJson<int?>(json['projectId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      type: serializer.fromJson<int>(json['type']),
      status: serializer.fromJson<int>(json['status']),
      priority: serializer.fromJson<int>(json['priority']),
      dueDate: serializer.fromJson<int?>(json['dueDate']),
      dueMinute: serializer.fromJson<int?>(json['dueMinute']),
      recurrence: serializer.fromJson<String?>(json['recurrence']),
      recurrenceGeneratedUntil: serializer.fromJson<int?>(json['recurrenceGeneratedUntil']),
      position: serializer.fromJson<int>(json['position']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      completedAt: serializer.fromJson<int?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'parentId': serializer.toJson<int?>(parentId),
      'projectId': serializer.toJson<int?>(projectId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'type': serializer.toJson<int>(type),
      'status': serializer.toJson<int>(status),
      'priority': serializer.toJson<int>(priority),
      'dueDate': serializer.toJson<int?>(dueDate),
      'dueMinute': serializer.toJson<int?>(dueMinute),
      'recurrence': serializer.toJson<String?>(recurrence),
      'recurrenceGeneratedUntil': serializer.toJson<int?>(recurrenceGeneratedUntil),
      'position': serializer.toJson<int>(position),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'completedAt': serializer.toJson<int?>(completedAt),
    };
  }

  TaskRow copyWith({
    int? id,
    Value<int?> parentId = const Value.absent(),
    Value<int?> projectId = const Value.absent(),
    String? title,
    String? description,
    int? type,
    int? status,
    int? priority,
    Value<int?> dueDate = const Value.absent(),
    Value<int?> dueMinute = const Value.absent(),
    Value<String?> recurrence = const Value.absent(),
    Value<int?> recurrenceGeneratedUntil = const Value.absent(),
    int? position,
    int? createdAt,
    int? updatedAt,
    Value<int?> completedAt = const Value.absent(),
  }) => TaskRow(
    id: id ?? this.id,
    parentId: parentId.present ? parentId.value : this.parentId,
    projectId: projectId.present ? projectId.value : this.projectId,
    title: title ?? this.title,
    description: description ?? this.description,
    type: type ?? this.type,
    status: status ?? this.status,
    priority: priority ?? this.priority,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    dueMinute: dueMinute.present ? dueMinute.value : this.dueMinute,
    recurrence: recurrence.present ? recurrence.value : this.recurrence,
    recurrenceGeneratedUntil: recurrenceGeneratedUntil.present
        ? recurrenceGeneratedUntil.value
        : this.recurrenceGeneratedUntil,
    position: position ?? this.position,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  TaskRow copyWithCompanion(TasksCompanion data) {
    return TaskRow(
      id: data.id.present ? data.id.value : this.id,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present ? data.description.value : this.description,
      type: data.type.present ? data.type.value : this.type,
      status: data.status.present ? data.status.value : this.status,
      priority: data.priority.present ? data.priority.value : this.priority,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      dueMinute: data.dueMinute.present ? data.dueMinute.value : this.dueMinute,
      recurrence: data.recurrence.present ? data.recurrence.value : this.recurrence,
      recurrenceGeneratedUntil: data.recurrenceGeneratedUntil.present
          ? data.recurrenceGeneratedUntil.value
          : this.recurrenceGeneratedUntil,
      position: data.position.present ? data.position.value : this.position,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      completedAt: data.completedAt.present ? data.completedAt.value : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskRow(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('projectId: $projectId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('dueDate: $dueDate, ')
          ..write('dueMinute: $dueMinute, ')
          ..write('recurrence: $recurrence, ')
          ..write('recurrenceGeneratedUntil: $recurrenceGeneratedUntil, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    parentId,
    projectId,
    title,
    description,
    type,
    status,
    priority,
    dueDate,
    dueMinute,
    recurrence,
    recurrenceGeneratedUntil,
    position,
    createdAt,
    updatedAt,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskRow &&
          other.id == this.id &&
          other.parentId == this.parentId &&
          other.projectId == this.projectId &&
          other.title == this.title &&
          other.description == this.description &&
          other.type == this.type &&
          other.status == this.status &&
          other.priority == this.priority &&
          other.dueDate == this.dueDate &&
          other.dueMinute == this.dueMinute &&
          other.recurrence == this.recurrence &&
          other.recurrenceGeneratedUntil == this.recurrenceGeneratedUntil &&
          other.position == this.position &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.completedAt == this.completedAt);
}

class TasksCompanion extends UpdateCompanion<TaskRow> {
  final Value<int> id;
  final Value<int?> parentId;
  final Value<int?> projectId;
  final Value<String> title;
  final Value<String> description;
  final Value<int> type;
  final Value<int> status;
  final Value<int> priority;
  final Value<int?> dueDate;
  final Value<int?> dueMinute;
  final Value<String?> recurrence;
  final Value<int?> recurrenceGeneratedUntil;
  final Value<int> position;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> completedAt;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.parentId = const Value.absent(),
    this.projectId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.type = const Value.absent(),
    this.status = const Value.absent(),
    this.priority = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.dueMinute = const Value.absent(),
    this.recurrence = const Value.absent(),
    this.recurrenceGeneratedUntil = const Value.absent(),
    this.position = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  TasksCompanion.insert({
    this.id = const Value.absent(),
    this.parentId = const Value.absent(),
    this.projectId = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    this.type = const Value.absent(),
    this.status = const Value.absent(),
    this.priority = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.dueMinute = const Value.absent(),
    this.recurrence = const Value.absent(),
    this.recurrenceGeneratedUntil = const Value.absent(),
    this.position = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.completedAt = const Value.absent(),
  }) : title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TaskRow> custom({
    Expression<int>? id,
    Expression<int>? parentId,
    Expression<int>? projectId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<int>? type,
    Expression<int>? status,
    Expression<int>? priority,
    Expression<int>? dueDate,
    Expression<int>? dueMinute,
    Expression<String>? recurrence,
    Expression<int>? recurrenceGeneratedUntil,
    Expression<int>? position,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (parentId != null) 'parent_id': parentId,
      if (projectId != null) 'project_id': projectId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      if (priority != null) 'priority': priority,
      if (dueDate != null) 'due_date': dueDate,
      if (dueMinute != null) 'due_minute': dueMinute,
      if (recurrence != null) 'recurrence': recurrence,
      if (recurrenceGeneratedUntil != null) 'recurrence_generated_until': recurrenceGeneratedUntil,
      if (position != null) 'position': position,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  TasksCompanion copyWith({
    Value<int>? id,
    Value<int?>? parentId,
    Value<int?>? projectId,
    Value<String>? title,
    Value<String>? description,
    Value<int>? type,
    Value<int>? status,
    Value<int>? priority,
    Value<int?>? dueDate,
    Value<int?>? dueMinute,
    Value<String?>? recurrence,
    Value<int?>? recurrenceGeneratedUntil,
    Value<int>? position,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? completedAt,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      dueMinute: dueMinute ?? this.dueMinute,
      recurrence: recurrence ?? this.recurrence,
      recurrenceGeneratedUntil: recurrenceGeneratedUntil ?? this.recurrenceGeneratedUntil,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<int>(parentId.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<int>(projectId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(type.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<int>(dueDate.value);
    }
    if (dueMinute.present) {
      map['due_minute'] = Variable<int>(dueMinute.value);
    }
    if (recurrence.present) {
      map['recurrence'] = Variable<String>(recurrence.value);
    }
    if (recurrenceGeneratedUntil.present) {
      map['recurrence_generated_until'] = Variable<int>(recurrenceGeneratedUntil.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('projectId: $projectId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('dueDate: $dueDate, ')
          ..write('dueMinute: $dueMinute, ')
          ..write('recurrence: $recurrence, ')
          ..write('recurrenceGeneratedUntil: $recurrenceGeneratedUntil, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }
}

class $OccurrencesTable extends Occurrences with TableInfo<$OccurrencesTable, OccurrenceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OccurrencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<int> taskId = GeneratedColumn<int>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES tasks (id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<int> date = GeneratedColumn<int>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueMinuteMeta = const VerificationMeta('dueMinute');
  @override
  late final GeneratedColumn<int> dueMinute = GeneratedColumn<int>(
    'due_minute',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, taskId, date, dueMinute, status, createdAt, updatedAt, completedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'occurrences';
  @override
  VerificationContext validateIntegrity(Insertable<OccurrenceRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('task_id')) {
      context.handle(_taskIdMeta, taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta));
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(_dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('due_minute')) {
      context.handle(_dueMinuteMeta, dueMinute.isAcceptableOrUnknown(data['due_minute']!, _dueMinuteMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta, status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(_completedAtMeta, completedAt.isAcceptableOrUnknown(data['completed_at']!, _completedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OccurrenceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OccurrenceRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      taskId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}task_id'])!,
      date: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}date'])!,
      dueMinute: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}due_minute']),
      status: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}status'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      completedAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}completed_at']),
    );
  }

  @override
  $OccurrencesTable createAlias(String alias) {
    return $OccurrencesTable(attachedDatabase, alias);
  }
}

class OccurrenceRow extends DataClass implements Insertable<OccurrenceRow> {
  final int id;
  final int taskId;
  final int date;
  final int? dueMinute;
  final int status;
  final int createdAt;
  final int updatedAt;
  final int? completedAt;
  const OccurrenceRow({
    required this.id,
    required this.taskId,
    required this.date,
    this.dueMinute,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['task_id'] = Variable<int>(taskId);
    map['date'] = Variable<int>(date);
    if (!nullToAbsent || dueMinute != null) {
      map['due_minute'] = Variable<int>(dueMinute);
    }
    map['status'] = Variable<int>(status);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(completedAt);
    }
    return map;
  }

  OccurrencesCompanion toCompanion(bool nullToAbsent) {
    return OccurrencesCompanion(
      id: Value(id),
      taskId: Value(taskId),
      date: Value(date),
      dueMinute: dueMinute == null && nullToAbsent ? const Value.absent() : Value(dueMinute),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      completedAt: completedAt == null && nullToAbsent ? const Value.absent() : Value(completedAt),
    );
  }

  factory OccurrenceRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OccurrenceRow(
      id: serializer.fromJson<int>(json['id']),
      taskId: serializer.fromJson<int>(json['taskId']),
      date: serializer.fromJson<int>(json['date']),
      dueMinute: serializer.fromJson<int?>(json['dueMinute']),
      status: serializer.fromJson<int>(json['status']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      completedAt: serializer.fromJson<int?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'taskId': serializer.toJson<int>(taskId),
      'date': serializer.toJson<int>(date),
      'dueMinute': serializer.toJson<int?>(dueMinute),
      'status': serializer.toJson<int>(status),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'completedAt': serializer.toJson<int?>(completedAt),
    };
  }

  OccurrenceRow copyWith({
    int? id,
    int? taskId,
    int? date,
    Value<int?> dueMinute = const Value.absent(),
    int? status,
    int? createdAt,
    int? updatedAt,
    Value<int?> completedAt = const Value.absent(),
  }) => OccurrenceRow(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    date: date ?? this.date,
    dueMinute: dueMinute.present ? dueMinute.value : this.dueMinute,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  OccurrenceRow copyWithCompanion(OccurrencesCompanion data) {
    return OccurrenceRow(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      date: data.date.present ? data.date.value : this.date,
      dueMinute: data.dueMinute.present ? data.dueMinute.value : this.dueMinute,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      completedAt: data.completedAt.present ? data.completedAt.value : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OccurrenceRow(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('date: $date, ')
          ..write('dueMinute: $dueMinute, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, taskId, date, dueMinute, status, createdAt, updatedAt, completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OccurrenceRow &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.date == this.date &&
          other.dueMinute == this.dueMinute &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.completedAt == this.completedAt);
}

class OccurrencesCompanion extends UpdateCompanion<OccurrenceRow> {
  final Value<int> id;
  final Value<int> taskId;
  final Value<int> date;
  final Value<int?> dueMinute;
  final Value<int> status;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> completedAt;
  const OccurrencesCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.date = const Value.absent(),
    this.dueMinute = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  OccurrencesCompanion.insert({
    this.id = const Value.absent(),
    required int taskId,
    required int date,
    this.dueMinute = const Value.absent(),
    this.status = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.completedAt = const Value.absent(),
  }) : taskId = Value(taskId),
       date = Value(date),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<OccurrenceRow> custom({
    Expression<int>? id,
    Expression<int>? taskId,
    Expression<int>? date,
    Expression<int>? dueMinute,
    Expression<int>? status,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (date != null) 'date': date,
      if (dueMinute != null) 'due_minute': dueMinute,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  OccurrencesCompanion copyWith({
    Value<int>? id,
    Value<int>? taskId,
    Value<int>? date,
    Value<int?>? dueMinute,
    Value<int>? status,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? completedAt,
  }) {
    return OccurrencesCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      date: date ?? this.date,
      dueMinute: dueMinute ?? this.dueMinute,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<int>(taskId.value);
    }
    if (date.present) {
      map['date'] = Variable<int>(date.value);
    }
    if (dueMinute.present) {
      map['due_minute'] = Variable<int>(dueMinute.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OccurrencesCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('date: $date, ')
          ..write('dueMinute: $dueMinute, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }
}

class $RemindersTable extends Reminders with TableInfo<$RemindersTable, ReminderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<int> taskId = GeneratedColumn<int>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES tasks (id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<int> kind = GeneratedColumn<int>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atDateMeta = const VerificationMeta('atDate');
  @override
  late final GeneratedColumn<int> atDate = GeneratedColumn<int>(
    'at_date',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _atMinuteMeta = const VerificationMeta('atMinute');
  @override
  late final GeneratedColumn<int> atMinute = GeneratedColumn<int>(
    'at_minute',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _offsetMinutesMeta = const VerificationMeta('offsetMinutes');
  @override
  late final GeneratedColumn<int> offsetMinutes = GeneratedColumn<int>(
    'offset_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _repeatRuleMeta = const VerificationMeta('repeatRule');
  @override
  late final GeneratedColumn<String> repeatRule = GeneratedColumn<String>(
    'repeat_rule',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _atUtcMeta = const VerificationMeta('atUtc');
  @override
  late final GeneratedColumn<int> atUtc = GeneratedColumn<int>(
    'at_utc',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _occurrenceDateMeta = const VerificationMeta('occurrenceDate');
  @override
  late final GeneratedColumn<int> occurrenceDate = GeneratedColumn<int>(
    'occurrence_date',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta('enabled');
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("enabled" IN (0, 1))'),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    kind,
    atDate,
    atMinute,
    offsetMinutes,
    repeatRule,
    atUtc,
    occurrenceDate,
    enabled,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  VerificationContext validateIntegrity(Insertable<ReminderRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('task_id')) {
      context.handle(_taskIdMeta, taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta));
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(_kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('at_date')) {
      context.handle(_atDateMeta, atDate.isAcceptableOrUnknown(data['at_date']!, _atDateMeta));
    }
    if (data.containsKey('at_minute')) {
      context.handle(_atMinuteMeta, atMinute.isAcceptableOrUnknown(data['at_minute']!, _atMinuteMeta));
    }
    if (data.containsKey('offset_minutes')) {
      context.handle(
        _offsetMinutesMeta,
        offsetMinutes.isAcceptableOrUnknown(data['offset_minutes']!, _offsetMinutesMeta),
      );
    }
    if (data.containsKey('repeat_rule')) {
      context.handle(_repeatRuleMeta, repeatRule.isAcceptableOrUnknown(data['repeat_rule']!, _repeatRuleMeta));
    }
    if (data.containsKey('at_utc')) {
      context.handle(_atUtcMeta, atUtc.isAcceptableOrUnknown(data['at_utc']!, _atUtcMeta));
    }
    if (data.containsKey('occurrence_date')) {
      context.handle(
        _occurrenceDateMeta,
        occurrenceDate.isAcceptableOrUnknown(data['occurrence_date']!, _occurrenceDateMeta),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(_enabledMeta, enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReminderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReminderRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      taskId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}task_id'])!,
      kind: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}kind'])!,
      atDate: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}at_date']),
      atMinute: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}at_minute']),
      offsetMinutes: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}offset_minutes']),
      repeatRule: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}repeat_rule']),
      atUtc: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}at_utc']),
      occurrenceDate: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}occurrence_date']),
      enabled: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}enabled'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $RemindersTable createAlias(String alias) {
    return $RemindersTable(attachedDatabase, alias);
  }
}

class ReminderRow extends DataClass implements Insertable<ReminderRow> {
  final int id;
  final int taskId;
  final int kind;

  /// [ReminderKind.once]: civil date + minute.
  final int? atDate;
  final int? atMinute;

  /// [ReminderKind.relative]: minutes before the due time.
  final int? offsetMinutes;

  /// [ReminderKind.repeating]: JSON RecurrenceRule (fires at [atMinute]).
  final String? repeatRule;

  /// [ReminderKind.snooze]: absolute instant (UTC millis) and target occurrence.
  final int? atUtc;
  final int? occurrenceDate;
  final bool enabled;
  final int createdAt;
  const ReminderRow({
    required this.id,
    required this.taskId,
    required this.kind,
    this.atDate,
    this.atMinute,
    this.offsetMinutes,
    this.repeatRule,
    this.atUtc,
    this.occurrenceDate,
    required this.enabled,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['task_id'] = Variable<int>(taskId);
    map['kind'] = Variable<int>(kind);
    if (!nullToAbsent || atDate != null) {
      map['at_date'] = Variable<int>(atDate);
    }
    if (!nullToAbsent || atMinute != null) {
      map['at_minute'] = Variable<int>(atMinute);
    }
    if (!nullToAbsent || offsetMinutes != null) {
      map['offset_minutes'] = Variable<int>(offsetMinutes);
    }
    if (!nullToAbsent || repeatRule != null) {
      map['repeat_rule'] = Variable<String>(repeatRule);
    }
    if (!nullToAbsent || atUtc != null) {
      map['at_utc'] = Variable<int>(atUtc);
    }
    if (!nullToAbsent || occurrenceDate != null) {
      map['occurrence_date'] = Variable<int>(occurrenceDate);
    }
    map['enabled'] = Variable<bool>(enabled);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      id: Value(id),
      taskId: Value(taskId),
      kind: Value(kind),
      atDate: atDate == null && nullToAbsent ? const Value.absent() : Value(atDate),
      atMinute: atMinute == null && nullToAbsent ? const Value.absent() : Value(atMinute),
      offsetMinutes: offsetMinutes == null && nullToAbsent ? const Value.absent() : Value(offsetMinutes),
      repeatRule: repeatRule == null && nullToAbsent ? const Value.absent() : Value(repeatRule),
      atUtc: atUtc == null && nullToAbsent ? const Value.absent() : Value(atUtc),
      occurrenceDate: occurrenceDate == null && nullToAbsent ? const Value.absent() : Value(occurrenceDate),
      enabled: Value(enabled),
      createdAt: Value(createdAt),
    );
  }

  factory ReminderRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReminderRow(
      id: serializer.fromJson<int>(json['id']),
      taskId: serializer.fromJson<int>(json['taskId']),
      kind: serializer.fromJson<int>(json['kind']),
      atDate: serializer.fromJson<int?>(json['atDate']),
      atMinute: serializer.fromJson<int?>(json['atMinute']),
      offsetMinutes: serializer.fromJson<int?>(json['offsetMinutes']),
      repeatRule: serializer.fromJson<String?>(json['repeatRule']),
      atUtc: serializer.fromJson<int?>(json['atUtc']),
      occurrenceDate: serializer.fromJson<int?>(json['occurrenceDate']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'taskId': serializer.toJson<int>(taskId),
      'kind': serializer.toJson<int>(kind),
      'atDate': serializer.toJson<int?>(atDate),
      'atMinute': serializer.toJson<int?>(atMinute),
      'offsetMinutes': serializer.toJson<int?>(offsetMinutes),
      'repeatRule': serializer.toJson<String?>(repeatRule),
      'atUtc': serializer.toJson<int?>(atUtc),
      'occurrenceDate': serializer.toJson<int?>(occurrenceDate),
      'enabled': serializer.toJson<bool>(enabled),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  ReminderRow copyWith({
    int? id,
    int? taskId,
    int? kind,
    Value<int?> atDate = const Value.absent(),
    Value<int?> atMinute = const Value.absent(),
    Value<int?> offsetMinutes = const Value.absent(),
    Value<String?> repeatRule = const Value.absent(),
    Value<int?> atUtc = const Value.absent(),
    Value<int?> occurrenceDate = const Value.absent(),
    bool? enabled,
    int? createdAt,
  }) => ReminderRow(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    kind: kind ?? this.kind,
    atDate: atDate.present ? atDate.value : this.atDate,
    atMinute: atMinute.present ? atMinute.value : this.atMinute,
    offsetMinutes: offsetMinutes.present ? offsetMinutes.value : this.offsetMinutes,
    repeatRule: repeatRule.present ? repeatRule.value : this.repeatRule,
    atUtc: atUtc.present ? atUtc.value : this.atUtc,
    occurrenceDate: occurrenceDate.present ? occurrenceDate.value : this.occurrenceDate,
    enabled: enabled ?? this.enabled,
    createdAt: createdAt ?? this.createdAt,
  );
  ReminderRow copyWithCompanion(RemindersCompanion data) {
    return ReminderRow(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      kind: data.kind.present ? data.kind.value : this.kind,
      atDate: data.atDate.present ? data.atDate.value : this.atDate,
      atMinute: data.atMinute.present ? data.atMinute.value : this.atMinute,
      offsetMinutes: data.offsetMinutes.present ? data.offsetMinutes.value : this.offsetMinutes,
      repeatRule: data.repeatRule.present ? data.repeatRule.value : this.repeatRule,
      atUtc: data.atUtc.present ? data.atUtc.value : this.atUtc,
      occurrenceDate: data.occurrenceDate.present ? data.occurrenceDate.value : this.occurrenceDate,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReminderRow(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('kind: $kind, ')
          ..write('atDate: $atDate, ')
          ..write('atMinute: $atMinute, ')
          ..write('offsetMinutes: $offsetMinutes, ')
          ..write('repeatRule: $repeatRule, ')
          ..write('atUtc: $atUtc, ')
          ..write('occurrenceDate: $occurrenceDate, ')
          ..write('enabled: $enabled, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    taskId,
    kind,
    atDate,
    atMinute,
    offsetMinutes,
    repeatRule,
    atUtc,
    occurrenceDate,
    enabled,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReminderRow &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.kind == this.kind &&
          other.atDate == this.atDate &&
          other.atMinute == this.atMinute &&
          other.offsetMinutes == this.offsetMinutes &&
          other.repeatRule == this.repeatRule &&
          other.atUtc == this.atUtc &&
          other.occurrenceDate == this.occurrenceDate &&
          other.enabled == this.enabled &&
          other.createdAt == this.createdAt);
}

class RemindersCompanion extends UpdateCompanion<ReminderRow> {
  final Value<int> id;
  final Value<int> taskId;
  final Value<int> kind;
  final Value<int?> atDate;
  final Value<int?> atMinute;
  final Value<int?> offsetMinutes;
  final Value<String?> repeatRule;
  final Value<int?> atUtc;
  final Value<int?> occurrenceDate;
  final Value<bool> enabled;
  final Value<int> createdAt;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.kind = const Value.absent(),
    this.atDate = const Value.absent(),
    this.atMinute = const Value.absent(),
    this.offsetMinutes = const Value.absent(),
    this.repeatRule = const Value.absent(),
    this.atUtc = const Value.absent(),
    this.occurrenceDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  RemindersCompanion.insert({
    this.id = const Value.absent(),
    required int taskId,
    required int kind,
    this.atDate = const Value.absent(),
    this.atMinute = const Value.absent(),
    this.offsetMinutes = const Value.absent(),
    this.repeatRule = const Value.absent(),
    this.atUtc = const Value.absent(),
    this.occurrenceDate = const Value.absent(),
    this.enabled = const Value.absent(),
    required int createdAt,
  }) : taskId = Value(taskId),
       kind = Value(kind),
       createdAt = Value(createdAt);
  static Insertable<ReminderRow> custom({
    Expression<int>? id,
    Expression<int>? taskId,
    Expression<int>? kind,
    Expression<int>? atDate,
    Expression<int>? atMinute,
    Expression<int>? offsetMinutes,
    Expression<String>? repeatRule,
    Expression<int>? atUtc,
    Expression<int>? occurrenceDate,
    Expression<bool>? enabled,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (kind != null) 'kind': kind,
      if (atDate != null) 'at_date': atDate,
      if (atMinute != null) 'at_minute': atMinute,
      if (offsetMinutes != null) 'offset_minutes': offsetMinutes,
      if (repeatRule != null) 'repeat_rule': repeatRule,
      if (atUtc != null) 'at_utc': atUtc,
      if (occurrenceDate != null) 'occurrence_date': occurrenceDate,
      if (enabled != null) 'enabled': enabled,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  RemindersCompanion copyWith({
    Value<int>? id,
    Value<int>? taskId,
    Value<int>? kind,
    Value<int?>? atDate,
    Value<int?>? atMinute,
    Value<int?>? offsetMinutes,
    Value<String?>? repeatRule,
    Value<int?>? atUtc,
    Value<int?>? occurrenceDate,
    Value<bool>? enabled,
    Value<int>? createdAt,
  }) {
    return RemindersCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      kind: kind ?? this.kind,
      atDate: atDate ?? this.atDate,
      atMinute: atMinute ?? this.atMinute,
      offsetMinutes: offsetMinutes ?? this.offsetMinutes,
      repeatRule: repeatRule ?? this.repeatRule,
      atUtc: atUtc ?? this.atUtc,
      occurrenceDate: occurrenceDate ?? this.occurrenceDate,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<int>(taskId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<int>(kind.value);
    }
    if (atDate.present) {
      map['at_date'] = Variable<int>(atDate.value);
    }
    if (atMinute.present) {
      map['at_minute'] = Variable<int>(atMinute.value);
    }
    if (offsetMinutes.present) {
      map['offset_minutes'] = Variable<int>(offsetMinutes.value);
    }
    if (repeatRule.present) {
      map['repeat_rule'] = Variable<String>(repeatRule.value);
    }
    if (atUtc.present) {
      map['at_utc'] = Variable<int>(atUtc.value);
    }
    if (occurrenceDate.present) {
      map['occurrence_date'] = Variable<int>(occurrenceDate.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemindersCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('kind: $kind, ')
          ..write('atDate: $atDate, ')
          ..write('atMinute: $atMinute, ')
          ..write('offsetMinutes: $offsetMinutes, ')
          ..write('repeatRule: $repeatRule, ')
          ..write('atUtc: $atUtc, ')
          ..write('occurrenceDate: $occurrenceDate, ')
          ..write('enabled: $enabled, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ScheduledNotificationsTable extends ScheduledNotifications
    with TableInfo<$ScheduledNotificationsTable, ScheduledNotificationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScheduledNotificationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _instanceKeyMeta = const VerificationMeta('instanceKey');
  @override
  late final GeneratedColumn<String> instanceKey = GeneratedColumn<String>(
    'instance_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reminderIdMeta = const VerificationMeta('reminderId');
  @override
  late final GeneratedColumn<int> reminderId = GeneratedColumn<int>(
    'reminder_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<int> taskId = GeneratedColumn<int>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurrenceDateMeta = const VerificationMeta('occurrenceDate');
  @override
  late final GeneratedColumn<int> occurrenceDate = GeneratedColumn<int>(
    'occurrence_date',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fireAtMeta = const VerificationMeta('fireAt');
  @override
  late final GeneratedColumn<int> fireAt = GeneratedColumn<int>(
    'fire_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _signatureMeta = const VerificationMeta('signature');
  @override
  late final GeneratedColumn<String> signature = GeneratedColumn<String>(
    'signature',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deliveredAtMeta = const VerificationMeta('deliveredAt');
  @override
  late final GeneratedColumn<int> deliveredAt = GeneratedColumn<int>(
    'delivered_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    instanceKey,
    reminderId,
    taskId,
    occurrenceDate,
    fireAt,
    title,
    body,
    signature,
    deliveredAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scheduled_notifications';
  @override
  VerificationContext validateIntegrity(Insertable<ScheduledNotificationRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('instance_key')) {
      context.handle(_instanceKeyMeta, instanceKey.isAcceptableOrUnknown(data['instance_key']!, _instanceKeyMeta));
    } else if (isInserting) {
      context.missing(_instanceKeyMeta);
    }
    if (data.containsKey('reminder_id')) {
      context.handle(_reminderIdMeta, reminderId.isAcceptableOrUnknown(data['reminder_id']!, _reminderIdMeta));
    } else if (isInserting) {
      context.missing(_reminderIdMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(_taskIdMeta, taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta));
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('occurrence_date')) {
      context.handle(
        _occurrenceDateMeta,
        occurrenceDate.isAcceptableOrUnknown(data['occurrence_date']!, _occurrenceDateMeta),
      );
    }
    if (data.containsKey('fire_at')) {
      context.handle(_fireAtMeta, fireAt.isAcceptableOrUnknown(data['fire_at']!, _fireAtMeta));
    } else if (isInserting) {
      context.missing(_fireAtMeta);
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(_bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('signature')) {
      context.handle(_signatureMeta, signature.isAcceptableOrUnknown(data['signature']!, _signatureMeta));
    } else if (isInserting) {
      context.missing(_signatureMeta);
    }
    if (data.containsKey('delivered_at')) {
      context.handle(_deliveredAtMeta, deliveredAt.isAcceptableOrUnknown(data['delivered_at']!, _deliveredAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScheduledNotificationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScheduledNotificationRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      instanceKey: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}instance_key'])!,
      reminderId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}reminder_id'])!,
      taskId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}task_id'])!,
      occurrenceDate: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}occurrence_date']),
      fireAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}fire_at'])!,
      title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      body: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}body'])!,
      signature: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}signature'])!,
      deliveredAt: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}delivered_at']),
    );
  }

  @override
  $ScheduledNotificationsTable createAlias(String alias) {
    return $ScheduledNotificationsTable(attachedDatabase, alias);
  }
}

class ScheduledNotificationRow extends DataClass implements Insertable<ScheduledNotificationRow> {
  /// Also the OS notification id.
  final int id;

  /// Stable identity of a reminder instance: "reminderId@fireAtUtc[@date]".
  final String instanceKey;
  final int reminderId;
  final int taskId;
  final int? occurrenceDate;
  final int fireAt;

  /// Displayed content (kept so instances can be re-handed to the OS).
  final String title;
  final String body;

  /// Hash of the displayed content; a change triggers re-scheduling.
  final String signature;
  final int? deliveredAt;
  const ScheduledNotificationRow({
    required this.id,
    required this.instanceKey,
    required this.reminderId,
    required this.taskId,
    this.occurrenceDate,
    required this.fireAt,
    required this.title,
    required this.body,
    required this.signature,
    this.deliveredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['instance_key'] = Variable<String>(instanceKey);
    map['reminder_id'] = Variable<int>(reminderId);
    map['task_id'] = Variable<int>(taskId);
    if (!nullToAbsent || occurrenceDate != null) {
      map['occurrence_date'] = Variable<int>(occurrenceDate);
    }
    map['fire_at'] = Variable<int>(fireAt);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    map['signature'] = Variable<String>(signature);
    if (!nullToAbsent || deliveredAt != null) {
      map['delivered_at'] = Variable<int>(deliveredAt);
    }
    return map;
  }

  ScheduledNotificationsCompanion toCompanion(bool nullToAbsent) {
    return ScheduledNotificationsCompanion(
      id: Value(id),
      instanceKey: Value(instanceKey),
      reminderId: Value(reminderId),
      taskId: Value(taskId),
      occurrenceDate: occurrenceDate == null && nullToAbsent ? const Value.absent() : Value(occurrenceDate),
      fireAt: Value(fireAt),
      title: Value(title),
      body: Value(body),
      signature: Value(signature),
      deliveredAt: deliveredAt == null && nullToAbsent ? const Value.absent() : Value(deliveredAt),
    );
  }

  factory ScheduledNotificationRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScheduledNotificationRow(
      id: serializer.fromJson<int>(json['id']),
      instanceKey: serializer.fromJson<String>(json['instanceKey']),
      reminderId: serializer.fromJson<int>(json['reminderId']),
      taskId: serializer.fromJson<int>(json['taskId']),
      occurrenceDate: serializer.fromJson<int?>(json['occurrenceDate']),
      fireAt: serializer.fromJson<int>(json['fireAt']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      signature: serializer.fromJson<String>(json['signature']),
      deliveredAt: serializer.fromJson<int?>(json['deliveredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'instanceKey': serializer.toJson<String>(instanceKey),
      'reminderId': serializer.toJson<int>(reminderId),
      'taskId': serializer.toJson<int>(taskId),
      'occurrenceDate': serializer.toJson<int?>(occurrenceDate),
      'fireAt': serializer.toJson<int>(fireAt),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'signature': serializer.toJson<String>(signature),
      'deliveredAt': serializer.toJson<int?>(deliveredAt),
    };
  }

  ScheduledNotificationRow copyWith({
    int? id,
    String? instanceKey,
    int? reminderId,
    int? taskId,
    Value<int?> occurrenceDate = const Value.absent(),
    int? fireAt,
    String? title,
    String? body,
    String? signature,
    Value<int?> deliveredAt = const Value.absent(),
  }) => ScheduledNotificationRow(
    id: id ?? this.id,
    instanceKey: instanceKey ?? this.instanceKey,
    reminderId: reminderId ?? this.reminderId,
    taskId: taskId ?? this.taskId,
    occurrenceDate: occurrenceDate.present ? occurrenceDate.value : this.occurrenceDate,
    fireAt: fireAt ?? this.fireAt,
    title: title ?? this.title,
    body: body ?? this.body,
    signature: signature ?? this.signature,
    deliveredAt: deliveredAt.present ? deliveredAt.value : this.deliveredAt,
  );
  ScheduledNotificationRow copyWithCompanion(ScheduledNotificationsCompanion data) {
    return ScheduledNotificationRow(
      id: data.id.present ? data.id.value : this.id,
      instanceKey: data.instanceKey.present ? data.instanceKey.value : this.instanceKey,
      reminderId: data.reminderId.present ? data.reminderId.value : this.reminderId,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      occurrenceDate: data.occurrenceDate.present ? data.occurrenceDate.value : this.occurrenceDate,
      fireAt: data.fireAt.present ? data.fireAt.value : this.fireAt,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      signature: data.signature.present ? data.signature.value : this.signature,
      deliveredAt: data.deliveredAt.present ? data.deliveredAt.value : this.deliveredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScheduledNotificationRow(')
          ..write('id: $id, ')
          ..write('instanceKey: $instanceKey, ')
          ..write('reminderId: $reminderId, ')
          ..write('taskId: $taskId, ')
          ..write('occurrenceDate: $occurrenceDate, ')
          ..write('fireAt: $fireAt, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('signature: $signature, ')
          ..write('deliveredAt: $deliveredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, instanceKey, reminderId, taskId, occurrenceDate, fireAt, title, body, signature, deliveredAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScheduledNotificationRow &&
          other.id == this.id &&
          other.instanceKey == this.instanceKey &&
          other.reminderId == this.reminderId &&
          other.taskId == this.taskId &&
          other.occurrenceDate == this.occurrenceDate &&
          other.fireAt == this.fireAt &&
          other.title == this.title &&
          other.body == this.body &&
          other.signature == this.signature &&
          other.deliveredAt == this.deliveredAt);
}

class ScheduledNotificationsCompanion extends UpdateCompanion<ScheduledNotificationRow> {
  final Value<int> id;
  final Value<String> instanceKey;
  final Value<int> reminderId;
  final Value<int> taskId;
  final Value<int?> occurrenceDate;
  final Value<int> fireAt;
  final Value<String> title;
  final Value<String> body;
  final Value<String> signature;
  final Value<int?> deliveredAt;
  const ScheduledNotificationsCompanion({
    this.id = const Value.absent(),
    this.instanceKey = const Value.absent(),
    this.reminderId = const Value.absent(),
    this.taskId = const Value.absent(),
    this.occurrenceDate = const Value.absent(),
    this.fireAt = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.signature = const Value.absent(),
    this.deliveredAt = const Value.absent(),
  });
  ScheduledNotificationsCompanion.insert({
    this.id = const Value.absent(),
    required String instanceKey,
    required int reminderId,
    required int taskId,
    this.occurrenceDate = const Value.absent(),
    required int fireAt,
    required String title,
    required String body,
    required String signature,
    this.deliveredAt = const Value.absent(),
  }) : instanceKey = Value(instanceKey),
       reminderId = Value(reminderId),
       taskId = Value(taskId),
       fireAt = Value(fireAt),
       title = Value(title),
       body = Value(body),
       signature = Value(signature);
  static Insertable<ScheduledNotificationRow> custom({
    Expression<int>? id,
    Expression<String>? instanceKey,
    Expression<int>? reminderId,
    Expression<int>? taskId,
    Expression<int>? occurrenceDate,
    Expression<int>? fireAt,
    Expression<String>? title,
    Expression<String>? body,
    Expression<String>? signature,
    Expression<int>? deliveredAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (instanceKey != null) 'instance_key': instanceKey,
      if (reminderId != null) 'reminder_id': reminderId,
      if (taskId != null) 'task_id': taskId,
      if (occurrenceDate != null) 'occurrence_date': occurrenceDate,
      if (fireAt != null) 'fire_at': fireAt,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (signature != null) 'signature': signature,
      if (deliveredAt != null) 'delivered_at': deliveredAt,
    });
  }

  ScheduledNotificationsCompanion copyWith({
    Value<int>? id,
    Value<String>? instanceKey,
    Value<int>? reminderId,
    Value<int>? taskId,
    Value<int?>? occurrenceDate,
    Value<int>? fireAt,
    Value<String>? title,
    Value<String>? body,
    Value<String>? signature,
    Value<int?>? deliveredAt,
  }) {
    return ScheduledNotificationsCompanion(
      id: id ?? this.id,
      instanceKey: instanceKey ?? this.instanceKey,
      reminderId: reminderId ?? this.reminderId,
      taskId: taskId ?? this.taskId,
      occurrenceDate: occurrenceDate ?? this.occurrenceDate,
      fireAt: fireAt ?? this.fireAt,
      title: title ?? this.title,
      body: body ?? this.body,
      signature: signature ?? this.signature,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (instanceKey.present) {
      map['instance_key'] = Variable<String>(instanceKey.value);
    }
    if (reminderId.present) {
      map['reminder_id'] = Variable<int>(reminderId.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<int>(taskId.value);
    }
    if (occurrenceDate.present) {
      map['occurrence_date'] = Variable<int>(occurrenceDate.value);
    }
    if (fireAt.present) {
      map['fire_at'] = Variable<int>(fireAt.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (signature.present) {
      map['signature'] = Variable<String>(signature.value);
    }
    if (deliveredAt.present) {
      map['delivered_at'] = Variable<int>(deliveredAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScheduledNotificationsCompanion(')
          ..write('id: $id, ')
          ..write('instanceKey: $instanceKey, ')
          ..write('reminderId: $reminderId, ')
          ..write('taskId: $taskId, ')
          ..write('occurrenceDate: $occurrenceDate, ')
          ..write('fireAt: $fireAt, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('signature: $signature, ')
          ..write('deliveredAt: $deliveredAt')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(Insertable<SettingRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(_keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(_valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String value;
  const SettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory SettingRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(key: serializer.fromJson<String>(json['key']), value: serializer.fromJson<String>(json['value']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'key': serializer.toJson<String>(key), 'value': serializer.toJson<String>(value)};
  }

  SettingRow copyWith({String? key, String? value}) => SettingRow(key: key ?? this.key, value: value ?? this.value);
  SettingRow copyWithCompanion(SettingsCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is SettingRow && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({required String key, required String value, this.rowid = const Value.absent()})
    : key = Value(key),
      value = Value(value);
  static Insertable<SettingRow> custom({Expression<String>? key, Expression<String>? value, Expression<int>? rowid}) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return SettingsCompanion(key: key ?? this.key, value: value ?? this.value, rowid: rowid ?? this.rowid);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProjectsTable projects = $ProjectsTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $OccurrencesTable occurrences = $OccurrencesTable(this);
  late final $RemindersTable reminders = $RemindersTable(this);
  late final $ScheduledNotificationsTable scheduledNotifications = $ScheduledNotificationsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final Index idxTasksStatusDue = Index(
    'idx_tasks_status_due',
    'CREATE INDEX idx_tasks_status_due ON tasks (status, due_date)',
  );
  late final Index idxTasksParent = Index('idx_tasks_parent', 'CREATE INDEX idx_tasks_parent ON tasks (parent_id)');
  late final Index idxTasksProject = Index(
    'idx_tasks_project',
    'CREATE INDEX idx_tasks_project ON tasks (project_id, status)',
  );
  late final Index idxTasksTypeStatus = Index(
    'idx_tasks_type_status',
    'CREATE INDEX idx_tasks_type_status ON tasks (type, status)',
  );
  late final Index idxTasksUpdated = Index('idx_tasks_updated', 'CREATE INDEX idx_tasks_updated ON tasks (updated_at)');
  late final Index idxOccStatusDate = Index(
    'idx_occ_status_date',
    'CREATE INDEX idx_occ_status_date ON occurrences (status, date)',
  );
  late final Index idxOccTaskDate = Index(
    'idx_occ_task_date',
    'CREATE UNIQUE INDEX idx_occ_task_date ON occurrences (task_id, date)',
  );
  late final Index idxRemindersTask = Index(
    'idx_reminders_task',
    'CREATE INDEX idx_reminders_task ON reminders (task_id)',
  );
  late final Index idxSchedFire = Index(
    'idx_sched_fire',
    'CREATE INDEX idx_sched_fire ON scheduled_notifications (fire_at)',
  );
  late final Index idxSchedKey = Index(
    'idx_sched_key',
    'CREATE UNIQUE INDEX idx_sched_key ON scheduled_notifications (instance_key)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    projects,
    tasks,
    occurrences,
    reminders,
    scheduledNotifications,
    settings,
    idxTasksStatusDue,
    idxTasksParent,
    idxTasksProject,
    idxTasksTypeStatus,
    idxTasksUpdated,
    idxOccStatusDate,
    idxOccTaskDate,
    idxRemindersTask,
    idxSchedFire,
    idxSchedKey,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName('tasks', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('tasks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('projects', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('tasks', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('tasks', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('occurrences', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('tasks', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('reminders', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ProjectsTableCreateCompanionBuilder = ProjectsCompanion Function({
  Value<int> id,
  required String name,
  Value<int> color,
  Value<int> sortOrder,
  required int createdAt,
  required int updatedAt,
});
typedef $$ProjectsTableUpdateCompanionBuilder = ProjectsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> color,
  Value<int> sortOrder,
  Value<int> createdAt,
  Value<int> updatedAt,
});

final class $$ProjectsTableReferences extends BaseReferences<_$AppDatabase, $ProjectsTable, ProjectRow> {
  $$ProjectsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TasksTable, List<TaskRow>> _tasksRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.tasks, aliasName: 'projects__id__tasks__project_id');

  $$TasksTableProcessedTableManager get tasksRefs {
    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_tasksRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ProjectsTableFilterComposer extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get color => $composableBuilder(column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> tasksRefs(Expression<bool> Function($$TasksTableFilterComposer f) f) {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.projectId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProjectsTableOrderingComposer extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ProjectsTableAnnotationComposer extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get color => $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> tasksRefs<T extends Object>(Expression<T> Function($$TasksTableAnnotationComposer a) f) {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.projectId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProjectsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProjectsTable,
          ProjectRow,
          $$ProjectsTableFilterComposer,
          $$ProjectsTableOrderingComposer,
          $$ProjectsTableAnnotationComposer,
          $$ProjectsTableCreateCompanionBuilder,
          $$ProjectsTableUpdateCompanionBuilder,
          (ProjectRow, $$ProjectsTableReferences),
          ProjectRow,
          PrefetchHooks Function({bool tasksRefs})
        > {
  $$ProjectsTableTableManager(_$AppDatabase db, $ProjectsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$ProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$ProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$ProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => ProjectsCompanion(
                id: id,
                name: name,
                color: color,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<int> color = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => ProjectsCompanion.insert(
                id: id,
                name: name,
                color: color,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$ProjectsTable, ProjectRow>(table), $$ProjectsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({tasksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (tasksRefs) db.tasks],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (tasksRefs)
                    await $_getPrefetchedData<ProjectRow, $ProjectsTable, TaskRow>(
                      currentTable: table,
                      referencedTable: $$ProjectsTableReferences._tasksRefsTable(db),
                      managerFromTypedResult: (p0) => $$ProjectsTableReferences(db, table, p0).tasksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.projectId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ProjectsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProjectsTable,
      ProjectRow,
      $$ProjectsTableFilterComposer,
      $$ProjectsTableOrderingComposer,
      $$ProjectsTableAnnotationComposer,
      $$ProjectsTableCreateCompanionBuilder,
      $$ProjectsTableUpdateCompanionBuilder,
      (ProjectRow, $$ProjectsTableReferences),
      ProjectRow,
      PrefetchHooks Function({bool tasksRefs})
    >;
typedef $$TasksTableCreateCompanionBuilder = TasksCompanion Function({
  Value<int> id,
  Value<int?> parentId,
  Value<int?> projectId,
  required String title,
  Value<String> description,
  Value<int> type,
  Value<int> status,
  Value<int> priority,
  Value<int?> dueDate,
  Value<int?> dueMinute,
  Value<String?> recurrence,
  Value<int?> recurrenceGeneratedUntil,
  Value<int> position,
  required int createdAt,
  required int updatedAt,
  Value<int?> completedAt,
});
typedef $$TasksTableUpdateCompanionBuilder = TasksCompanion Function({
  Value<int> id,
  Value<int?> parentId,
  Value<int?> projectId,
  Value<String> title,
  Value<String> description,
  Value<int> type,
  Value<int> status,
  Value<int> priority,
  Value<int?> dueDate,
  Value<int?> dueMinute,
  Value<String?> recurrence,
  Value<int?> recurrenceGeneratedUntil,
  Value<int> position,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> completedAt,
});

final class $$TasksTableReferences extends BaseReferences<_$AppDatabase, $TasksTable, TaskRow> {
  $$TasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TasksTable _parentIdTable(_$AppDatabase db) => db.tasks.createAlias('tasks__parent_id__tasks__id');

  $$TasksTableProcessedTableManager? get parentId {
    final $_column = $_itemColumn<int>('parent_id');
    if ($_column == null) return null;
    final manager = $$TasksTableTableManager($_db, $_db.tasks).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ProjectsTable _projectIdTable(_$AppDatabase db) => db.projects.createAlias('tasks__project_id__projects__id');

  $$ProjectsTableProcessedTableManager? get projectId {
    final $_column = $_itemColumn<int>('project_id');
    if ($_column == null) return null;
    final manager = $$ProjectsTableTableManager($_db, $_db.projects).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$OccurrencesTable, List<OccurrenceRow>> _occurrencesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.occurrences, aliasName: 'tasks__id__occurrences__task_id');

  $$OccurrencesTableProcessedTableManager get occurrencesRefs {
    final manager = $$OccurrencesTableTableManager(
      $_db,
      $_db.occurrences,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_occurrencesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$RemindersTable, List<ReminderRow>> _remindersRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.reminders, aliasName: 'tasks__id__reminders__task_id');

  $$RemindersTableProcessedTableManager get remindersRefs {
    final manager = $$RemindersTableTableManager(
      $_db,
      $_db.reminders,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_remindersRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description =>
      $composableBuilder(column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get type => $composableBuilder(column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dueMinute =>
      $composableBuilder(column: $table.dueMinute, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recurrence =>
      $composableBuilder(column: $table.recurrence, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get recurrenceGeneratedUntil =>
      $composableBuilder(column: $table.recurrenceGeneratedUntil, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get completedAt =>
      $composableBuilder(column: $table.completedAt, builder: (column) => ColumnFilters(column));

  $$TasksTableFilterComposer get parentId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProjectsTableFilterComposer get projectId {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ProjectsTableFilterComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> occurrencesRefs(Expression<bool> Function($$OccurrencesTableFilterComposer f) f) {
    final $$OccurrencesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.occurrences,
      getReferencedColumn: (t) => t.taskId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$OccurrencesTableFilterComposer(
            $db: $db,
            $table: $db.occurrences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> remindersRefs(Expression<bool> Function($$RemindersTableFilterComposer f) f) {
    final $$RemindersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reminders,
      getReferencedColumn: (t) => t.taskId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$RemindersTableFilterComposer(
            $db: $db,
            $table: $db.reminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TasksTableOrderingComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description =>
      $composableBuilder(column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dueMinute =>
      $composableBuilder(column: $table.dueMinute, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recurrence =>
      $composableBuilder(column: $table.recurrence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get recurrenceGeneratedUntil =>
      $composableBuilder(column: $table.recurrenceGeneratedUntil, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get completedAt =>
      $composableBuilder(column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  $$TasksTableOrderingComposer get parentId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProjectsTableOrderingComposer get projectId {
    final $$ProjectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ProjectsTableOrderingComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TasksTableAnnotationComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title => $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description =>
      $composableBuilder(column: $table.description, builder: (column) => column);

  GeneratedColumn<int> get type => $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get status => $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get priority => $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<int> get dueDate => $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<int> get dueMinute => $composableBuilder(column: $table.dueMinute, builder: (column) => column);

  GeneratedColumn<String> get recurrence => $composableBuilder(column: $table.recurrence, builder: (column) => column);

  GeneratedColumn<int> get recurrenceGeneratedUntil =>
      $composableBuilder(column: $table.recurrenceGeneratedUntil, builder: (column) => column);

  GeneratedColumn<int> get position => $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get completedAt => $composableBuilder(column: $table.completedAt, builder: (column) => column);

  $$TasksTableAnnotationComposer get parentId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProjectsTableAnnotationComposer get projectId {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ProjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> occurrencesRefs<T extends Object>(Expression<T> Function($$OccurrencesTableAnnotationComposer a) f) {
    final $$OccurrencesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.occurrences,
      getReferencedColumn: (t) => t.taskId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$OccurrencesTableAnnotationComposer(
            $db: $db,
            $table: $db.occurrences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> remindersRefs<T extends Object>(Expression<T> Function($$RemindersTableAnnotationComposer a) f) {
    final $$RemindersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reminders,
      getReferencedColumn: (t) => t.taskId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$RemindersTableAnnotationComposer(
            $db: $db,
            $table: $db.reminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTable,
          TaskRow,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (TaskRow, $$TasksTableReferences),
          TaskRow,
          PrefetchHooks Function({bool parentId, bool projectId, bool occurrencesRefs, bool remindersRefs})
        > {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> parentId = const Value.absent(),
                Value<int?> projectId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> type = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<int?> dueDate = const Value.absent(),
                Value<int?> dueMinute = const Value.absent(),
                Value<String?> recurrence = const Value.absent(),
                Value<int?> recurrenceGeneratedUntil = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                parentId: parentId,
                projectId: projectId,
                title: title,
                description: description,
                type: type,
                status: status,
                priority: priority,
                dueDate: dueDate,
                dueMinute: dueMinute,
                recurrence: recurrence,
                recurrenceGeneratedUntil: recurrenceGeneratedUntil,
                position: position,
                createdAt: createdAt,
                updatedAt: updatedAt,
                completedAt: completedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> parentId = const Value.absent(),
                Value<int?> projectId = const Value.absent(),
                required String title,
                Value<String> description = const Value.absent(),
                Value<int> type = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<int?> dueDate = const Value.absent(),
                Value<int?> dueMinute = const Value.absent(),
                Value<String?> recurrence = const Value.absent(),
                Value<int?> recurrenceGeneratedUntil = const Value.absent(),
                Value<int> position = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> completedAt = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                parentId: parentId,
                projectId: projectId,
                title: title,
                description: description,
                type: type,
                status: status,
                priority: priority,
                dueDate: dueDate,
                dueMinute: dueMinute,
                recurrence: recurrence,
                recurrenceGeneratedUntil: recurrenceGeneratedUntil,
                position: position,
                createdAt: createdAt,
                updatedAt: updatedAt,
                completedAt: completedAt,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable<$TasksTable, TaskRow>(table), $$TasksTableReferences(db, table, e))).toList(),
          prefetchHooksCallback:
              ({parentId = false, projectId = false, occurrencesRefs = false, remindersRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (occurrencesRefs) db.occurrences, if (remindersRefs) db.reminders],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (parentId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.parentId,
                            referencedTable: $$TasksTableReferences._parentIdTable(db),
                            referencedColumn: $$TasksTableReferences._parentIdTable(db).id,
                          ) as T;
                        }
                        if (projectId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.projectId,
                            referencedTable: $$TasksTableReferences._projectIdTable(db),
                            referencedColumn: $$TasksTableReferences._projectIdTable(db).id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (occurrencesRefs)
                        await $_getPrefetchedData<TaskRow, $TasksTable, OccurrenceRow>(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences._occurrencesRefsTable(db),
                          managerFromTypedResult: (p0) => $$TasksTableReferences(db, table, p0).occurrencesRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) =>
                              referencedItems.where((e) => e.taskId == item.id),
                          typedResults: items,
                        ),
                      if (remindersRefs)
                        await $_getPrefetchedData<TaskRow, $TasksTable, ReminderRow>(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences._remindersRefsTable(db),
                          managerFromTypedResult: (p0) => $$TasksTableReferences(db, table, p0).remindersRefs,
                          referencedItemsForCurrentItem: (item, referencedItems) =>
                              referencedItems.where((e) => e.taskId == item.id),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTable,
      TaskRow,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (TaskRow, $$TasksTableReferences),
      TaskRow,
      PrefetchHooks Function({bool parentId, bool projectId, bool occurrencesRefs, bool remindersRefs})
    >;
typedef $$OccurrencesTableCreateCompanionBuilder = OccurrencesCompanion Function({
  Value<int> id,
  required int taskId,
  required int date,
  Value<int?> dueMinute,
  Value<int> status,
  required int createdAt,
  required int updatedAt,
  Value<int?> completedAt,
});
typedef $$OccurrencesTableUpdateCompanionBuilder = OccurrencesCompanion Function({
  Value<int> id,
  Value<int> taskId,
  Value<int> date,
  Value<int?> dueMinute,
  Value<int> status,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> completedAt,
});

final class $$OccurrencesTableReferences extends BaseReferences<_$AppDatabase, $OccurrencesTable, OccurrenceRow> {
  $$OccurrencesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TasksTable _taskIdTable(_$AppDatabase db) => db.tasks.createAlias('occurrences__task_id__tasks__id');

  $$TasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<int>('task_id')!;

    final manager = $$TasksTableTableManager($_db, $_db.tasks).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$OccurrencesTableFilterComposer extends Composer<_$AppDatabase, $OccurrencesTable> {
  $$OccurrencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get date => $composableBuilder(column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dueMinute =>
      $composableBuilder(column: $table.dueMinute, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get completedAt =>
      $composableBuilder(column: $table.completedAt, builder: (column) => ColumnFilters(column));

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OccurrencesTableOrderingComposer extends Composer<_$AppDatabase, $OccurrencesTable> {
  $$OccurrencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get date =>
      $composableBuilder(column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dueMinute =>
      $composableBuilder(column: $table.dueMinute, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get completedAt =>
      $composableBuilder(column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OccurrencesTableAnnotationComposer extends Composer<_$AppDatabase, $OccurrencesTable> {
  $$OccurrencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get date => $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get dueMinute => $composableBuilder(column: $table.dueMinute, builder: (column) => column);

  GeneratedColumn<int> get status => $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get completedAt => $composableBuilder(column: $table.completedAt, builder: (column) => column);

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OccurrencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OccurrencesTable,
          OccurrenceRow,
          $$OccurrencesTableFilterComposer,
          $$OccurrencesTableOrderingComposer,
          $$OccurrencesTableAnnotationComposer,
          $$OccurrencesTableCreateCompanionBuilder,
          $$OccurrencesTableUpdateCompanionBuilder,
          (OccurrenceRow, $$OccurrencesTableReferences),
          OccurrenceRow,
          PrefetchHooks Function({bool taskId})
        > {
  $$OccurrencesTableTableManager(_$AppDatabase db, $OccurrencesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$OccurrencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$OccurrencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$OccurrencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> taskId = const Value.absent(),
                Value<int> date = const Value.absent(),
                Value<int?> dueMinute = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
              }) => OccurrencesCompanion(
                id: id,
                taskId: taskId,
                date: date,
                dueMinute: dueMinute,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                completedAt: completedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int taskId,
                required int date,
                Value<int?> dueMinute = const Value.absent(),
                Value<int> status = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> completedAt = const Value.absent(),
              }) => OccurrencesCompanion.insert(
                id: id,
                taskId: taskId,
                date: date,
                dueMinute: dueMinute,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                completedAt: completedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable<$OccurrencesTable, OccurrenceRow>(table), $$OccurrencesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (taskId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.taskId,
                        referencedTable: $$OccurrencesTableReferences._taskIdTable(db),
                        referencedColumn: $$OccurrencesTableReferences._taskIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$OccurrencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OccurrencesTable,
      OccurrenceRow,
      $$OccurrencesTableFilterComposer,
      $$OccurrencesTableOrderingComposer,
      $$OccurrencesTableAnnotationComposer,
      $$OccurrencesTableCreateCompanionBuilder,
      $$OccurrencesTableUpdateCompanionBuilder,
      (OccurrenceRow, $$OccurrencesTableReferences),
      OccurrenceRow,
      PrefetchHooks Function({bool taskId})
    >;
typedef $$RemindersTableCreateCompanionBuilder = RemindersCompanion Function({
  Value<int> id,
  required int taskId,
  required int kind,
  Value<int?> atDate,
  Value<int?> atMinute,
  Value<int?> offsetMinutes,
  Value<String?> repeatRule,
  Value<int?> atUtc,
  Value<int?> occurrenceDate,
  Value<bool> enabled,
  required int createdAt,
});
typedef $$RemindersTableUpdateCompanionBuilder = RemindersCompanion Function({
  Value<int> id,
  Value<int> taskId,
  Value<int> kind,
  Value<int?> atDate,
  Value<int?> atMinute,
  Value<int?> offsetMinutes,
  Value<String?> repeatRule,
  Value<int?> atUtc,
  Value<int?> occurrenceDate,
  Value<bool> enabled,
  Value<int> createdAt,
});

final class $$RemindersTableReferences extends BaseReferences<_$AppDatabase, $RemindersTable, ReminderRow> {
  $$RemindersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TasksTable _taskIdTable(_$AppDatabase db) => db.tasks.createAlias('reminders__task_id__tasks__id');

  $$TasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<int>('task_id')!;

    final manager = $$TasksTableTableManager($_db, $_db.tasks).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$RemindersTableFilterComposer extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get kind => $composableBuilder(column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get atDate =>
      $composableBuilder(column: $table.atDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get atMinute =>
      $composableBuilder(column: $table.atMinute, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get offsetMinutes =>
      $composableBuilder(column: $table.offsetMinutes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get repeatRule =>
      $composableBuilder(column: $table.repeatRule, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get atUtc => $composableBuilder(column: $table.atUtc, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get occurrenceDate =>
      $composableBuilder(column: $table.occurrenceDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RemindersTableOrderingComposer extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get atDate =>
      $composableBuilder(column: $table.atDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get atMinute =>
      $composableBuilder(column: $table.atMinute, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get offsetMinutes =>
      $composableBuilder(column: $table.offsetMinutes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get repeatRule =>
      $composableBuilder(column: $table.repeatRule, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get atUtc =>
      $composableBuilder(column: $table.atUtc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get occurrenceDate =>
      $composableBuilder(column: $table.occurrenceDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RemindersTableAnnotationComposer extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get kind => $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get atDate => $composableBuilder(column: $table.atDate, builder: (column) => column);

  GeneratedColumn<int> get atMinute => $composableBuilder(column: $table.atMinute, builder: (column) => column);

  GeneratedColumn<int> get offsetMinutes =>
      $composableBuilder(column: $table.offsetMinutes, builder: (column) => column);

  GeneratedColumn<String> get repeatRule => $composableBuilder(column: $table.repeatRule, builder: (column) => column);

  GeneratedColumn<int> get atUtc => $composableBuilder(column: $table.atUtc, builder: (column) => column);

  GeneratedColumn<int> get occurrenceDate =>
      $composableBuilder(column: $table.occurrenceDate, builder: (column) => column);

  GeneratedColumn<bool> get enabled => $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemindersTable,
          ReminderRow,
          $$RemindersTableFilterComposer,
          $$RemindersTableOrderingComposer,
          $$RemindersTableAnnotationComposer,
          $$RemindersTableCreateCompanionBuilder,
          $$RemindersTableUpdateCompanionBuilder,
          (ReminderRow, $$RemindersTableReferences),
          ReminderRow,
          PrefetchHooks Function({bool taskId})
        > {
  $$RemindersTableTableManager(_$AppDatabase db, $RemindersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$RemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$RemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$RemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> taskId = const Value.absent(),
                Value<int> kind = const Value.absent(),
                Value<int?> atDate = const Value.absent(),
                Value<int?> atMinute = const Value.absent(),
                Value<int?> offsetMinutes = const Value.absent(),
                Value<String?> repeatRule = const Value.absent(),
                Value<int?> atUtc = const Value.absent(),
                Value<int?> occurrenceDate = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => RemindersCompanion(
                id: id,
                taskId: taskId,
                kind: kind,
                atDate: atDate,
                atMinute: atMinute,
                offsetMinutes: offsetMinutes,
                repeatRule: repeatRule,
                atUtc: atUtc,
                occurrenceDate: occurrenceDate,
                enabled: enabled,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int taskId,
                required int kind,
                Value<int?> atDate = const Value.absent(),
                Value<int?> atMinute = const Value.absent(),
                Value<int?> offsetMinutes = const Value.absent(),
                Value<String?> repeatRule = const Value.absent(),
                Value<int?> atUtc = const Value.absent(),
                Value<int?> occurrenceDate = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                required int createdAt,
              }) => RemindersCompanion.insert(
                id: id,
                taskId: taskId,
                kind: kind,
                atDate: atDate,
                atMinute: atMinute,
                offsetMinutes: offsetMinutes,
                repeatRule: repeatRule,
                atUtc: atUtc,
                occurrenceDate: occurrenceDate,
                enabled: enabled,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$RemindersTable, ReminderRow>(table), $$RemindersTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (taskId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.taskId,
                        referencedTable: $$RemindersTableReferences._taskIdTable(db),
                        referencedColumn: $$RemindersTableReferences._taskIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemindersTable,
      ReminderRow,
      $$RemindersTableFilterComposer,
      $$RemindersTableOrderingComposer,
      $$RemindersTableAnnotationComposer,
      $$RemindersTableCreateCompanionBuilder,
      $$RemindersTableUpdateCompanionBuilder,
      (ReminderRow, $$RemindersTableReferences),
      ReminderRow,
      PrefetchHooks Function({bool taskId})
    >;
typedef $$ScheduledNotificationsTableCreateCompanionBuilder = ScheduledNotificationsCompanion Function({
  Value<int> id,
  required String instanceKey,
  required int reminderId,
  required int taskId,
  Value<int?> occurrenceDate,
  required int fireAt,
  required String title,
  required String body,
  required String signature,
  Value<int?> deliveredAt,
});
typedef $$ScheduledNotificationsTableUpdateCompanionBuilder = ScheduledNotificationsCompanion Function({
  Value<int> id,
  Value<String> instanceKey,
  Value<int> reminderId,
  Value<int> taskId,
  Value<int?> occurrenceDate,
  Value<int> fireAt,
  Value<String> title,
  Value<String> body,
  Value<String> signature,
  Value<int?> deliveredAt,
});

class $$ScheduledNotificationsTableFilterComposer extends Composer<_$AppDatabase, $ScheduledNotificationsTable> {
  $$ScheduledNotificationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get instanceKey =>
      $composableBuilder(column: $table.instanceKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reminderId =>
      $composableBuilder(column: $table.reminderId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get occurrenceDate =>
      $composableBuilder(column: $table.occurrenceDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fireAt =>
      $composableBuilder(column: $table.fireAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get body => $composableBuilder(column: $table.body, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get signature =>
      $composableBuilder(column: $table.signature, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deliveredAt =>
      $composableBuilder(column: $table.deliveredAt, builder: (column) => ColumnFilters(column));
}

class $$ScheduledNotificationsTableOrderingComposer extends Composer<_$AppDatabase, $ScheduledNotificationsTable> {
  $$ScheduledNotificationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get instanceKey =>
      $composableBuilder(column: $table.instanceKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reminderId =>
      $composableBuilder(column: $table.reminderId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get occurrenceDate =>
      $composableBuilder(column: $table.occurrenceDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fireAt =>
      $composableBuilder(column: $table.fireAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get signature =>
      $composableBuilder(column: $table.signature, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deliveredAt =>
      $composableBuilder(column: $table.deliveredAt, builder: (column) => ColumnOrderings(column));
}

class $$ScheduledNotificationsTableAnnotationComposer extends Composer<_$AppDatabase, $ScheduledNotificationsTable> {
  $$ScheduledNotificationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get instanceKey =>
      $composableBuilder(column: $table.instanceKey, builder: (column) => column);

  GeneratedColumn<int> get reminderId => $composableBuilder(column: $table.reminderId, builder: (column) => column);

  GeneratedColumn<int> get taskId => $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<int> get occurrenceDate =>
      $composableBuilder(column: $table.occurrenceDate, builder: (column) => column);

  GeneratedColumn<int> get fireAt => $composableBuilder(column: $table.fireAt, builder: (column) => column);

  GeneratedColumn<String> get title => $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body => $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get signature => $composableBuilder(column: $table.signature, builder: (column) => column);

  GeneratedColumn<int> get deliveredAt => $composableBuilder(column: $table.deliveredAt, builder: (column) => column);
}

class $$ScheduledNotificationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScheduledNotificationsTable,
          ScheduledNotificationRow,
          $$ScheduledNotificationsTableFilterComposer,
          $$ScheduledNotificationsTableOrderingComposer,
          $$ScheduledNotificationsTableAnnotationComposer,
          $$ScheduledNotificationsTableCreateCompanionBuilder,
          $$ScheduledNotificationsTableUpdateCompanionBuilder,
          (
            ScheduledNotificationRow,
            BaseReferences<_$AppDatabase, $ScheduledNotificationsTable, ScheduledNotificationRow>,
          ),
          ScheduledNotificationRow,
          PrefetchHooks Function()
        > {
  $$ScheduledNotificationsTableTableManager(_$AppDatabase db, $ScheduledNotificationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$ScheduledNotificationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$ScheduledNotificationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$ScheduledNotificationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> instanceKey = const Value.absent(),
                Value<int> reminderId = const Value.absent(),
                Value<int> taskId = const Value.absent(),
                Value<int?> occurrenceDate = const Value.absent(),
                Value<int> fireAt = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String> signature = const Value.absent(),
                Value<int?> deliveredAt = const Value.absent(),
              }) => ScheduledNotificationsCompanion(
                id: id,
                instanceKey: instanceKey,
                reminderId: reminderId,
                taskId: taskId,
                occurrenceDate: occurrenceDate,
                fireAt: fireAt,
                title: title,
                body: body,
                signature: signature,
                deliveredAt: deliveredAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String instanceKey,
                required int reminderId,
                required int taskId,
                Value<int?> occurrenceDate = const Value.absent(),
                required int fireAt,
                required String title,
                required String body,
                required String signature,
                Value<int?> deliveredAt = const Value.absent(),
              }) => ScheduledNotificationsCompanion.insert(
                id: id,
                instanceKey: instanceKey,
                reminderId: reminderId,
                taskId: taskId,
                occurrenceDate: occurrenceDate,
                fireAt: fireAt,
                title: title,
                body: body,
                signature: signature,
                deliveredAt: deliveredAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ScheduledNotificationsTable, ScheduledNotificationRow>(table),
                  BaseReferences<_$AppDatabase, $ScheduledNotificationsTable, ScheduledNotificationRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ScheduledNotificationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScheduledNotificationsTable,
      ScheduledNotificationRow,
      $$ScheduledNotificationsTableFilterComposer,
      $$ScheduledNotificationsTableOrderingComposer,
      $$ScheduledNotificationsTableAnnotationComposer,
      $$ScheduledNotificationsTableCreateCompanionBuilder,
      $$ScheduledNotificationsTableUpdateCompanionBuilder,
      (ScheduledNotificationRow, BaseReferences<_$AppDatabase, $ScheduledNotificationsTable, ScheduledNotificationRow>),
      ScheduledNotificationRow,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$SettingsTableOrderingComposer extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$SettingsTableAnnotationComposer extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key => $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value => $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          SettingRow,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (SettingRow, BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, SettingRow>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      SettingRow,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (SettingRow, BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>),
      SettingRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProjectsTableTableManager get projects => $$ProjectsTableTableManager(_db, _db.projects);
  $$TasksTableTableManager get tasks => $$TasksTableTableManager(_db, _db.tasks);
  $$OccurrencesTableTableManager get occurrences => $$OccurrencesTableTableManager(_db, _db.occurrences);
  $$RemindersTableTableManager get reminders => $$RemindersTableTableManager(_db, _db.reminders);
  $$ScheduledNotificationsTableTableManager get scheduledNotifications =>
      $$ScheduledNotificationsTableTableManager(_db, _db.scheduledNotifications);
  $$SettingsTableTableManager get settings => $$SettingsTableTableManager(_db, _db.settings);
}
