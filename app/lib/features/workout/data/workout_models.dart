import 'package:flutter/foundation.dart';

import '../../../core/db/app_database.dart';
import '../../../core/utils/units.dart';
import '../../../core/utils/workout_math.dart';

/// Default rest when neither the routine exercise nor settings override it.
const int kDefaultRestSeconds = 90;

/// Settings keys read/written by the workout feature (values JSON-encoded,
/// docs/DATA.md). `unit` and `default_rest_seconds` are written by settings.
abstract final class WorkoutSettingsKeys {
  static const unit = 'unit';
  static const defaultRestSeconds = 'default_rest_seconds';
  static const restEndsAt = 'active_rest_ends_at';
  static const restNotificationId = 'active_rest_notification_id';

  /// Total length of the running rest (for the progress bar).
  static const restTotalSeconds = 'active_rest_total_seconds';

  /// True once the notification permission prompt has been shown.
  static const notificationsAsked = 'workout_notifications_asked';
}

SetStats setStatsOf(WorkoutSet s) => SetStats(
      weightKg: s.weightKg,
      reps: s.reps,
      completed: s.completedAt != null,
      type: s.type,
    );

/// One exercise of a workout with everything its section needs.
@immutable
class WorkoutExerciseDetail {
  const WorkoutExerciseDetail({
    required this.entry,
    required this.exercise,
    required this.sets,
    required this.previous,
    required this.prs,
    required this.restSeconds,
  });

  final WorkoutExercise entry;

  /// Catalog row, or null when the exercise left the catalog ("Unknown exercise").
  final Exercise? exercise;

  /// Sets in display order.
  final List<WorkoutSet> sets;

  /// Sets of this exercise in the last finished workout (index-aligned "previous").
  final List<WorkoutSet> previous;

  /// Set index (in [sets]) → PR types it holds versus all earlier workouts.
  final Map<int, Set<PrType>> prs;

  final int restSeconds;

  WorkoutSet? previousFor(int index) => index < previous.length ? previous[index] : null;
}

/// A workout with its exercises and sets: the single source for the active
/// workout screen and the summary. Always rebuilt from the DB.
@immutable
class WorkoutDetail {
  const WorkoutDetail({required this.workout, required this.exercises, required this.unit});

  final Workout workout;
  final List<WorkoutExerciseDetail> exercises;
  final WeightUnit unit;

  Iterable<WorkoutSet> get allSets => exercises.expand((e) => e.sets);

  /// Lifted (شِلت) of the whole workout, kg.
  double get liftedTotalKg => liftedKg(allSets.map(setStatsOf));

  int get completedSets => allSets.where((s) => s.completedAt != null).length;

  int get prCount => exercises.fold(0, (n, e) => n + e.prs.values.fold(0, (m, t) => m + t.length));
}

/// Display number of each set row: normal sets count 1, 2, 3…; other types
/// get null (they show their letter instead).
List<int?> normalSetNumbers(List<WorkoutSet> sets) {
  var n = 0;
  return [for (final s in sets) s.type == SetType.normal ? ++n : null];
}

/// Best set of an exercise for the summary: highest estimated 1RM among
/// completed working sets (falls back to warm-ups if there are only warm-ups).
WorkoutSet? bestSet(List<WorkoutSet> sets) {
  WorkoutSet? best;
  var bestScore = 0.0;
  for (final pass in [false, true]) {
    for (final s in sets) {
      if (s.completedAt == null || s.reps <= 0) continue;
      if (!pass && s.type == SetType.warmup) continue;
      final score = epley1Rm(s.weightKg, s.reps) + s.reps / 1000; // reps break ties (bodyweight)
      if (best == null || score > bestScore) {
        best = s;
        bestScore = score;
      }
    }
    if (best != null) return best;
  }
  return null;
}
