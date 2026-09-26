import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../utils/workout_math.dart' show SetType;

export '../utils/workout_math.dart' show SetType;

// Schema: docs/DATA.md. Catalog tables are read-only and replaced wholesale by
// CatalogInstaller; user tables are NEVER touched by catalog updates.
// Timestamps: UTC, stored as ISO-8601 text (build.yaml). Weights: kg.

const _uuid = Uuid();
/// New UUID v4 for user records (public: drift copies defaults into the .g.dart part).
String newUuid() => _uuid.v4();
/// Current time in UTC (all stored timestamps are UTC).
DateTime utcNow() => DateTime.now().toUtc();

// ============================ CATALOG (read-only) ============================

/// Single row: the installed catalog version.
class CatalogMeta extends Table {
  IntColumn get version => integer()();
}

@DataClassName('Exercise')
class Exercises extends Table {
  /// Dataset id, e.g. "0025".
  TextColumn get id => text()();
  TextColumn get nameEn => text()();
  TextColumn get nameAr => text().nullable()();

  /// JSON array of Egyptian-gym slang aliases.
  TextColumn get aliasesAr => text().withDefault(const Constant('[]'))();
  TextColumn get bodyPart => text()();
  TextColumn get target => text()();

  /// JSON array of muscle keys.
  TextColumn get secondaryMuscles => text().withDefault(const Constant('[]'))();
  TextColumn get equipment => text()();

  /// JSON array of instruction steps.
  TextColumn get instructionsEn => text()();
  TextColumn get instructionsAr => text().nullable()();
  TextColumn get mediaId => text()();

  /// normalizeForSearch(name_en + name_ar + aliases).
  TextColumn get searchNorm => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Ready-made programs (data/programs/programs.json), one JSON doc per row.
@DataClassName('CatalogProgram')
class CatalogPrograms extends Table {
  TextColumn get id => text()();
  IntColumn get sort => integer()();
  TextColumn get data => text()();

  @override
  Set<Column> get primaryKey => {id};
}

// ================================ USER DATA =================================

enum WorkoutStatus { active, finished }

class Routines extends Table {
  TextColumn get id => text().clientDefault(newUuid)();
  TextColumn get name => text()();
  TextColumn get notes => text().nullable()();
  IntColumn get sort => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().clientDefault(utcNow)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(utcNow)();

  @override
  Set<Column> get primaryKey => {id};
}

class RoutineExercises extends Table {
  TextColumn get id => text().clientDefault(newUuid)();
  TextColumn get routineId => text().references(Routines, #id, onDelete: KeyAction.cascade)();

  /// Catalog exercise id. No FK: the catalog is replaceable.
  TextColumn get exerciseId => text()();
  IntColumn get sort => integer().withDefault(const Constant(0))();
  IntColumn get restSeconds => integer().nullable()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class RoutineSets extends Table {
  TextColumn get id => text().clientDefault(newUuid)();
  TextColumn get routineExerciseId =>
      text().references(RoutineExercises, #id, onDelete: KeyAction.cascade)();
  IntColumn get sort => integer().withDefault(const Constant(0))();
  TextColumn get type => textEnum<SetType>().withDefault(Constant(SetType.normal.name))();
  IntColumn get targetReps => integer().nullable()();
  RealColumn get targetWeightKg => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// At most ONE row with status = active (partial unique index, see AppDatabase).
class Workouts extends Table {
  TextColumn get id => text().clientDefault(newUuid)();

  /// Source routine, if any. No FK: the routine may be deleted later.
  TextColumn get routineId => text().nullable()();
  TextColumn get name => text()();
  DateTimeColumn get startedAt => dateTime().clientDefault(utcNow)();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get status =>
      textEnum<WorkoutStatus>().withDefault(Constant(WorkoutStatus.active.name))();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class WorkoutExercises extends Table {
  TextColumn get id => text().clientDefault(newUuid)();
  TextColumn get workoutId => text().references(Workouts, #id, onDelete: KeyAction.cascade)();

  /// Catalog exercise id. No FK: history must survive catalog changes.
  TextColumn get exerciseId => text()();
  IntColumn get sort => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class WorkoutSets extends Table {
  TextColumn get id => text().clientDefault(newUuid)();
  TextColumn get workoutExerciseId =>
      text().references(WorkoutExercises, #id, onDelete: KeyAction.cascade)();
  IntColumn get sort => integer().withDefault(const Constant(0))();
  TextColumn get type => textEnum<SetType>().withDefault(Constant(SetType.normal.name))();
  RealColumn get weightKg => real().withDefault(const Constant(0))();
  IntColumn get reps => integer().withDefault(const Constant(0))();

  /// Null = not ✓.
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Key/value app settings; value is JSON-encoded (DATA.md lists the keys).
@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
