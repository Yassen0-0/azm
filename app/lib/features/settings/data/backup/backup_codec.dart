import 'dart:convert';

import '../../../../core/db/app_database.dart';
import '../app_settings.dart' show LanguagePref, SettingsKeys, ThemePref;
import '../training_settings.dart' show TrainingSettingsKeys;

// Backup file format: docs/DATA.md → Backup format. Pure Dart (no Flutter, no
// DB access): encode rows → JSON text, and decode + FULLY validate JSON text
// → rows. Nothing here touches the database, so a rejected file can never
// change existing data.

/// Format marker of every Azm backup file.
const String kBackupFormat = 'azm-backup';

/// The backup version this build writes; it reads every version up to it
/// and rejects newer ones. v2 (schema v3): `workout_exercises.rest_seconds`
/// (0 = rest OFF) and `workout_sets.prefilled`.
const int kBackupVersion = 2;

/// Settings keys that travel in a backup (decision in DECISIONS_LOG → Window E).
/// Everything else (onboarding flag, permission prompts, the running rest
/// timer) is device state and is neither exported nor overwritten.
const List<String> kBackupSettingsKeys = [
  SettingsKeys.locale,
  SettingsKeys.theme,
  TrainingSettingsKeys.unit,
  TrainingSettingsKeys.defaultRestSeconds,
];

/// Why a file was rejected. The UI maps each to a message.
enum BackupError {
  /// Not valid UTF-8 JSON at all.
  notJson,

  /// JSON, but not an Azm backup (no/other format marker).
  notAzmBackup,

  /// An Azm backup written by a newer app version.
  newerVersion,

  /// An Azm backup whose content is broken (types, ids, links, values).
  corrupt,
}

class BackupException implements Exception {
  const BackupException(this.error, [this.detail = '']);

  final BackupError error;

  /// Developer detail (which table/row/column); never shown to the user.
  final String detail;

  @override
  String toString() => 'BackupException(${error.name}${detail.isEmpty ? '' : ': $detail'})';
}

/// Everything a backup holds, typed and validated.
class BackupContents {
  const BackupContents({
    required this.exportedAt,
    required this.appVersion,
    required this.settings,
    required this.routines,
    required this.routineExercises,
    required this.routineSets,
    required this.workouts,
    required this.workoutExercises,
    required this.workoutSets,
  });

  final DateTime exportedAt;
  final String appVersion;

  /// Restorable settings: key → JSON-encoded value (as stored in `settings`).
  final Map<String, String> settings;
  final List<Routine> routines;
  final List<RoutineExercise> routineExercises;
  final List<RoutineSet> routineSets;
  final List<Workout> workouts;
  final List<WorkoutExercise> workoutExercises;
  final List<WorkoutSet> workoutSets;

  /// True when the backup holds a workout that was still running at export.
  bool get hasActiveWorkout => workouts.any((w) => w.status == WorkoutStatus.active);
}

// ------------------------------- Encoding ----------------------------------

String _ts(DateTime d) => d.toUtc().toIso8601String();
String? _tsOrNull(DateTime? d) => d == null ? null : _ts(d);

