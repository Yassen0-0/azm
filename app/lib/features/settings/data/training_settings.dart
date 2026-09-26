import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/utils/units.dart';

/// Training settings shared by every feature: weight unit and default rest.
/// The settings feature is the only WRITER; other features only watch the
/// providers below (docs/DATA.md → Settings keys).
abstract final class TrainingSettingsKeys {
  static const unit = 'unit';
  static const defaultRestSeconds = 'default_rest_seconds';
}

/// Default rest when neither the routine exercise nor settings override it.
const int kDefaultRestSeconds = 90;

/// `unit` JSON value → unit (missing / unknown → kg).
WeightUnit parseWeightUnit(String? json) =>
    json != null && jsonDecode(json) == 'lb' ? WeightUnit.lb : WeightUnit.kg;

/// `default_rest_seconds` JSON value → seconds (missing / invalid → 90).
int parseDefaultRestSeconds(String? json) {
  final v = json == null ? null : jsonDecode(json);
  return v is int && v > 0 ? v : kDefaultRestSeconds;
}

Stream<String?> _watchSetting(AppDatabase db, String key) =>
    (db.select(db.settings)..where((s) => s.key.equals(key)))
        .watchSingleOrNull()
        .map((row) => row?.value);

/// The chosen weight unit; re-emits whenever the setting is written.
final weightUnitProvider = StreamProvider<WeightUnit>(
  (ref) => _watchSetting(ref.watch(appDatabaseProvider), TrainingSettingsKeys.unit).map(parseWeightUnit),
  retry: (_, _) => null,
);

/// The global default rest in seconds; re-emits whenever the setting is written.
final defaultRestSecondsProvider = StreamProvider<int>(
  (ref) => _watchSetting(ref.watch(appDatabaseProvider), TrainingSettingsKeys.defaultRestSeconds)
      .map(parseDefaultRestSeconds),
  retry: (_, _) => null,
);

/// Writes the training settings (used by the settings screen / onboarding).
class TrainingSettingsWriter {
  const TrainingSettingsWriter(this.db);

  final AppDatabase db;

  Future<void> setWeightUnit(WeightUnit unit) =>
      db.writeSetting(TrainingSettingsKeys.unit, jsonEncode(unit.name));

  Future<void> setDefaultRestSeconds(int seconds) {
    if (seconds <= 0) throw ArgumentError.value(seconds, 'seconds', 'must be > 0');
    return db.writeSetting(TrainingSettingsKeys.defaultRestSeconds, jsonEncode(seconds));
  }
}

final trainingSettingsWriterProvider =
    Provider<TrainingSettingsWriter>((ref) => TrainingSettingsWriter(ref.watch(appDatabaseProvider)));
