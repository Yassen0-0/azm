import 'dart:convert';

import 'package:azm/app.dart';
import 'package:azm/core/db/app_database.dart';
import 'package:azm/core/db/catalog_installer.dart';
import 'package:azm/core/widgets/exercise_card.dart';
import 'package:azm/features/exercises/data/exercise_filters.dart';
import 'package:azm/features/exercises/ui/filter_sheet.dart';
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

/// Opens the [kind] filter sheet, toggles the cards [ids] and applies them
/// with "Show N results".
Future<void> applyFilter(WidgetTester tester, FilterKind kind, List<String> ids) async {
  await openFilterSheet(tester, kind);
  for (final id in ids) {
    await tapFilterCard(tester, kind, id);
  }
  await tester.tap(find.byKey(FilterKeys.showResults));
  await settle(tester);
}

Future<void> openFilterSheet(WidgetTester tester, FilterKind kind) async {
  await tester.tap(find.byKey(FilterKeys.chip(kind)));
  await settle(tester);
}

/// Scrolls the open sheet until the card is visible, then taps it.
Future<void> tapFilterCard(WidgetTester tester, FilterKind kind, String id) async {
  final card = find.byKey(FilterKeys.card(kind, id));
  await tester.scrollUntilVisible(
    card.hitTestable(),
    120,
    scrollable: find.descendant(of: find.byType(BottomSheet), matching: find.byType(Scrollable)).first,
  );
  await settle(tester);
  await tester.tap(card);
  await settle(tester);
}

/// Label of the sheet's primary button ("Show N results").
String showResultsLabel(WidgetTester tester) =>
    (tester.widget<FilledButton>(find.byKey(FilterKeys.showResults)).child! as Text).data!;

/// Decoded JSON value of a settings key (null when unset).
Future<Object?> readSettingJson(AppDatabase db, String key) async {
  final v = await db.readSetting(key);
  return v == null ? null : jsonDecode(v);
}
