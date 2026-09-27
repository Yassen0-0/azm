// Parity screenshots of settings, backup and licences (CLAUDE.md → Platform
// Parity Rule).   AZM_DEVICE_SET=A tools/screenshots.sh settings
// Writes only unit = kg and default rest = 90 s to the device database. The
// import confirmation and the import error are opened directly with an
// in-memory backup: nothing is ever imported on the device, and the system
// share sheet / file picker (not drivable from a test) are never opened.
import 'dart:async';

import 'package:azm/core/db/app_database.dart';
import 'package:azm/core/l10n/l10n.dart';
import 'package:azm/core/router/app_router.dart';
import 'package:azm/core/utils/units.dart';
import 'package:azm/features/settings/data/backup/backup_codec.dart';
import 'package:azm/features/settings/data/training_settings.dart';
import 'package:azm/features/settings/ui/backup_flow.dart';
import 'package:azm/features/settings/ui/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'screenshot_harness.dart';

Future<void> _pumpFor(WidgetTester tester, [int ms = 800]) async {
  for (var t = 0; t < ms; t += 16) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// Settings with known training values (kg, 1:30).
Future<void> _open(WidgetTester tester, ProviderContainer c, GoRouter router) async {
  final writer = c.read(trainingSettingsWriterProvider);
  await writer.setWeightUnit(WeightUnit.kg);
  await writer.setDefaultRestSeconds(kDefaultRestSeconds);
  unawaited(router.push(AppRoutes.settings));
  await _pumpFor(tester);
}

Future<void> _tap(WidgetTester tester, String key) async {
  final f = find.byKey(ValueKey(key));
  await tester.scrollUntilVisible(
    f,
    200,
    scrollable: find.descendant(of: find.byKey(const ValueKey('settings-list')), matching: find.byType(Scrollable)).first,
  );
  await _pumpFor(tester, 300);
  await tester.tap(f);
}

BuildContext _settingsContext(WidgetTester tester) => tester.element(find.byType(SettingsScreen));

/// A believable backup (3 routines, 48 workouts, 1,152 sets), memory only.
BackupContents _sampleBackup() {
  final t = DateTime.utc(2026, 9, 26, 18, 45);
  return BackupContents(
    exportedAt: t,
    appVersion: '1.0.0+1',
    settings: const {},
    routines: [
      for (var i = 0; i < 3; i++) Routine(id: newUuid(), name: 'R$i', sort: i, createdAt: t, updatedAt: t),
    ],
    routineExercises: const [],
    routineSets: const [],
    workouts: [
      for (var i = 0; i < 48; i++)
        Workout(id: newUuid(), name: 'W$i', startedAt: t, endedAt: t, status: WorkoutStatus.finished),
    ],
    workoutExercises: const [],
    workoutSets: [
      for (var i = 0; i < 1152; i++)
        WorkoutSet(id: newUuid(), workoutExerciseId: 'x', sort: i, type: SetType.normal, weightKg: 60, reps: 8),
    ],
  );
}

void main() => runScreenshotSuite('settings', [
      ScreenStep('settings', _open),
      ScreenStep('settings_backup_about', (tester, c, router) async {
        await _open(tester, c, router);
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('settings-licenses')),
          300,
          scrollable:
              find.descendant(of: find.byKey(const ValueKey('settings-list')), matching: find.byType(Scrollable)).first,
        );
      }),
      ScreenStep('unit_picker', (tester, c, router) async {
        await _open(tester, c, router);
        await _tap(tester, 'settings-unit');
      }),
      ScreenStep('rest_picker', (tester, c, router) async {
        await _open(tester, c, router);
        await _tap(tester, 'settings-rest');
      }),
      ScreenStep('import_confirm', (tester, c, router) async {
        await _open(tester, c, router);
        unawaited(showImportConfirmDialog(_settingsContext(tester), _sampleBackup()));
      }),
      ScreenStep('import_error_newer', (tester, c, router) async {
        await _open(tester, c, router);
        final context = _settingsContext(tester);
        unawaited(showImportErrorDialog(
          context,
          message: importErrorMessage(context.l10n, BackupError.newerVersion),
        ));
      }),
      ScreenStep('import_error_active_workout', (tester, c, router) async {
        await _open(tester, c, router);
        final context = _settingsContext(tester);
        unawaited(showImportErrorDialog(context, message: context.l10n.settingsImportErrorActive));
      }),
      ScreenStep('licenses', (tester, c, router) async {
        await _open(tester, c, router);
        await _tap(tester, 'settings-licenses');
      }),
      ScreenStep('licenses_packages', (tester, c, router) async {
        await _open(tester, c, router);
        await _tap(tester, 'settings-licenses');
        await _pumpFor(tester);
        final row = find.byKey(const ValueKey('settings-licenses-packages'));
        await tester.scrollUntilVisible(
          row,
          300,
          scrollable:
              find.descendant(of: find.byKey(const ValueKey('licenses-list')), matching: find.byType(Scrollable)).first,
        );
        await _pumpFor(tester, 300);
        await tester.tap(row);
        await _pumpFor(tester, 1500);
      }),
    ]);
