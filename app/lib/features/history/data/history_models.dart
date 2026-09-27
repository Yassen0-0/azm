import 'package:flutter/foundation.dart';

import '../../../core/db/app_database.dart';
import '../../../core/utils/workout_math.dart';
import '../../workout/data/workout_models.dart';

// Everything the History tab, the calendar and Stats show, computed in one
// pass over the completed sets of every FINISHED workout. Pure (no DB, no
// Flutter widgets) and unit-tested. Rules: docs/SPEC.md → History & PRs, Lifted.

/// One exercise of a past workout, as shown on its card.
@immutable
class HistoryWorkoutExercise {
  const HistoryWorkoutExercise({required this.exerciseId, required this.sets, required this.prSets});

  /// Catalog id (the exercise may have left the catalog).
  final String exerciseId;

  /// Completed sets, in logged order.
  final List<WorkoutSet> sets;

  /// Sets of this exercise that were a PR (any type) when logged.
  final int prSets;

  /// Best set (highest e1RM; warm-ups only if there is nothing else).
  WorkoutSet? get best => bestSet(sets);
}

/// A finished workout with its totals.
@immutable
class HistoryWorkout {
  const HistoryWorkout({
    required this.id,
    required this.name,
    required this.startedAt,
    required this.endedAt,
    required this.exercises,
  });

  final String id;
  final String name;

  /// UTC.
  final DateTime startedAt;
  final DateTime? endedAt;

  /// Exercises with at least one completed set, in workout order.
  final List<HistoryWorkoutExercise> exercises;

  Duration get duration => endedAt == null ? Duration.zero : endedAt!.difference(startedAt);

  Iterable<WorkoutSet> get allSets => exercises.expand((e) => e.sets);

  /// Lifted (شِلت) of this workout, kg (warm-ups included).
  double get liftedKg => liftedKgOf(allSets);

  int get setCount => allSets.length;

  /// Number of PR sets (a set holding several PR types counts once, like the
  /// post-workout summary).
  int get prCount => exercises.fold(0, (n, e) => n + e.prSets);
}

/// Per-exercise all-time stats (Stats → personal records).
@immutable
class ExerciseRecord {
  const ExerciseRecord({
    required this.exerciseId,
    required this.bests,
    required this.sessions,
    required this.lastAt,
  });

  final String exerciseId;
  final PrBests bests;

  /// Finished workouts containing this exercise.
  final int sessions;

  /// Start of the most recent of them (UTC).
  final DateTime lastAt;
}

/// All history, newest workout first.
@immutable
class HistoryData {
  const HistoryData({this.workouts = const [], this.records = const [], this.exercises = const {}});

  static const HistoryData empty = HistoryData();

  /// Newest first.
  final List<HistoryWorkout> workouts;

  /// Exercises with at least one PR-eligible set, most recently done first.
  final List<ExerciseRecord> records;

  /// Catalog rows of every exercise in [workouts] (names, thumbnails),
  /// loaded in the SAME emission so cards never show stale names. Missing
  /// ids = exercises that left the catalog.
  final Map<String, Exercise> exercises;

  HistoryData withExercises(Map<String, Exercise> exercises) =>
      HistoryData(workouts: workouts, records: records, exercises: exercises);

  bool get isEmpty => workouts.isEmpty;

  /// All-time Lifted, kg.
  double get liftedKg => workouts.fold(0.0, (t, w) => t + w.liftedKg);

  int get setCount => workouts.fold(0, (t, w) => t + w.setCount);
}

double liftedKgOf(Iterable<WorkoutSet> sets) => liftedKg(sets.map(setStatsOf));

/// Raw input: one finished workout with its exercises (entries in workout
/// order) and their completed sets (in logged order).
typedef RawWorkout = ({
  String id,
  String name,
  DateTime startedAt,
  DateTime? endedAt,
  List<({String exerciseId, List<WorkoutSet> sets})> entries,
});

/// Builds [HistoryData] from every finished workout (any order).
///
/// PRs are evaluated CHRONOLOGICALLY, exactly like the workout screens
/// (`WorkoutRepository.prBests`): a set is a PR if it strictly beats the best
/// of all workouts that STARTED EARLIER. Workouts sharing the same start time
/// don't count against each other. So editing an old workout changes the PRs
/// of every later one.
HistoryData computeHistory(List<RawWorkout> raw) {
  final chrono = [...raw]..sort((a, b) {
      final c = a.startedAt.compareTo(b.startedAt);
      return c != 0 ? c : a.id.compareTo(b.id);
    });

  final bests = <String, PrBests>{};
  final built = <HistoryWorkout>[];
  final sessions = <String, int>{};
  final lastAt = <String, DateTime>{};

  var i = 0;
  while (i < chrono.length) {
    // One group = workouts with the same start time.
    var j = i;
    while (j < chrono.length && chrono[j].startedAt == chrono[i].startedAt) {
      j++;
    }
    final group = chrono.sublist(i, j);
    for (final w in group) {
      final exercises = <HistoryWorkoutExercise>[];
      final seen = <String>{};
      for (final e in w.entries) {
        if (e.sets.isEmpty) continue;
        final prs = detectPrs(e.sets.map(setStatsOf).toList(), bests[e.exerciseId] ?? PrBests.none);
        exercises.add(HistoryWorkoutExercise(exerciseId: e.exerciseId, sets: e.sets, prSets: prs.length));
        if (seen.add(e.exerciseId)) {
          sessions[e.exerciseId] = (sessions[e.exerciseId] ?? 0) + 1;
          lastAt[e.exerciseId] = w.startedAt;
        }
      }
      built.add(HistoryWorkout(
        id: w.id,
        name: w.name,
        startedAt: w.startedAt,
        endedAt: w.endedAt,
        exercises: exercises,
      ));
    }
    // Only now do this group's sets become "earlier" for later workouts.
    for (final w in group) {
      for (final e in w.entries) {
        if (e.sets.isEmpty) continue;
        bests[e.exerciseId] = _merge(bests[e.exerciseId], PrBests.fromSets(e.sets.map(setStatsOf)));
      }
    }
    i = j;
  }

  final records = [
    for (final id in bests.keys)
      if (bests[id]!.heaviestKg > 0)
        ExerciseRecord(exerciseId: id, bests: bests[id]!, sessions: sessions[id] ?? 0, lastAt: lastAt[id]!),
  ]..sort((a, b) => b.lastAt.compareTo(a.lastAt));

  return HistoryData(workouts: built.reversed.toList(), records: records);
}

PrBests _merge(PrBests? a, PrBests b) => a == null
    ? b
    : PrBests(
        heaviestKg: a.heaviestKg > b.heaviestKg ? a.heaviestKg : b.heaviestKg,
        best1RmKg: a.best1RmKg > b.best1RmKg ? a.best1RmKg : b.best1RmKg,
        bestVolumeKg: a.bestVolumeKg > b.bestVolumeKg ? a.bestVolumeKg : b.bestVolumeKg,
      );
