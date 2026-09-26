// =============================================================================
// DEBUG ONLY — REMOVE AT MERGE (listed in docs/PLAN.md → Workout → merge notes)
// =============================================================================
// The exercise picker (window A, `AppRoutes.exercisePicker`) returns null until
// feature/exercises is merged. This lets a debug build add exercises to the
// active workout anyway. It is only reachable behind `kDebugMode` (the button
// in active_workout_screen.dart), so release builds never show it.
import '../data/workout_repository.dart';

/// Catalog ids with Arabic names: bench press, squat, one-arm dumbbell row.
const List<String> debugSeedExerciseIds = ['0025', '0043', '0292'];

Future<void> debugSeedExercises(WorkoutRepository repo, String workoutId) =>
    repo.addExercises(workoutId, debugSeedExerciseIds);
