import 'dart:async';

import 'package:azm/app.dart';
import 'package:azm/core/db/app_database.dart';
import 'package:azm/core/router/app_router.dart';
import 'package:azm/core/utils/units.dart';
import 'package:azm/features/settings/data/app_settings.dart';
import 'package:azm/features/settings/data/backup/backup_codec.dart';
import 'package:azm/features/settings/data/backup/backup_files.dart';
import 'package:azm/features/settings/data/license_texts.dart';
import 'package:azm/features/settings/data/training_settings.dart';
import 'package:azm/features/settings/ui/licenses_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'backup_test_helpers.dart';

/// Records shares and serves a scripted pick.
class FakeBackupFiles implements BackupFiles {
  String? pickResult;
  Object? pickError;
  int picks = 0;
  final shared = <({String fileName, String text})>[];

  @override
  Future<String?> pickText() async {
    picks++;
    if (pickError != null) throw pickError!;
    return pickResult;
  }

  @override
  Future<void> share({required String fileName, required String text, Rect? origin}) async =>
      shared.add((fileName: fileName, text: text));
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late FakeBackupFiles files;
  late String backupText; // seedEverything data: 2 routines, 2 workouts, 4 sets, locale ar

  setUpAll(() async => backupText = await validBackupText());

  Future<void> pumpSettings(WidgetTester tester, {LanguagePref lang = LanguagePref.en, Future<void> Function()? seed}) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    db = memoryDb();
    files = FakeBackupFiles();
    container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      settingsStoreProvider.overrideWithValue(DbSettingsStore(db)),
      initialAppSettingsProvider.overrideWithValue(AppSettings(language: lang)),
      backupFilesProvider.overrideWithValue(files),
    ]);
    if (seed != null) await seed();
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const AzmApp()));
    await settle(tester);
    unawaited(container.read(appRouterProvider).push(AppRoutes.settings));
    await settle(tester);
  }

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> tapKey(WidgetTester tester, String key) async {
    final f = find.byKey(ValueKey(key));
    for (final listKey in ['licenses-list', 'settings-list']) {
      final list = find.descendant(of: find.byKey(ValueKey(listKey)), matching: find.byType(Scrollable));
      if (f.evaluate().isEmpty && list.evaluate().isNotEmpty) {
        await tester.scrollUntilVisible(f, 200, scrollable: list.first);
      }
    }
    await tester.ensureVisible(f);
    await tester.pump();
    await tester.tap(f);
    await settle(tester);
  }

  /// A small, different data set already on the phone.
  Future<void> phoneData() async {
    await db.into(db.routines).insert(RoutinesCompanion.insert(name: 'On the phone'));
    await db.writeSetting('onboarding_done', 'true');
  }

  group('training settings', () {
    testWidgets('unit and default rest are written through the writer and shown live', (tester) async {
      await pumpSettings(tester);
      expect(find.text('kg'), findsOneWidget);
      expect(find.text('1:30'), findsOneWidget);

      await tapKey(tester, 'settings-unit');
      expect(find.text('Pounds (lb)'), findsOneWidget);
      await tapKey(tester, 'settings-unit-lb');
      expect(await db.readSetting(TrainingSettingsKeys.unit), '"lb"');
      expect(find.text('lb'), findsOneWidget);

      await tapKey(tester, 'settings-rest');
      expect(find.text('Routines can change it per exercise'), findsOneWidget);
      await tapKey(tester, 'settings-rest-120');
      expect(await db.readSetting(TrainingSettingsKeys.defaultRestSeconds), '120');
      expect(find.text('2:00'), findsOneWidget);
    });

    testWidgets('a value written elsewhere (onboarding) shows immediately', (tester) async {
      await pumpSettings(tester, lang: LanguagePref.ar);
      await container.read(trainingSettingsWriterProvider).setWeightUnit(WeightUnit.lb);
      await container.read(trainingSettingsWriterProvider).setDefaultRestSeconds(75);
      await settle(tester);
      expect(find.text('lb'), findsOneWidget);
      // 75 s is not a menu choice: shown as is and kept selectable in the sheet.
      expect(find.text('1:15'), findsOneWidget);
      await tapKey(tester, 'settings-rest');
      expect(find.byKey(const ValueKey('settings-rest-75')), findsOneWidget);
    });
  });

  group('export', () {
    testWidgets('shares azm-backup-YYYYMMDD-HHmm.json holding every user row', (tester) async {
      await pumpSettings(tester, seed: () => seedEverything(db));
      await tapKey(tester, 'settings-export');
      expect(files.shared, hasLength(1));
      expect(files.shared.single.fileName, matches(RegExp(r'^azm-backup-\d{8}-\d{4}\.json$')));
      final c = decodeBackup(files.shared.single.text);
      expect((c.routines.length, c.workouts.length, c.workoutSets.length), (2, 2, 4));
    });
  });

  group('import', () {
    testWidgets('pick → confirm with counts → everything replaced, language applied', (tester) async {
      await pumpSettings(tester, seed: phoneData);
      files.pickResult = backupText;
      await tapKey(tester, 'settings-import');

      expect(find.text('Restore this backup?'), findsOneWidget);
      expect(find.text('Routines: 2'), findsOneWidget);
      expect(find.text('Workouts: 2'), findsOneWidget);
      expect(find.text('Sets: 4'), findsOneWidget);
      await tapKey(tester, 'settings-import-confirm');

      final routines = await db.select(db.routines).get();
      expect(routines.map((r) => r.name).toSet(), {'دفع', 'Pull'});
      expect(await db.select(db.workoutSets).get(), hasLength(4));
      expect(await db.readSetting('onboarding_done'), 'true');
      // The backup's settings are live: Arabic UI, lb.
      expect(container.read(appSettingsProvider).language, LanguagePref.ar);
      expect(container.read(appSettingsProvider).theme, ThemePref.light);
      expect(find.text('النسخة رجعت ✓'), findsOneWidget);
      expect(find.text('lb'), findsOneWidget);
    });

    testWidgets('cancelling the confirmation changes nothing', (tester) async {
      await pumpSettings(tester, seed: phoneData);
      final before = normalized(await dumpUserData(db));
      files.pickResult = backupText;
      await tapKey(tester, 'settings-import');
      await tapKey(tester, 'settings-import-cancel');
      expect(normalized(await dumpUserData(db)), before);
    });

    testWidgets('cancelling the picker shows nothing', (tester) async {
      await pumpSettings(tester, seed: phoneData);
      await tapKey(tester, 'settings-import');
      expect(files.picks, 1);
      expect(find.byType(AlertDialog), findsNothing);
    });

    final cases = <String, (String, String)>{
      'not JSON': ('%PDF-1.7 not json', "This file isn't a backup (it isn't a JSON file)."),
      'not an Azm backup': ('{"hello": "world"}', "This file isn't an Azm backup."),
      'newer version': (
        '{"format": "azm-backup", "version": 2}',
        'This backup was made by a newer version of Azm. Update the app and try again.',
      ),
      'corrupt': ('{"format": "azm-backup", "version": 1, "routines": 5}', 'This backup is damaged or incomplete.'),
    };
    for (final e in cases.entries) {
      testWidgets('error: ${e.key} → clear message, data untouched', (tester) async {
        await pumpSettings(tester, seed: phoneData);
        final before = normalized(await dumpUserData(db));
        files.pickResult = e.value.$1;
        await tapKey(tester, 'settings-import');
        expect(find.text("Couldn't import this file"), findsOneWidget);
        expect(find.text(e.value.$2), findsOneWidget);
        expect(find.text('Your data is unchanged.'), findsOneWidget);
        await tapKey(tester, 'settings-import-error-ok');
        expect(find.byType(AlertDialog), findsNothing);
        expect(normalized(await dumpUserData(db)), before);
      });
    }

    testWidgets('error: unreadable file (not UTF-8)', (tester) async {
      await pumpSettings(tester, seed: phoneData);
      files.pickError = const BackupException(BackupError.notJson);
      await tapKey(tester, 'settings-import');
      expect(find.text("This file isn't a backup (it isn't a JSON file)."), findsOneWidget);
    });

    testWidgets('refused while a workout is running; the picker never opens', (tester) async {
      await pumpSettings(tester, seed: () async {
        await phoneData();
        await db.into(db.workouts).insert(WorkoutsCompanion.insert(name: 'Now'));
      });
      final before = normalized(await dumpUserData(db));
      files.pickResult = backupText;
      await tapKey(tester, 'settings-import');
      expect(find.text('Finish or discard your current workout first, then import.'), findsOneWidget);
      expect(files.picks, 0);
      expect(normalized(await dumpUserData(db)), before);
    });
  });

  group('licences', () {
    for (final lang in [LanguagePref.ar, LanguagePref.en]) {
      testWidgets('renders every credit (${lang.name})', (tester) async {
        await pumpSettings(tester, lang: lang);
        await tapKey(tester, 'settings-licenses');
        expect(find.byType(LicensesScreen), findsOneWidget);
        String plain(String s) => s.replaceAll(RegExp('[\u2066-\u2069]'), '');
        Finder credit(String s) => find.byWidgetPredicate((w) => w is Text && w.data != null && plain(w.data!) == s);
        expect(credit('Exercise data © 2026 Hasan Emir Yıldırım, MIT License'), findsOneWidget);
        expect(credit('Readex Pro © The Readex Pro Project Authors, SIL OFL 1.1'), findsOneWidget);
        expect(credit('© Gym visual — https://gymvisual.com/'), findsOneWidget);
        expect(find.text(lang == LanguagePref.ar ? 'بيانات التمارين' : 'Exercise data'), findsOneWidget);

        await tapKey(tester, 'settings-licenses-packages');
        expect(find.byType(LicensePage), findsOneWidget);
      });
    }

    test('dataset (MIT) and Readex Pro (OFL) are in the licence registry', () async {
      registerAzmLicenses();
      registerAzmLicenses(); // idempotent
      final entries = await LicenseRegistry.licenses.toList();
      final mine = entries.where((e) => e.packages.contains(kDatasetLicenseName) || e.packages.contains(kFontLicenseName));
      expect(mine, hasLength(2));
      final text = mine.expand((e) => e.paragraphs).map((p) => p.text).join('\n');
      expect(text, contains('Hasan Emir Yıldırım'));
      expect(text, contains('SIL OPEN FONT LICENSE Version 1.1'));
    });
  });
}
