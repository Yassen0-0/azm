import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/utils/workout_math.dart';

// "Your history with this exercise" for the exercise detail screen and the
// PR badges in the library. The UI only talks to [ExerciseHistorySource], so
// the history feature can later swap in its own implementation (edited past
// workouts, recomputed PRs, …) by overriding [exerciseHistorySourceProvider]
// without touching the exercises UI.
//
// Rules (docs/SPEC.md → History & PRs): only COMPLETED sets of FINISHED
// workouts count. Warm-ups are shown in the history and count toward volume,
// but never toward records.

/// One completed set of a finished workout.
@immutable
class HistorySet {
  const HistorySet({required this.type, required this.weightKg, required this.reps});

  final SetType type;
  final double weightKg;
  final int reps;

  SetStats get stats => SetStats(weightKg: weightKg, reps: reps, completed: true, type: type);
}

/// All completed sets of one exercise in one finished workout.
@immutable
class ExerciseSession {
  const ExerciseSession({
    required this.workoutId,
    required this.workoutName,
    required this.startedAt,
    required this.sets,
  });

  final String workoutId;
  final String workoutName;

  /// UTC.
  final DateTime startedAt;

  /// In logged order.
  final List<HistorySet> sets;

  /// Bests of this session (warm-ups excluded).
  PrBests get bests => PrBests.fromSets(sets.map((s) => s.stats));

  /// Σ weight × reps of the session, warm-ups included (like Lifted).
  double get volumeKg => liftedKg(sets.map((s) => s.stats));
}

/// Everything the detail screen shows about the user's history.
@immutable
class ExerciseHistory {
  const ExerciseHistory({this.sessions = const [], this.records = PrBests.none});

  static const ExerciseHistory empty = ExerciseHistory();

  /// Newest first.
  final List<ExerciseSession> sessions;

  /// All-time records over [sessions].
  final PrBests records;

  bool get isEmpty => sessions.isEmpty;
}

/// Source of per-exercise history. Implementations must emit again whenever
/// the underlying data changes (a workout is finished or edited).
abstract interface class ExerciseHistorySource {
  /// History of one exercise.
  Stream<ExerciseHistory> watchExercise(String exerciseId);

  /// All-time records of every exercise that has at least one eligible set
  /// (exercise id → bests). Exercises without records are absent.
  Stream<Map<String, PrBests>> watchRecords();
}

/// Default implementation straight on the workout tables.
class DbExerciseHistorySource implements ExerciseHistorySource {
  DbExerciseHistorySource(this.db);

  final AppDatabase db;

  @override
  Stream<ExerciseHistory> watchExercise(String exerciseId) {
    final q =
        db.select(db.workoutSets).join([
            innerJoin(db.workoutExercises, db.workoutExercises.id.equalsExp(db.workoutSets.workoutExerciseId)),
            innerJoin(db.workouts, db.workouts.id.equalsExp(db.workoutExercises.workoutId)),
          ])
          ..where(
            db.workoutExercises.exerciseId.equals(exerciseId) &
                db.workouts.status.equalsValue(WorkoutStatus.finished) &
                db.workoutSets.completedAt.isNotNull(),
          )
          ..orderBy([
            OrderingTerm.desc(db.workouts.startedAt),
            OrderingTerm.asc(db.workouts.id),
            OrderingTerm.asc(db.workoutExercises.sort),
            OrderingTerm.asc(db.workoutSets.sort),
          ]);

    return q.watch().map((rows) {
      final sessions = <ExerciseSession>[];
      String? currentId;
      for (final row in rows) {
        final w = row.readTable(db.workouts);
        final s = row.readTable(db.workoutSets);
        if (w.id != currentId) {
          currentId = w.id;
          sessions.add(ExerciseSession(workoutId: w.id, workoutName: w.name, startedAt: w.startedAt, sets: []));
        }
        sessions.last.sets.add(HistorySet(type: s.type, weightKg: s.weightKg, reps: s.reps));
      }
      final records = PrBests.fromSets([for (final x in sessions) ...x.sets.map((s) => s.stats)]);
      return ExerciseHistory(sessions: sessions, records: records);
    });
  }

  @override
  Stream<Map<String, PrBests>> watchRecords() {
    // Same eligibility as PrBests.fromSets: completed, not warm-up, w > 0, reps > 0.
    return db
        .customSelect(
          '''
      SELECT we.exercise_id AS id,
             MAX(ws.weight_kg) AS heaviest,
             MAX(CASE WHEN ws.reps = 1 THEN ws.weight_kg
                      ELSE ws.weight_kg * (1 + ws.reps / 30.0) END) AS e1rm,
             MAX(ws.weight_kg * ws.reps) AS volume
      FROM workout_sets ws
      JOIN workout_exercises we ON we.id = ws.workout_exercise_id
      JOIN workouts w ON w.id = we.workout_id
      WHERE w.status = 'finished' AND ws.completed_at IS NOT NULL
        AND ws.type <> 'warmup' AND ws.weight_kg > 0 AND ws.reps > 0
      GROUP BY we.exercise_id
      ''',
          readsFrom: {db.workouts, db.workoutExercises, db.workoutSets},
        )
        .watch()
        .map(
          (rows) => {
            for (final r in rows)
              r.read<String>('id'): PrBests(
                heaviestKg: r.read<double>('heaviest'),
                best1RmKg: r.read<double>('e1rm'),
                bestVolumeKg: r.read<double>('volume'),
              ),
          },
        );
  }
}

/// Override this (e.g. from the history feature) to change where history
/// comes from.
final exerciseHistorySourceProvider = Provider<ExerciseHistorySource>(
  (ref) => DbExerciseHistorySource(ref.watch(appDatabaseProvider)),
);

final exerciseHistoryProvider = StreamProvider.autoDispose.family<ExerciseHistory, String>(
  (ref, id) => ref.watch(exerciseHistorySourceProvider).watchExercise(id),
  retry: (_, _) => null,
);

final exerciseRecordsProvider = StreamProvider.autoDispose<Map<String, PrBests>>(
  (ref) => ref.watch(exerciseHistorySourceProvider).watchRecords(),
  retry: (_, _) => null,
);
