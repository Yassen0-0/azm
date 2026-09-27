import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/catalog_repository.dart';

/// Bilingual text from programs.json (`{"ar": …, "en": …}`).
@immutable
class LocalizedText {
  const LocalizedText({required this.ar, required this.en});

  factory LocalizedText.fromJson(Object? json) {
    final m = (json as Map?)?.cast<String, dynamic>() ?? const {};
    final en = (m['en'] as String?) ?? '';
    return LocalizedText(ar: (m['ar'] as String?) ?? en, en: en);
  }

  final String ar;
  final String en;

  /// Arabic for `ar`, English for everything else.
  String of(String languageCode) => languageCode == 'ar' && ar.isNotEmpty ? ar : en;
}

enum ProgramLevel { beginner, intermediate }

/// One exercise of a program day: `sets` × `repsMin`–`repsMax`.
@immutable
class ProgramExercise {
  const ProgramExercise({
    required this.exerciseId,
    required this.sets,
    required this.repsMin,
    required this.repsMax,
    this.restSeconds,
  });

  factory ProgramExercise.fromJson(Map<String, dynamic> j) {
    final reps = (j['reps'] as List).cast<num>();
    return ProgramExercise(
      exerciseId: j['exercise_id'] as String,
      sets: (j['sets'] as num).toInt(),
      repsMin: reps.first.toInt(),
      repsMax: reps.last.toInt(),
      restSeconds: (j['rest_seconds'] as num?)?.toInt(),
    );
  }

  final String exerciseId;
  final int sets;
  final int repsMin;
  final int repsMax;
  final int? restSeconds;
}

/// One day of a program; copied as one routine.
@immutable
class ProgramDay {
  const ProgramDay({required this.id, required this.name, required this.exercises});

  factory ProgramDay.fromJson(Map<String, dynamic> j) => ProgramDay(
        id: j['id'] as String,
        name: LocalizedText.fromJson(j['name']),
        exercises: [
          for (final e in (j['exercises'] as List).cast<Map<String, dynamic>>()) ProgramExercise.fromJson(e),
        ],
      );

  final String id;
  final LocalizedText name;
  final List<ProgramExercise> exercises;
}

/// A ready-made program (data/programs/programs.json, docs/DATA.md).
@immutable
class ReadyProgram {
  const ReadyProgram({
    required this.id,
    required this.name,
    required this.description,
    required this.daysPerWeek,
    required this.level,
    required this.days,
  });

  factory ReadyProgram.fromJson(Map<String, dynamic> j) => ReadyProgram(
        id: j['id'] as String,
        name: LocalizedText.fromJson(j['name']),
        description: LocalizedText.fromJson(j['description']),
        daysPerWeek: (j['days_per_week'] as num?)?.toInt() ?? 0,
        level: j['level'] == 'beginner' ? ProgramLevel.beginner : ProgramLevel.intermediate,
        days: [for (final r in (j['routines'] as List).cast<Map<String, dynamic>>()) ProgramDay.fromJson(r)],
      );

  final String id;
  final LocalizedText name;
  final LocalizedText description;
  final int daysPerWeek;
  final ProgramLevel level;
  final List<ProgramDay> days;

  Set<String> get exerciseIds => {for (final d in days) for (final e in d.exercises) e.exerciseId};
}

/// All ready programs, in catalog order.
final readyProgramsProvider = FutureProvider<List<ReadyProgram>>(
  (ref) async => [for (final j in await ref.watch(catalogRepositoryProvider).programs()) ReadyProgram.fromJson(j)],
  retry: (_, _) => null,
);

/// One program by id (null if the catalog doesn't have it).
final readyProgramProvider = FutureProvider.family<ReadyProgram?, String>(
  (ref, id) async {
    for (final p in await ref.watch(readyProgramsProvider.future)) {
      if (p.id == id) return p;
    }
    return null;
  },
  retry: (_, _) => null,
);
