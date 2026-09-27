import 'package:azm/core/db/app_database.dart';
import 'package:azm/core/db/catalog_installer.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Exercise ex(String id, String name) => Exercise(
      id: id,
      nameEn: name,
      nameAr: null,
      aliasesAr: '[]',
      bodyPart: 'chest',
      target: 'pectorals',
      secondaryMuscles: '[]',
      equipment: 'barbell',
      instructionsEn: '["step"]',
      instructionsAr: null,
      mediaId: 'm$id',
      searchNorm: name.toLowerCase(),
      hidden: false,
    );

CatalogData catalog(int version, List<Exercise> exercises) => CatalogData(
      version: version,
      exercises: exercises,
      programs: [CatalogProgram(id: 'p$version', sort: 0, data: '{"id":"p$version"}')],
    );

/// Snapshot of EVERY user table, to prove catalog updates never touch them.
Future<Map<String, List<Map<String, Object?>>>> userSnapshot(AppDatabase db) async {
  final out = <String, List<Map<String, Object?>>>{};
  for (final t in db.allTables) {
    if (catalogTableNames.contains(t.actualTableName)) continue;
    final rows = await db.customSelect('SELECT * FROM ${t.actualTableName} ORDER BY rowid').get();
    out[t.actualTableName] = [for (final r in rows) r.data];
  }
  return out;
}

Future<void> seedUserData(AppDatabase db) async {
  await db.into(db.routines).insert(RoutinesCompanion.insert(id: const Value('r1'), name: 'Push'));
  await db.into(db.routineExercises).insert(
      RoutineExercisesCompanion.insert(id: const Value('re1'), routineId: 'r1', exerciseId: '0001'));
  await db.into(db.routineSets).insert(RoutineSetsCompanion.insert(
      id: const Value('rs1'), routineExerciseId: 're1', targetReps: const Value(8)));
  await db.into(db.workouts).insert(WorkoutsCompanion.insert(
      id: const Value('w1'), name: 'Push', status: const Value(WorkoutStatus.finished)));
  await db.into(db.workoutExercises).insert(
      WorkoutExercisesCompanion.insert(id: const Value('we1'), workoutId: 'w1', exerciseId: '0001'));
  await db.into(db.workoutSets).insert(WorkoutSetsCompanion.insert(
    id: const Value('ws1'),
    workoutExerciseId: 'we1',
    weightKg: const Value(60),
    reps: const Value(8),
    type: const Value(SetType.warmup),
    completedAt: Value(DateTime.utc(2026, 9, 1, 10)),
  ));
  await db.writeSetting('unit', '"kg"');
}

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('catalog update replaces catalog tables and does NOT touch user data', () async {
    final installer = CatalogInstaller(db);
    expect(await installer.installedVersion(), isNull);

    expect(await installer.installIfNewer(catalog(1, [ex('0001', 'Bench'), ex('0002', 'Squat')])), isTrue);
    await seedUserData(db);
    final before = await userSnapshot(db);
    expect(before['workout_sets'], hasLength(1));

    // v2 drops 0001 (still referenced by user history!) and adds 0003.
    expect(await installer.installIfNewer(catalog(2, [ex('0002', 'Squat v2'), ex('0003', 'Row')])), isTrue);

    expect(await userSnapshot(db), before, reason: 'user tables must be byte-identical');
    expect(await installer.installedVersion(), 2);
    final ids = (await db.select(db.exercises).get()).map((e) => e.id);
    expect(ids, unorderedEquals(['0002', '0003']));
    expect((await db.select(db.catalogPrograms).get()).single.id, 'p2');
    expect((await db.select(db.catalogMeta).get()), hasLength(1));
  });

  test('same or older catalog version is not reinstalled', () async {
    final installer = CatalogInstaller(db);
    await installer.installIfNewer(catalog(3, [ex('0001', 'Bench')]));
    expect(await installer.installIfNewer(catalog(3, [ex('0009', 'X')])), isFalse);
    expect(await installer.installIfNewer(catalog(2, [ex('0009', 'X')])), isFalse);
    expect((await db.select(db.exercises).getSingle()).id, '0001');
  });

  test('at most one active workout', () async {
    await db.into(db.workouts).insert(WorkoutsCompanion.insert(name: 'A'));
    await db.into(db.workouts).insert(
        WorkoutsCompanion.insert(name: 'B', status: const Value(WorkoutStatus.finished)));
    expect(
      () => db.into(db.workouts).insert(WorkoutsCompanion.insert(name: 'C')),
      throwsA(isA<SqliteException>()),
    );
  });

  test('user ids are UUID v4 and timestamps are UTC', () async {
    final id = await db.into(db.routines).insertReturning(RoutinesCompanion.insert(name: 'R'));
    expect(id.id, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
    expect(id.createdAt.isUtc, isTrue);
  });

  test('deleting a workout cascades to its exercises and sets', () async {
    await seedUserData(db);
    await (db.delete(db.workouts)..where((w) => w.id.equals('w1'))).go();
    expect(await db.select(db.workoutExercises).get(), isEmpty);
    expect(await db.select(db.workoutSets).get(), isEmpty);
  });
}
