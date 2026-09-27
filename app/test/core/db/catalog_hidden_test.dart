import 'dart:convert';
import 'dart:io';

import 'package:azm/core/db/app_database.dart';
import 'package:azm/core/db/catalog_installer.dart';
import 'package:azm/core/db/catalog_repository.dart';
import 'package:azm/features/history/data/history_repository.dart';
import 'package:azm/features/workout/data/workout_repository.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hidden duplicates (data/hidden_exercises.json, docs/review/duplicates.md):
/// never listed or searched, but old user data that references them resolves.
/// Uses the REAL bundled catalog.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final hidden = ((jsonDecode(File('../data/hidden_exercises.json').readAsStringSync())
          as Map<String, dynamic>)['hidden'] as Map<String, dynamic>)
      .cast<String, String>();
  late CatalogData catalog;

  setUpAll(() => catalog = CatalogData.fromSqliteFile('assets/catalog/catalog.sqlite'));

  Future<AppDatabase> openWithCatalog() async {
    final db = AppDatabase(NativeDatabase.memory());
    await CatalogInstaller(db).installIfNewer(catalog);
    return db;
  }

  test('the bundled catalog flags exactly the ids in hidden_exercises.json', () {
    expect(hidden, hasLength(33));
    expect({for (final e in catalog.exercises) if (e.hidden) e.id}, hidden.keys.toSet());
  });

  test('search never returns a hidden id (all, by name, by filter)', () async {
    final db = await openWithCatalog();
    addTearDown(db.close);
    final repo = CatalogRepository(db);
    final all = await repo.search('');
    expect(all, hasLength(1324 - 33));
    expect(all.where((e) => hidden.containsKey(e.id)), isEmpty);
    for (final MapEntry(key: id, value: keep) in hidden.entries) {
      final row = (await repo.exercise(id))!;
      final byAr = await repo.search(row.nameAr!);
      expect(byAr.map((e) => e.id), contains(keep), reason: '$id → $keep');
      expect(byAr.map((e) => e.id), isNot(contains(id)));
      final byEn = await repo.search(row.nameEn);
      expect(byEn.map((e) => e.id), isNot(contains(id)));
      final filtered = await repo.search('', target: row.target, equipment: row.equipment);
      expect(filtered.map((e) => e.id), isNot(contains(id)));
    }
  });

  test('hidden ids still resolve by id for existing user data', () async {
    final db = await openWithCatalog();
    addTearDown(db.close);
    final repo = CatalogRepository(db);
    for (final id in hidden.keys) {
      final e = await repo.exercise(id);
      expect(e, isNotNull, reason: id);
      expect(e!.nameAr, isNotEmpty);
    }
    expect((await repo.exercisesByIds(hidden.keys)).length, hidden.length);

    // A workout logged with a now-hidden exercise before this catalog.
    final workouts = WorkoutRepository(db);
    final wid = await workouts.startEmpty('Old');
    await workouts.addExercises(wid, ['0077', '0025']);
    final detail = (await workouts.loadDetail(wid))!;
    for (final e in detail.exercises) {
      await workouts.setCompleted(e.sets.first.id, true, weightKg: 60, reps: 8);
    }
    expect(await workouts.finish(wid), isTrue);

    final after = (await workouts.loadDetail(wid))!;
    expect(after.exercises.map((e) => e.exercise?.id), ['0077', '0025']);
    final history = await HistoryRepository(db).exercises(['0077']);
    expect(history['0077']?.nameEn, isNotEmpty);
  });

  test('schema v1 → v2 adds exercises.hidden and keeps rows', () async {
    final db = AppDatabase(NativeDatabase.memory(setup: (raw) {
      raw.execute('''
        CREATE TABLE exercises (
          id TEXT NOT NULL PRIMARY KEY, name_en TEXT NOT NULL, name_ar TEXT,
          aliases_ar TEXT NOT NULL DEFAULT '[]', body_part TEXT NOT NULL, target TEXT NOT NULL,
          secondary_muscles TEXT NOT NULL DEFAULT '[]', equipment TEXT NOT NULL,
          instructions_en TEXT NOT NULL, instructions_ar TEXT, media_id TEXT NOT NULL,
          search_norm TEXT NOT NULL)''');
      raw.execute('CREATE TABLE catalog_meta (version INTEGER NOT NULL)');
      raw.execute('CREATE TABLE catalog_programs (id TEXT NOT NULL PRIMARY KEY, sort INTEGER NOT NULL, data TEXT NOT NULL)');
      raw.execute("INSERT INTO exercises (id, name_en, body_part, target, equipment, instructions_en, "
          "media_id, search_norm) VALUES ('0077', 'Old', 'upper legs', 'glutes', 'barbell', '[]', 'm', 'old')");
      raw.execute('INSERT INTO catalog_meta VALUES (2)');
      raw.userVersion = 1;
    }));
    addTearDown(db.close);
    final old = await (db.select(db.exercises)..where((e) => e.id.equals('0077'))).getSingle();
    expect(old.hidden, isFalse);
    expect(await CatalogInstaller(db).installIfNewer(catalog), isTrue);
    expect((await CatalogRepository(db).exercise('0077'))!.hidden, isTrue);
  });
}
