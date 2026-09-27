import '../../../core/db/app_database.dart';
import '../../exercises/data/exercise_history.dart';

/// The [ExerciseHistorySource] the whole app uses (exercise detail history,
/// records, library 🏆 badges). bootstrapApp() overrides
/// `exerciseHistorySourceProvider` with it, so the history window can change
/// the rules here without touching the exercises feature.
/// Pre-registered hook (docs/PLAN.md → Parallel windows, round 2): keep the
/// name and signature. Default: the exercises feature's DB implementation.
ExerciseHistorySource createExerciseHistorySource(AppDatabase db) => DbExerciseHistorySource(db);