/// Encodes [contents] as the backup JSON text (pretty-printed, stable order).
String encodeBackup(BackupContents contents) {
  final json = <String, Object?>{
    'format': kBackupFormat,
    'version': kBackupVersion,
    'exported_at': _ts(contents.exportedAt),
    'app_version': contents.appVersion,
    'settings': {
      for (final e in contents.settings.entries) e.key: jsonDecode(e.value),
    },
    'routines': [
      for (final r in contents.routines)
        {
          'id': r.id,
          'name': r.name,
          'notes': r.notes,
          'sort': r.sort,
          'created_at': _ts(r.createdAt),
          'updated_at': _ts(r.updatedAt),
        },
    ],
    'routine_exercises': [
      for (final e in contents.routineExercises)
        {
          'id': e.id,
          'routine_id': e.routineId,
          'exercise_id': e.exerciseId,
          'sort': e.sort,
          'rest_seconds': e.restSeconds,
          'notes': e.notes,
        },
    ],
    'routine_sets': [
      for (final s in contents.routineSets)
        {
          'id': s.id,
          'routine_exercise_id': s.routineExerciseId,
          'sort': s.sort,
          'type': s.type.name,
          'target_reps': s.targetReps,
          'target_weight_kg': s.targetWeightKg,
        },
    ],
    'workouts': [
      for (final w in contents.workouts)
        {
          'id': w.id,
          'routine_id': w.routineId,
          'name': w.name,
          'started_at': _ts(w.startedAt),
          'ended_at': _tsOrNull(w.endedAt),
          'status': w.status.name,
          'notes': w.notes,
        },
    ],
    'workout_exercises': [
      for (final e in contents.workoutExercises)
        {
          'id': e.id,
          'workout_id': e.workoutId,
          'exercise_id': e.exerciseId,
          'sort': e.sort,
          'notes': e.notes,
          'rest_seconds': e.restSeconds,
        },
    ],
    'workout_sets': [
      for (final s in contents.workoutSets)
        {
          'id': s.id,
          'workout_exercise_id': s.workoutExerciseId,
          'sort': s.sort,
          'type': s.type.name,
          'weight_kg': s.weightKg,
          'reps': s.reps,
          'completed_at': _tsOrNull(s.completedAt),
          'prefilled': s.prefilled,
        },
    ],
  };
  return const JsonEncoder.withIndent(' ').convert(json);
}

/// `azm-backup-YYYYMMDD-HHmm.json` for the given LOCAL time.
String backupFileName(DateTime local) {
  String two(int v) => v.toString().padLeft(2, '0');
  return 'azm-backup-${local.year}${two(local.month)}${two(local.day)}'
      '-${two(local.hour)}${two(local.minute)}.json';
}

// ------------------------------- Decoding ----------------------------------

final RegExp _uuidV4 =
    RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$', caseSensitive: false);

/// Reads one row's columns; every failure is a [BackupError.corrupt].
class _Row {
  _Row(this.table, this.index, Object? raw, Set<String> columns) {
    if (raw is! Map<String, Object?>) _fail('row is not an object');
    map = raw;
    final missing = columns.difference(map.keys.toSet());
    final extra = map.keys.toSet().difference(columns);
    if (missing.isNotEmpty) _fail('missing $missing');
    if (extra.isNotEmpty) _fail('unknown columns $extra');
  }

  final String table;
  final int index;
  late final Map<String, Object?> map;

  Never _fail(String why) => throw BackupException(BackupError.corrupt, '$table[$index]: $why');

  String uuid(String c) {
    final v = map[c];
    if (v is! String || !_uuidV4.hasMatch(v)) _fail('$c is not a UUID v4');
    return v;
  }

  String? uuidOrNull(String c) => map[c] == null ? null : uuid(c);

  String string(String c, {bool nonEmpty = false}) {
    final v = map[c];
    if (v is! String || (nonEmpty && v.trim().isEmpty)) _fail('$c is not a string');
    return v;
  }

  String? stringOrNull(String c) => map[c] == null ? null : string(c);

  int integer(String c, {int min = 0}) {
    final v = map[c];
    if (v is! int || v < min) _fail('$c is not an integer ≥ $min');
    return v;
  }

  int? integerOrNull(String c, {int min = 0}) => map[c] == null ? null : integer(c, min: min);

  bool boolean(String c) {
    final v = map[c];
    if (v is! bool) _fail('$c is not a boolean');
    return v;
  }

  double kg(String c) {
    final v = map[c];
    if (v is! num || !v.isFinite || v < 0) _fail('$c is not a weight ≥ 0');
    return v.toDouble();
  }

  double? kgOrNull(String c) => map[c] == null ? null : kg(c);

  DateTime time(String c) {
    final v = map[c];
    final t = v is String ? DateTime.tryParse(v) : null;
    if (t == null) _fail('$c is not an ISO-8601 time');
    return t.toUtc();
  }

  DateTime? timeOrNull(String c) => map[c] == null ? null : time(c);

