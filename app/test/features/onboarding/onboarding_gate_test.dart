import 'dart:convert';

import 'package:azm/core/db/app_database.dart';
import 'package:azm/core/utils/units.dart';
import 'package:azm/features/onboarding/data/onboarding_gate.dart';
import 'package:azm/features/routines/data/ready_programs.dart';
import 'package:azm/features/routines/data/routine_repository.dart';
import 'package:azm/features/settings/data/training_settings.dart';
import 'package:azm/features/workout/data/workout_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../routines/routines_test_helpers.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = openRoutinesTestDb();
    await seedRoutinesCatalog(db);
  });
  tearDown(() => db.close());

  OnboardingController controller() => OnboardingController(
        db: db,
        settings: TrainingSettingsWriter(db),
        routines: RoutineRepository(db),
      );

  test('fresh install → onboarding; onboarding_done true → skipped', () async {
    expect(await loadOnboardingDone(db), isFalse);
    await db.writeSetting(kOnboardingDoneKey, jsonEncode(false));
    expect(await loadOnboardingDone(db), isFalse);
    await db.writeSetting(kOnboardingDoneKey, jsonEncode(true));
    expect(await loadOnboardingDone(db), isTrue);
  });

  test('existing users with data skip onboarding (and the flag is written)', () async {
    await WorkoutRepository(db).startEmpty('Evening');
    expect(await loadOnboardingDone(db), isTrue);
    expect(await db.readSetting(kOnboardingDoneKey), 'true');
  });

  test('existing routines also count as data', () async {
    await RoutineRepository(db).create(name: 'Push');
    expect(await loadOnboardingDone(db), isTrue);
  });

  test('finish without a program: unit + flag, no routines', () async {
    final ids = await controller().finish(unit: WeightUnit.lb, languageCode: 'en');
    expect(ids, isEmpty);
    expect(parseWeightUnit(await db.readSetting(TrainingSettingsKeys.unit)), WeightUnit.lb);
    expect(await loadOnboardingDone(db), isTrue);
    expect(await db.select(db.routines).get(), isEmpty);
  });

  test('finish with a program copies it in the app language', () async {
    final program = ReadyProgram.fromJson(testProgramJson);
    final ids = await controller().finish(unit: WeightUnit.kg, program: program, languageCode: 'ar');
    expect(ids, hasLength(2));
    final names = [for (final r in await RoutineRepository(db).loadRoutines()) r.routine.name];
    expect(names, ['يوم أ', 'يوم ب']);
    expect(parseWeightUnit(await db.readSetting(TrainingSettingsKeys.unit)), WeightUnit.kg);
    expect(await db.readSetting(kOnboardingDoneKey), 'true');
  });
}
