import 'dart:convert';

import 'package:azm/core/db/app_database.dart';
import 'package:azm/features/settings/data/backup/backup_codec.dart';
import 'package:azm/features/settings/data/backup/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'backup_test_helpers.dart';

Map<String, Object?> _json(String text) => jsonDecode(text) as Map<String, Object?>;

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  group('round trip', () {
    test('export → wipe → import restores every row identically', () async {
      await seedEverything(db);
      final service = BackupService(db);
      final before = normalized(await dumpUserData(db));

      final text = await service.exportText(now: t(9), appVersion: '1.2.3+4');
      await wipe(db);
      // Device state written after the wipe survives the import untouched.
      await db.writeSetting('onboarding_done', 'true');
      await db.writeSetting('workout_notifications_asked', 'true');
      await service.restore(decodeBackup(text));

      expect(normalized(await dumpUserData(db)), before);
      // Importing the same file twice changes nothing.
      await service.restore(decodeBackup(text));
      expect(normalized(await dumpUserData(db)), before);
    });

    test('import into a fresh database (another phone) restores the same rows', () async {
      await seedEverything(db);
      final text = await BackupService(db).exportText(now: t(9), appVersion: '1.2.3+4');
      final expected = normalized(await dumpUserData(db));

      final other = memoryDb();
      addTearDown(other.close);
      await other.writeSetting('onboarding_done', 'true');
      await other.writeSetting('workout_notifications_asked', 'true');
      await BackupService(other).restore(decodeBackup(text));
      expect(normalized(await dumpUserData(other)), expected);
    });

    test('an active workout in the backup comes back active', () async {
      await seedEverything(db, activeWorkout: true);
      final service = BackupService(db);
      final before = normalized(await dumpUserData(db));
      final contents = decodeBackup(await service.exportText(now: t(9), appVersion: '1.2.3+4'));
      expect(contents.hasActiveWorkout, isTrue);
      await wipe(db);
      await db.writeSetting('onboarding_done', 'true');
      await db.writeSetting('workout_notifications_asked', 'true');
      await service.restore(contents);
      expect(normalized(await dumpUserData(db)), before);
    });

    test('file matches docs/DATA.md: marker, version, meta, settings, six tables', () async {
      await seedEverything(db);
      final json = _json(await BackupService(db).exportText(now: t(9, 14, 30), appVersion: '1.2.3+4'));
      expect(json['format'], 'azm-backup');
      expect(json['version'], 2);
      expect(json['exported_at'], '2026-09-09T14:30:00.000Z');
      expect(json['app_version'], '1.2.3+4');
      expect(json['settings'], {'locale': 'ar', 'theme': 'light', 'unit': 'lb', 'default_rest_seconds': 120});
      for (final table in [
        'routines',
        'routine_exercises',
        'routine_sets',
        'workouts',
        'workout_exercises',
        'workout_sets',
      ]) {
        expect(json[table], isA<List<Object?>>(), reason: table);
      }
      final set = (json['workout_sets']! as List).cast<Map<String, Object?>>().firstWhere(
            (s) => s['id'] == 'f2222222-2222-4222-8222-222222222222',
          );
      expect(set, {
        'id': 'f2222222-2222-4222-8222-222222222222',
        'workout_exercise_id': 'e1111111-1111-4111-8111-111111111111',
        'sort': 1,
        'type': 'normal',
        'weight_kg': 83.91457,
        'reps': 5,
        'completed_at': '2026-09-05T18:09:00.001Z',
        'prefilled': false,
      });
      // Catalog data and device state are never exported.
      expect(json.keys, isNot(contains('exercises')));
      expect((json['settings']! as Map).keys, isNot(contains('onboarding_done')));
    });

    test('an empty database exports and imports as empty', () async {
      final service = BackupService(db);
      final text = await service.exportText(now: t(9), appVersion: '1.2.3+4');
      final contents = decodeBackup(text);
      expect(contents.routines, isEmpty);
      expect(contents.settings, isEmpty);
      await seedEverything(db);
      await service.restore(contents);
      final after = await dumpUserData(db);
      for (final table in after.keys.where((k) => k != 'settings')) {
        expect(after[table], isEmpty, reason: table);
      }
      // Backed-up keys absent from the file are reset to their defaults (deleted).
      expect((after['settings']!.cast<SettingRow>()).map((s) => s.key).toSet(),
          {'onboarding_done', 'workout_notifications_asked'});
    });

    test('file name uses local time: azm-backup-YYYYMMDD-HHmm.json', () {
      expect(backupFileName(DateTime(2026, 3, 7, 5, 9)), 'azm-backup-20260307-0509.json');
      expect(backupFileName(DateTime(2026, 12, 31, 23, 59)), 'azm-backup-20261231-2359.json');
    });
  });

  group('validation (nothing is touched on failure)', () {
    late String valid;
    setUpAll(() async => valid = await validBackupText());

    /// Applies [mutate] to the valid file, expects [error], and checks the DB
    /// (seeded with DIFFERENT data) is byte-for-byte unchanged afterwards.
    Future<void> expectRejected(BackupError error, void Function(Map<String, dynamic> json) mutate) async {
      final json = jsonDecode(valid) as Map<String, dynamic>;
      mutate(json);
      await _expectTextRejected(db, jsonEncode(json), error);
    }

    test('valid file decodes with the right counts', () {
      final c = decodeBackup(valid);
      expect(c.routines, hasLength(2));
      expect(c.routineExercises, hasLength(3));
      expect(c.routineSets, hasLength(4));
      expect(c.workouts, hasLength(2));
      expect(c.workoutExercises, hasLength(2));
      expect(c.workoutSets, hasLength(4));
      expect(c.appVersion, 'test');
    });

    test('not JSON', () async {
      await _expectTextRejected(db, 'hello', BackupError.notJson);
      await _expectTextRejected(db, '{"format": "azm-backup",', BackupError.notJson);
      await _expectTextRejected(db, '', BackupError.notJson);
    });

    test('JSON but not an Azm backup', () async {
      await _expectTextRejected(db, '[1, 2, 3]', BackupError.notAzmBackup);
      await _expectTextRejected(db, '"azm-backup"', BackupError.notAzmBackup);
      await _expectTextRejected(db, '{"routines": []}', BackupError.notAzmBackup);
      await expectRejected(BackupError.notAzmBackup, (j) => j['format'] = 'hevy-export');
      await expectRejected(BackupError.notAzmBackup, (j) => j.remove('format'));
    });

    test('newer version is refused; bad version is corrupt', () async {
      await expectRejected(BackupError.newerVersion, (j) => j['version'] = 3);
      await expectRejected(BackupError.newerVersion, (j) => j['version'] = 99);
      await expectRejected(BackupError.corrupt, (j) => j['version'] = 0);
      await expectRejected(BackupError.corrupt, (j) => j['version'] = '1');
      await expectRejected(BackupError.corrupt, (j) => j['version'] = 1.5);
      await expectRejected(BackupError.corrupt, (j) => j.remove('version'));
    });

    test('missing meta or tables', () async {
      await expectRejected(BackupError.corrupt, (j) => j.remove('exported_at'));
      await expectRejected(BackupError.corrupt, (j) => j['exported_at'] = 'yesterday');
      await expectRejected(BackupError.corrupt, (j) => j.remove('app_version'));
      await expectRejected(BackupError.corrupt, (j) => j.remove('settings'));
      await expectRejected(BackupError.corrupt, (j) => j['settings'] = []);
      for (final table in ['routines', 'routine_exercises', 'routine_sets', 'workouts', 'workout_exercises', 'workout_sets']) {
        await expectRejected(BackupError.corrupt, (j) => j.remove(table));
        await expectRejected(BackupError.corrupt, (j) => j[table] = {'id': 'x'});
        await expectRejected(BackupError.corrupt, (j) => (j[table] as List).add('row'));
      }
    });

    Map<String, dynamic> first(Map<String, dynamic> j, String table) => (j[table] as List).first as Map<String, dynamic>;

    test('wrong types, missing and unknown columns', () async {
      await expectRejected(BackupError.corrupt, (j) => first(j, 'routines')['name'] = 5);
      await expectRejected(BackupError.corrupt, (j) => first(j, 'routines')['sort'] = '0');
      await expectRejected(BackupError.corrupt, (j) => first(j, 'routines')['created_at'] = 12345);
      await expectRejected(BackupError.corrupt, (j) => first(j, 'routines').remove('notes'));
      await expectRejected(BackupError.corrupt, (j) => first(j, 'routines')['colour'] = 'red');
      await expectRejected(BackupError.corrupt, (j) => first(j, 'routine_sets')['target_reps'] = 8.5);
      await expectRejected(BackupError.corrupt, (j) => first(j, 'routine_sets')['target_weight_kg'] = '60');
      await expectRejected(BackupError.corrupt, (j) => first(j, 'routine_exercises')['rest_seconds'] = 0);
      await expectRejected(BackupError.corrupt, (j) => first(j, 'routine_exercises')['exercise_id'] = '');
      await expectRejected(BackupError.corrupt, (j) => first(j, 'workouts')['ended_at'] = 'soon');
      await expectRejected(BackupError.corrupt, (j) => first(j, 'workout_sets')['weight_kg'] = -5);
      await expectRejected(BackupError.corrupt, (j) => first(j, 'workout_sets')['weight_kg'] = null);
      await expectRejected(BackupError.corrupt, (j) => first(j, 'workout_sets')['reps'] = -1);
      await expectRejected(BackupError.corrupt, (j) => first(j, 'workout_sets')['reps'] = 5.0);
    });

    test('ids must be UUID v4 and unique', () async {
      await expectRejected(BackupError.corrupt, (j) => first(j, 'routines')['id'] = 'abc');
      await expectRejected(BackupError.corrupt, (j) => first(j, 'workouts')['id'] = 42);
      // A v1 (time-based) UUID is not v4.
      await expectRejected(BackupError.corrupt,
          (j) => first(j, 'workout_sets')['id'] = 'f1111111-1111-1111-8111-111111111111');
      await expectRejected(BackupError.corrupt, (j) => first(j, 'workouts')['routine_id'] = 'routine-1');
      await expectRejected(BackupError.corrupt, (j) {
        final sets = j['workout_sets'] as List;
        (sets[1] as Map)['id'] = (sets[0] as Map)['id'];
      });
    });

    test('links between tables must resolve', () async {
      const ghost = '99999999-9999-4999-8999-999999999999';
      await expectRejected(BackupError.corrupt, (j) => first(j, 'routine_exercises')['routine_id'] = ghost);
      await expectRejected(BackupError.corrupt, (j) => first(j, 'routine_sets')['routine_exercise_id'] = ghost);
      await expectRejected(BackupError.corrupt, (j) => first(j, 'workout_exercises')['workout_id'] = ghost);
      await expectRejected(BackupError.corrupt, (j) => first(j, 'workout_sets')['workout_exercise_id'] = ghost);
      // Removing a parent orphans its children.
      await expectRejected(BackupError.corrupt, (j) => (j['workouts'] as List).removeAt(0));
    });

    test('enum values', () async {
      await expectRejected(BackupError.corrupt, (j) => first(j, 'routine_sets')['type'] = 'superset');
      await expectRejected(BackupError.corrupt, (j) => first(j, 'workout_sets')['type'] = null);
      await expectRejected(BackupError.corrupt, (j) => first(j, 'workouts')['status'] = 'paused');
      await expectRejected(BackupError.corrupt, (j) {
        for (final w in j['workouts'] as List) {
          (w as Map)['status'] = 'active';
        }
      });
      await expectRejected(BackupError.corrupt, (j) => (j['settings'] as Map)['locale'] = 'fr');
      await expectRejected(BackupError.corrupt, (j) => (j['settings'] as Map)['theme'] = 'sepia');
      await expectRejected(BackupError.corrupt, (j) => (j['settings'] as Map)['unit'] = 'stone');
      await expectRejected(BackupError.corrupt, (j) => (j['settings'] as Map)['default_rest_seconds'] = 0);
      await expectRejected(BackupError.corrupt, (j) => (j['settings'] as Map)['default_rest_seconds'] = '90');
    });

    test('unknown settings keys are ignored, device keys never restored', () {
      final json = jsonDecode(valid) as Map<String, dynamic>;
      (json['settings'] as Map)
        ..['onboarding_done'] = false
        ..['active_rest_ends_at'] = '2026-01-01T00:00:00.000Z'
        ..['future_key'] = {'x': 1};
      final c = decodeBackup(jsonEncode(json));
      expect(c.settings.keys.toSet(), kBackupSettingsKeys.toSet());
    });
  });

  group('restore safety', () {
    test('refused while a workout is active; nothing changes', () async {
      await seedEverything(db, activeWorkout: true);
      final before = normalized(await dumpUserData(db));
      final contents = decodeBackup(await validBackupText());
      final service = BackupService(db);
      expect(await service.hasActiveWorkout(), isTrue);
      await expectLater(service.restore(contents), throwsA(isA<ActiveWorkoutBlocksImport>()));
      expect(normalized(await dumpUserData(db)), before);
    });

    test('a failure half-way rolls back everything (one transaction)', () async {
      await seedEverything(db);
      final before = normalized(await dumpUserData(db));
      final good = decodeBackup(await validBackupText());
      // Bypass the validator: a set pointing at a missing exercise row makes
      // the LAST insert fail on the foreign key, after all deletes ran.
      final broken = BackupContents(
        exportedAt: good.exportedAt,
        appVersion: good.appVersion,
        settings: const {'locale': '"en"'},
        routines: good.routines,
        routineExercises: good.routineExercises,
        routineSets: good.routineSets,
        workouts: good.workouts,
        workoutExercises: good.workoutExercises,
        workoutSets: [
          ...good.workoutSets,
          const WorkoutSet(prefilled: false, 
            id: 'f9999999-9999-4999-8999-999999999999',
            workoutExerciseId: 'e9999999-9999-4999-8999-999999999999',
            sort: 0,
            type: SetType.normal,
            weightKg: 1,
            reps: 1,
          ),
        ],
      );
      await expectLater(BackupService(db).restore(broken), throwsA(anything));
      expect(normalized(await dumpUserData(db)), before);
    });

    test('catalog tables are never exported, deleted or written', () async {
      await db.into(db.exercises).insert(const Exercise(
            id: '0025',
            nameEn: 'Barbell Bench Press',
            aliasesAr: '[]',
            bodyPart: 'chest',
            target: 'pectorals',
            secondaryMuscles: '[]',
            equipment: 'barbell',
            instructionsEn: '[]',
            mediaId: 'x',
            searchNorm: 'barbell bench press',
            hidden: false,
          ));
      await db.into(db.catalogMeta).insert(const CatalogMetaData(version: 7));
      await seedEverything(db);
      final text = await BackupService(db).exportText(now: t(9), appVersion: '1.2.3+4');
      expect(text, isNot(contains('Barbell Bench Press')));
      await BackupService(db).restore(decodeBackup(text));
      expect(await db.select(db.exercises).get(), hasLength(1));
      expect((await db.select(db.catalogMeta).getSingle()).version, 7);
    });
  });
}

Future<void> _expectTextRejected(AppDatabase db, String text, BackupError error) async {
  await wipe(db);
  await seedEverything(db, activeWorkout: false);
  // Make the DB differ from the file so an accidental import would show.
  await db.writeSetting('locale', '"en"');
  final before = normalized(await dumpUserData(db));
  BackupContents? contents;
  try {
    contents = decodeBackup(text);
  } on BackupException catch (e) {
    expect(e.error, error, reason: e.toString());
  }
  expect(contents, isNull, reason: 'expected ${error.name} for: ${text.length > 80 ? text.substring(0, 80) : text}');
  expect(normalized(await dumpUserData(db)), before);
}
