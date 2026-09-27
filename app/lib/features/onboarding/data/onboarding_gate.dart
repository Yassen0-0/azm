import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../routines/data/ready_programs.dart';
import '../../routines/data/routine_repository.dart';
import '../../settings/data/training_settings.dart';
import '../../../core/utils/units.dart';

// First-run gate. bootstrapApp() calls [loadOnboardingDone] before the first
// frame and overrides [onboardingDoneAtLaunchProvider]; the router starts on
// AppRoutes.onboarding when it is false. Screenshot/integration runs
// (bootstrapApp(settingsOverride: …)) always count as done.

/// Settings key (JSON bool, docs/DATA.md).
const String kOnboardingDoneKey = 'onboarding_done';

/// Whether first-run onboarding is behind us: `onboarding_done` = true, or
/// (users who had data before onboarding existed) any workout or routine in
/// the DB. The latter also writes the flag so the check runs only once.
Future<bool> loadOnboardingDone(AppDatabase db) async {
  final raw = await db.readSetting(kOnboardingDoneKey);
  if (raw != null && jsonDecode(raw) == true) return true;
  final hasWorkout = await (db.select(db.workouts)..limit(1)).getSingleOrNull() != null;
  final hasRoutine = await (db.select(db.routines)..limit(1)).getSingleOrNull() != null;
  if (hasWorkout || hasRoutine) {
    await db.writeSetting(kOnboardingDoneKey, jsonEncode(true));
    return true;
  }
  return false;
}

/// Read once by the router for its initial location. Default (tests without
/// bootstrap): done.
final onboardingDoneAtLaunchProvider = Provider<bool>((ref) => true);

/// Finishes onboarding: saves the unit (through settings' writer), copies the
/// chosen ready program (if any) into "My routines", then sets
/// `onboarding_done`. Returns the new routine ids.
class OnboardingController {
  OnboardingController({required this.db, required this.settings, required this.routines});

  final AppDatabase db;
  final TrainingSettingsWriter settings;
  final RoutineRepository routines;

  Future<void> setUnit(WeightUnit unit) => settings.setWeightUnit(unit);

  Future<List<String>> finish({required WeightUnit unit, ReadyProgram? program, required String languageCode}) async {
    await settings.setWeightUnit(unit);
    final ids = program == null
        ? const <String>[]
        : await routines.copyProgram(program, languageCode: languageCode);
    await db.writeSetting(kOnboardingDoneKey, jsonEncode(true));
    return ids;
  }
}

final onboardingControllerProvider = Provider<OnboardingController>(
  (ref) => OnboardingController(
    db: ref.watch(appDatabaseProvider),
    settings: ref.watch(trainingSettingsWriterProvider),
    routines: ref.watch(routineRepositoryProvider),
  ),
);
