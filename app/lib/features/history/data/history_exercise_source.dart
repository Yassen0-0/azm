import '../../../core/db/app_database.dart';
import '../../../core/utils/workout_math.dart';
import '../../exercises/data/exercise_history.dart';

/// The [ExerciseHistorySource] the whole app uses (exercise detail history,
/// records, library 🏆 badges). bootstrapApp() overrides
/// `exerciseHistorySourceProvider` with it, so the history window can change
/// the rules here without touching the exercises feature.
/// Pre-registered hook (docs/PLAN.md → Parallel windows, round 2): keep the
/// name and signature.
ExerciseHistorySource createExerciseHistorySource(AppDatabase db) => HistoryExerciseSource(db);

/// The history feature's source. Same rules as the exercises feature's
/// [DbExerciseHistorySource] (completed sets of finished workouts; warm-ups
/// shown but never records), plus:
/// - sets with no reps are not history (a past workout being edited can hold
///   one for a moment; `HistoryRepository.tidy` removes it on leave);
/// - it only emits when the result changes, so ticking sets in the ACTIVE
///   workout doesn't rebuild every exercise detail and library badge.
/// Edits of past workouts are live: every stream re-reads the DB on change.
class HistoryExerciseSource implements ExerciseHistorySource {
  HistoryExerciseSource(AppDatabase db) : _db = DbExerciseHistorySource(db);

  final DbExerciseHistorySource _db;

  @override
  Stream<ExerciseHistory> watchExercise(String exerciseId) =>
      _db.watchExercise(exerciseId).map(_withoutEmptySets).distinct(sameExerciseHistory);

  @override
  Stream<Map<String, PrBests>> watchRecords() => _db.watchRecords().distinct(sameRecords);

  static ExerciseHistory _withoutEmptySets(ExerciseHistory h) {
    if (h.sessions.every((s) => s.sets.every((x) => x.reps > 0))) return h;
    final sessions = [
      for (final s in h.sessions)
        if (s.sets.any((x) => x.reps > 0))
          ExerciseSession(
            workoutId: s.workoutId,
            workoutName: s.workoutName,
            startedAt: s.startedAt,
            sets: [for (final x in s.sets) if (x.reps > 0) x],
          ),
    ];
    return ExerciseHistory(sessions: sessions, records: h.records);
  }
}

bool _sameBests(PrBests a, PrBests b) =>
    a.heaviestKg == b.heaviestKg && a.best1RmKg == b.best1RmKg && a.bestVolumeKg == b.bestVolumeKg;

/// Value equality of two histories (the models have none).
bool sameExerciseHistory(ExerciseHistory a, ExerciseHistory b) {
  if (!_sameBests(a.records, b.records) || a.sessions.length != b.sessions.length) return false;
  for (var i = 0; i < a.sessions.length; i++) {
    final x = a.sessions[i], y = b.sessions[i];
    if (x.workoutId != y.workoutId ||
        x.workoutName != y.workoutName ||
        x.startedAt != y.startedAt ||
        x.sets.length != y.sets.length) {
      return false;
    }
    for (var j = 0; j < x.sets.length; j++) {
      final s = x.sets[j], t = y.sets[j];
      if (s.type != t.type || s.weightKg != t.weightKg || s.reps != t.reps) return false;
    }
  }
  return true;
}

bool sameRecords(Map<String, PrBests> a, Map<String, PrBests> b) {
  if (a.length != b.length) return false;
  for (final e in a.entries) {
    final o = b[e.key];
    if (o == null || !_sameBests(e.value, o)) return false;
  }
  return true;
}
