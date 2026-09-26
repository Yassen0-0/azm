import 'package:azm/core/db/app_database.dart';
import 'package:azm/core/utils/units.dart';
import 'package:azm/features/settings/data/training_settings.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parsers fall back to kg / 90 s on missing or invalid values', () {
    expect(parseWeightUnit(null), WeightUnit.kg);
    expect(parseWeightUnit('"lb"'), WeightUnit.lb);
    expect(parseWeightUnit('"stone"'), WeightUnit.kg);
    expect(parseDefaultRestSeconds(null), kDefaultRestSeconds);
    expect(parseDefaultRestSeconds('120'), 120);
    expect(parseDefaultRestSeconds('0'), kDefaultRestSeconds);
    expect(parseDefaultRestSeconds('"x"'), kDefaultRestSeconds);
  });

  test('providers re-emit when the settings writer changes a value', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(overrides: [appDatabaseProvider.overrideWithValue(db)]);
    addTearDown(() async {
      container.dispose();
      await db.close();
    });

    final units = <WeightUnit>[];
    final rests = <int>[];
    container.listen(weightUnitProvider, (_, next) => next.whenData(units.add), fireImmediately: true);
    container.listen(defaultRestSecondsProvider, (_, next) => next.whenData(rests.add), fireImmediately: true);
    await container.read(weightUnitProvider.future);
    await container.read(defaultRestSecondsProvider.future);

    final writer = container.read(trainingSettingsWriterProvider);
    await writer.setWeightUnit(WeightUnit.lb);
    await writer.setDefaultRestSeconds(150);
    await pumpEventQueue();

    expect(units, [WeightUnit.kg, WeightUnit.lb]);
    expect(rests, [kDefaultRestSeconds, 150]);
    expect(await db.readSetting(TrainingSettingsKeys.unit), '"lb"');
    expect(() => writer.setDefaultRestSeconds(0), throwsArgumentError);
  });
}