  T enumValue<T extends Enum>(String c, List<T> values) {
    final v = map[c];
    for (final e in values) {
      if (e.name == v) return e;
    }
    _fail('$c has unknown value $v');
  }
}

List<T> _table<T>(
  Map<String, Object?> root,
  String name,
  Set<String> columns,
  T Function(_Row row) read,
) {
  final raw = root[name];
  if (raw is! List) throw BackupException(BackupError.corrupt, '$name is missing or not a list');
  final rows = [for (var i = 0; i < raw.length; i++) read(_Row(name, i, raw[i], columns))];
  return rows;
}

void _uniqueIds(String table, Iterable<String> ids) {
  final seen = <String>{};
  for (final id in ids) {
    if (!seen.add(id)) throw BackupException(BackupError.corrupt, '$table: duplicate id $id');
  }
}

void _links(String table, String column, Iterable<String> refs, Set<String> parents) {
  for (final r in refs) {
    if (!parents.contains(r)) throw BackupException(BackupError.corrupt, '$table.$column → missing $r');
  }
}

/// Validated JSON value of a restorable setting, re-encoded for storage.
String _settingValue(String key, Object? v) {
  final ok = switch (key) {
    SettingsKeys.locale => LanguagePref.values.any((e) => e.name == v),
    SettingsKeys.theme => ThemePref.values.any((e) => e.name == v),
    TrainingSettingsKeys.unit => v == 'kg' || v == 'lb',
    TrainingSettingsKeys.defaultRestSeconds => v is int && v > 0,
    _ => false,
  };
  if (!ok) throw BackupException(BackupError.corrupt, 'settings.$key has invalid value $v');
  return jsonEncode(v);
}

