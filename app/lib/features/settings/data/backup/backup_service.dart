import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/db/app_database.dart';
import 'backup_codec.dart';

/// Import refused because a workout is running (DECISIONS_LOG → Window E).
class ActiveWorkoutBlocksImport implements Exception {
  const ActiveWorkoutBlocksImport();
}

/// Reads every user table for export and replaces them all on import.
/// Catalog tables are never read or written here.
class BackupService {
  const BackupService(this.db);

  final AppDatabase db;

  /// Everything the backup holds, as currently stored.
  /// [appVersion] is the running build (`appVersionProvider` → `AppVersion.full`).
  Future<BackupContents> snapshot({required DateTime exportedAt, required String appVersion}) =>
      db.transaction(() async {
        final settingRows =
            await (db.select(db.settings)..where((s) => s.key.isIn(kBackupSettingsKeys))).get();
        return BackupContents(
          exportedAt: exportedAt,
          appVersion: appVersion,
          settings: {for (final s in settingRows) s.key: s.value},
          routines: await (db.select(db.routines)..orderBy([(t) => OrderingTerm(expression: t.id)])).get(),
          routineExercises:
              await (db.select(db.routineExercises)..orderBy([(t) => OrderingTerm(expression: t.id)])).get(),
          routineSets: await (db.select(db.routineSets)..orderBy([(t) => OrderingTerm(expression: t.id)])).get(),
          workouts: await (db.select(db.workouts)..orderBy([(t) => OrderingTerm(expression: t.id)])).get(),
          workoutExercises:
              await (db.select(db.workoutExercises)..orderBy([(t) => OrderingTerm(expression: t.id)])).get(),
          workoutSets: await (db.select(db.workoutSets)..orderBy([(t) => OrderingTerm(expression: t.id)])).get(),
        );
      });

  /// The backup file text for "now".
  Future<String> exportText({required DateTime now, required String appVersion}) async =>
      encodeBackup(await snapshot(exportedAt: now, appVersion: appVersion));

  /// True while a workout is running (import is refused then).
  Future<bool> hasActiveWorkout() async {
    final row = await (db.select(db.workouts)
          ..where((w) => w.status.equalsValue(WorkoutStatus.active))
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }

  /// Replaces ALL user tables and the backed-up settings with [contents], in
  /// one transaction: either everything is replaced or nothing changes.
  /// [contents] must come from [decodeBackup] (already validated).
  Future<void> restore(BackupContents contents) => db.transaction(() async {
        if (await hasActiveWorkout()) throw const ActiveWorkoutBlocksImport();
        // Children first (cascades would do it too; explicit is clearer).
        await db.delete(db.workoutSets).go();
        await db.delete(db.workoutExercises).go();
        await db.delete(db.workouts).go();
        await db.delete(db.routineSets).go();
        await db.delete(db.routineExercises).go();
        await db.delete(db.routines).go();
        await db.batch((b) {
          b.insertAll(db.routines, contents.routines);
          b.insertAll(db.routineExercises, contents.routineExercises);
          b.insertAll(db.routineSets, contents.routineSets);
          b.insertAll(db.workouts, contents.workouts);
          b.insertAll(db.workoutExercises, contents.workoutExercises);
          b.insertAll(db.workoutSets, contents.workoutSets);
          for (final key in kBackupSettingsKeys) {
            final value = contents.settings[key];
            if (value == null) {
              b.deleteWhere(db.settings, (s) => s.key.equals(key));
            } else {
              b.insert(db.settings, SettingRow(key: key, value: value), mode: InsertMode.insertOrReplace);
            }
          }
        });
      });
}

final backupServiceProvider = Provider<BackupService>((ref) => BackupService(ref.watch(appDatabaseProvider)));
