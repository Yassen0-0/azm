import 'package:azm/app.dart';
import 'package:azm/core/db/app_database.dart';
import 'package:azm/core/db/catalog_installer.dart';
import 'package:azm/core/widgets/exercise_card.dart';
import 'package:azm/core/widgets/muscle_chips.dart';
import 'package:azm/features/settings/data/app_settings.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory DB with the REAL bundled catalog installed.
Future<AppDatabase> openCatalogDb() async {
  final db = AppDatabase(NativeDatabase.memory());
  await CatalogInstaller(db).installIfNewer(CatalogData.fromSqliteFile('assets/catalog/catalog.sqlite'));
  return db;
}

/// Empty in-memory DB (no catalog) for pure history tests.
AppDatabase openEmptyDb() => AppDatabase(NativeDatabase.memory());

/// One seeded set: (type, kg, reps, completed).
typedef SeedSet = (SetType, double, int, bool);

/// Inserts a workout with one exercise and its sets. Returns the workout id.
Future<String> seedWorkout(
  AppDatabase db, {
  required String exerciseId,
  required DateTime startedAt,
  required List<SeedSet> sets,
  String name = 'Push',
  WorkoutStatus status = WorkoutStatus.finished,
}) async {
  final w = await db
      .into(db.workouts)
      .insertReturning(
        WorkoutsCompanion.insert(
          name: name,
          startedAt: Value(startedAt.toUtc()),
          endedAt: Value(status == WorkoutStatus.finished ? startedAt.toUtc().add(const Duration(hours: 1)) : null),
          status: Value(status),
        ),
      );
  final we = await db
      .into(db.workoutExercises)
      .insertReturning(WorkoutExercisesCompanion.insert(workoutId: w.id, exerciseId: exerciseId));
  for (final (i, (type, kg, reps, done)) in sets.indexed) {
    await db
        .into(db.workoutSets)
        .insert(
          WorkoutSetsCompanion.insert(
            workoutExerciseId: we.id,
            sort: Value(i),
            type: Value(type),
            weightKg: Value(kg),
            reps: Value(reps),
            completedAt: Value(done ? startedAt.toUtc().add(Duration(minutes: i + 1)) : null),
          ),
        );
  }
  return w.id;
}

/// Pumps the real app (router, theme, l10n) on [db] in [language].
Future<ProviderContainer> pumpAzm(WidgetTester tester, AppDatabase db, LanguagePref language) async {
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      initialAppSettingsProvider.overrideWithValue(AppSettings(language: language)),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const AzmApp()));
  await tester.pumpAndSettle();
  return container;
}

/// Lets DB futures/streams resolve, then settles the UI.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}

/// Ids of the ExerciseCards currently built, top to bottom.
List<String> cardIds() => [
  for (final e in find.byType(ExerciseCard).evaluate()) (e.widget as ExerciseCard).exercise.id,
];

/// Large enough that the list shows many rows.
void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Scrolls the muscle chip row until [label] is on screen, then taps it.
Future<void> tapChip(WidgetTester tester, String label) async {
  final row = find.descendant(of: find.byType(MuscleChips), matching: find.byType(Scrollable)).first;
  final chip = find.descendant(of: find.byType(MuscleChips), matching: find.text(label));
  // From the start of the row, scroll forward until the chip is on screen.
  tester.state<ScrollableState>(row).position.jumpTo(0);
  await settle(tester);
  await tester.scrollUntilVisible(chip.hitTestable(), 150, scrollable: row);
  await settle(tester);
  await tester.tap(chip);
  await settle(tester);
}