/// Decodes and validates a backup file's [text]. Throws [BackupException]
/// on the FIRST problem; returns only fully consistent contents.
BackupContents decodeBackup(String text) {
  final Object? root;
  try {
    root = jsonDecode(text);
  } on FormatException catch (e) {
    throw BackupException(BackupError.notJson, e.message);
  }
  if (root is! Map<String, Object?> || root['format'] != kBackupFormat) {
    throw const BackupException(BackupError.notAzmBackup);
  }
  final version = root['version'];
  if (version is! int || version < 1) {
    throw BackupException(BackupError.corrupt, 'version $version');
  }
  if (version > kBackupVersion) {
    throw BackupException(BackupError.newerVersion, 'version $version');
  }

  final exportedAt = root['exported_at'];
  final exportedTime = exportedAt is String ? DateTime.tryParse(exportedAt) : null;
  if (exportedTime == null) throw const BackupException(BackupError.corrupt, 'exported_at');
  final appVersion = root['app_version'];
  if (appVersion is! String) throw const BackupException(BackupError.corrupt, 'app_version');

  final rawSettings = root['settings'];
  if (rawSettings is! Map<String, Object?>) {
    throw const BackupException(BackupError.corrupt, 'settings is missing or not an object');
  }
  // Unknown keys (e.g. device state from another build) are ignored on purpose.
  final settings = {
    for (final key in kBackupSettingsKeys)
      if (rawSettings[key] != null) key: _settingValue(key, rawSettings[key]),
  };

  final routines = _table(
    root,
    'routines',
    {'id', 'name', 'notes', 'sort', 'created_at', 'updated_at'},
    (r) => Routine(
      id: r.uuid('id'),
      name: r.string('name'),
      notes: r.stringOrNull('notes'),
      sort: r.integer('sort', min: -1 << 31),
      createdAt: r.time('created_at'),
      updatedAt: r.time('updated_at'),
    ),
  );
  final routineExercises = _table(
    root,
    'routine_exercises',
    {'id', 'routine_id', 'exercise_id', 'sort', 'rest_seconds', 'notes'},
    (r) => RoutineExercise(
      id: r.uuid('id'),
      routineId: r.uuid('routine_id'),
      exerciseId: r.string('exercise_id', nonEmpty: true),
      sort: r.integer('sort', min: -1 << 31),
      restSeconds: r.integerOrNull('rest_seconds', min: 1),
      notes: r.stringOrNull('notes'),
    ),
  );
  final routineSets = _table(
    root,
    'routine_sets',
    {'id', 'routine_exercise_id', 'sort', 'type', 'target_reps', 'target_weight_kg'},
    (r) => RoutineSet(
      id: r.uuid('id'),
      routineExerciseId: r.uuid('routine_exercise_id'),
      sort: r.integer('sort', min: -1 << 31),
      type: r.enumValue('type', SetType.values),
      targetReps: r.integerOrNull('target_reps'),
      targetWeightKg: r.kgOrNull('target_weight_kg'),
    ),
  );
  final workouts = _table(
    root,
    'workouts',
    {'id', 'routine_id', 'name', 'started_at', 'ended_at', 'status', 'notes'},
    (r) => Workout(
      id: r.uuid('id'),
      routineId: r.uuidOrNull('routine_id'),
      name: r.string('name'),
      startedAt: r.time('started_at'),
      endedAt: r.timeOrNull('ended_at'),
      status: r.enumValue('status', WorkoutStatus.values),
      notes: r.stringOrNull('notes'),
    ),
  );
  final workoutExercises = _table(
    root,
    'workout_exercises',
    {'id', 'workout_id', 'exercise_id', 'sort', 'notes', if (version >= 2) 'rest_seconds'},
    (r) => WorkoutExercise(
      id: r.uuid('id'),
      workoutId: r.uuid('workout_id'),
      exerciseId: r.string('exercise_id', nonEmpty: true),
      sort: r.integer('sort', min: -1 << 31),
      notes: r.stringOrNull('notes'),
      restSeconds: version >= 2 ? r.integerOrNull('rest_seconds') : null,
    ),
  );
  final workoutSets = _table(
    root,
    'workout_sets',
    {'id', 'workout_exercise_id', 'sort', 'type', 'weight_kg', 'reps', 'completed_at', if (version >= 2) 'prefilled'},
    (r) => WorkoutSet(
      id: r.uuid('id'),
      workoutExerciseId: r.uuid('workout_exercise_id'),
      sort: r.integer('sort', min: -1 << 31),
      type: r.enumValue('type', SetType.values),
      weightKg: r.kg('weight_kg'),
      reps: r.integer('reps'),
      completedAt: r.timeOrNull('completed_at'),
      prefilled: version >= 2 && r.boolean('prefilled'),
    ),
  );

  // Primary keys and links (the DB's foreign keys, checked up front).
  _uniqueIds('routines', routines.map((e) => e.id));
  _uniqueIds('routine_exercises', routineExercises.map((e) => e.id));
  _uniqueIds('routine_sets', routineSets.map((e) => e.id));
  _uniqueIds('workouts', workouts.map((e) => e.id));
  _uniqueIds('workout_exercises', workoutExercises.map((e) => e.id));
  _uniqueIds('workout_sets', workoutSets.map((e) => e.id));
  _links('routine_exercises', 'routine_id', routineExercises.map((e) => e.routineId),
      routines.map((e) => e.id).toSet());
  _links('routine_sets', 'routine_exercise_id', routineSets.map((e) => e.routineExerciseId),
      routineExercises.map((e) => e.id).toSet());
  _links('workout_exercises', 'workout_id', workoutExercises.map((e) => e.workoutId),
      workouts.map((e) => e.id).toSet());
  _links('workout_sets', 'workout_exercise_id', workoutSets.map((e) => e.workoutExerciseId),
      workoutExercises.map((e) => e.id).toSet());
  if (workouts.where((w) => w.status == WorkoutStatus.active).length > 1) {
    throw const BackupException(BackupError.corrupt, 'more than one active workout');
  }

  return BackupContents(
    exportedAt: exportedTime.toUtc(),
    appVersion: appVersion,
    settings: settings,
    routines: routines,
    routineExercises: routineExercises,
    routineSets: routineSets,
    workouts: workouts,
    workoutExercises: workoutExercises,
    workoutSets: workoutSets,
  );
}
