import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tables.dart';

export 'tables.dart';

part 'app_database.g.dart';

/// Tables that belong to the replaceable catalog (everything else is user data).
const catalogTableNames = {'catalog_meta', 'exercises', 'catalog_programs'};

@DriftDatabase(
  tables: [
    CatalogMeta,
    Exercises,
    CatalogPrograms,
    Routines,
    RoutineExercises,
    RoutineSets,
    Workouts,
    WorkoutExercises,
    WorkoutSets,
    Settings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// The on-device database (`azm.sqlite` in the app documents directory).
  factory AppDatabase.open() => AppDatabase(driftDatabase(name: 'azm'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement(
            "CREATE UNIQUE INDEX IF NOT EXISTS workouts_one_active "
            "ON workouts (status) WHERE status = 'active'",
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS workout_exercises_exercise '
            'ON workout_exercises (exercise_id)',
          );
        },
        onUpgrade: (m, from, to) async {
          // v2: catalog `exercises.hidden`. Catalog-only; the bundled catalog
          // (newer version) is re-installed right after opening.
          if (from < 2) await m.addColumn(exercises, exercises.hidden);
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  // ---- Settings (key → JSON value) -----------------------------------------

  Future<String?> readSetting(String key) async {
    final row = await (select(settings)..where((s) => s.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> writeSetting(String key, String jsonValue) =>
      into(settings).insertOnConflictUpdate(SettingRow(key: key, value: jsonValue));
}

/// The app database. Overridden in `main()` with the opened instance.
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('appDatabaseProvider must be overridden in main()'),
);
