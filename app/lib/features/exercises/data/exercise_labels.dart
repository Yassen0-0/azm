import '../../../core/l10n/l10n.dart';
import 'exercise_filters.dart';

/// Localized labels for the dataset keys stored in the catalog (`target`,
/// `secondary_muscles`, `equipment`, `body_part`; docs/DATA.md). The keys stay
/// English in the DB; the UI always goes through here.
///
/// The key lists mirror the bundled catalog. A key a future catalog adds
/// falls back to the raw key (capitalized) until it gets an ARB entry.
abstract final class ExerciseLabels {
  /// Target muscles in real-world usage order (owner, 2026-09-26): the
  /// MuscleChips shown first.
  static const List<String> targets = [
    'pectorals',
    'lats',
    'upper back',
    'delts',
    'biceps',
    'triceps',
    'quads',
    'hamstrings',
    'glutes',
    'calves',
    'abs',
    'forearms',
    'traps',
    'cardiovascular system',
  ];

  /// Less common targets, behind the final "More" chip.
  static const List<String> moreTargets = ['spine', 'adductors', 'abductors', 'serratus anterior', 'levator scapulae'];

  /// Equipment, most exercises first (the equipment sheet order).
  static const List<String> equipment = [
    'body weight',
    'dumbbell',
    'cable',
    'barbell',
    'leverage machine',
    'band',
    'smith machine',
    'kettlebell',
    'weighted',
    'stability ball',
    'ez barbell',
    'sled machine',
    'assisted',
    'medicine ball',
    'rope',
    'roller',
    'resistance band',
    'bosu ball',
    'wheel roller',
    'olympic barbell',
    'upper body ergometer',
    'trap bar',
    'tire',
    'stepmill machine',
    'stationary bike',
    'skierg machine',
    'hammer',
    'elliptical machine',
  ];

  static String muscle(AppLocalizations l, String key) => switch (key) {
    'abs' => l.exercisesMuscleAbs,
    'pectorals' => l.exercisesMusclePectorals,
    'biceps' => l.exercisesMuscleBiceps,
    'glutes' => l.exercisesMuscleGlutes,
    'delts' => l.exercisesMuscleDelts,
    'triceps' => l.exercisesMuscleTriceps,
    'upper back' => l.exercisesMuscleUpperBack,
    'lats' => l.exercisesMuscleLats,
    'calves' => l.exercisesMuscleCalves,
    'quads' => l.exercisesMuscleQuads,
    'forearms' => l.exercisesMuscleForearms,
    'cardiovascular system' => l.exercisesMuscleCardiovascularSystem,
    'hamstrings' => l.exercisesMuscleHamstrings,
    'spine' => l.exercisesMuscleSpine,
    'traps' => l.exercisesMuscleTraps,
    'adductors' => l.exercisesMuscleAdductors,
    'serratus anterior' => l.exercisesMuscleSerratusAnterior,
    'abductors' => l.exercisesMuscleAbductors,
    'levator scapulae' => l.exercisesMuscleLevatorScapulae,
    'abdominals' => l.exercisesMuscleAbdominals,
    'ankle stabilizers' => l.exercisesMuscleAnkleStabilizers,
    'ankles' => l.exercisesMuscleAnkles,
    'back' => l.exercisesMuscleBack,
    'brachialis' => l.exercisesMuscleBrachialis,
    'chest' => l.exercisesMuscleChest,
    'core' => l.exercisesMuscleCore,
    'deltoids' => l.exercisesMuscleDeltoids,
    'feet' => l.exercisesMuscleFeet,
    'grip muscles' => l.exercisesMuscleGripMuscles,
    'groin' => l.exercisesMuscleGroin,
    'hands' => l.exercisesMuscleHands,
    'hip flexors' => l.exercisesMuscleHipFlexors,
    'inner thighs' => l.exercisesMuscleInnerThighs,
    'latissimus dorsi' => l.exercisesMuscleLatissimusDorsi,
    'lower abs' => l.exercisesMuscleLowerAbs,
    'lower back' => l.exercisesMuscleLowerBack,
    'obliques' => l.exercisesMuscleObliques,
    'quadriceps' => l.exercisesMuscleQuadriceps,
    'rear deltoids' => l.exercisesMuscleRearDeltoids,
    'rhomboids' => l.exercisesMuscleRhomboids,
    'rotator cuff' => l.exercisesMuscleRotatorCuff,
    'shins' => l.exercisesMuscleShins,
    'shoulders' => l.exercisesMuscleShoulders,
    'soleus' => l.exercisesMuscleSoleus,
    'sternocleidomastoid' => l.exercisesMuscleSternocleidomastoid,
    'trapezius' => l.exercisesMuscleTrapezius,
    'upper chest' => l.exercisesMuscleUpperChest,
    'wrist extensors' => l.exercisesMuscleWristExtensors,
    'wrist flexors' => l.exercisesMuscleWristFlexors,
    'wrists' => l.exercisesMuscleWrists,
    _ => _fallback(key),
  };

  static String equipmentLabel(AppLocalizations l, String key) => switch (key) {
    'body weight' => l.exercisesEquipmentBodyWeight,
    'dumbbell' => l.exercisesEquipmentDumbbell,
    'cable' => l.exercisesEquipmentCable,
    'barbell' => l.exercisesEquipmentBarbell,
    'leverage machine' => l.exercisesEquipmentLeverageMachine,
    'band' => l.exercisesEquipmentBand,
    'smith machine' => l.exercisesEquipmentSmithMachine,
    'kettlebell' => l.exercisesEquipmentKettlebell,
    'weighted' => l.exercisesEquipmentWeighted,
    'stability ball' => l.exercisesEquipmentStabilityBall,
    'ez barbell' => l.exercisesEquipmentEzBarbell,
    'sled machine' => l.exercisesEquipmentSledMachine,
    'assisted' => l.exercisesEquipmentAssisted,
    'medicine ball' => l.exercisesEquipmentMedicineBall,
    'rope' => l.exercisesEquipmentRope,
    'roller' => l.exercisesEquipmentRoller,
    'resistance band' => l.exercisesEquipmentResistanceBand,
    'bosu ball' => l.exercisesEquipmentBosuBall,
    'wheel roller' => l.exercisesEquipmentWheelRoller,
    'olympic barbell' => l.exercisesEquipmentOlympicBarbell,
    'upper body ergometer' => l.exercisesEquipmentUpperBodyErgometer,
    'trap bar' => l.exercisesEquipmentTrapBar,
    'tire' => l.exercisesEquipmentTire,
    'stepmill machine' => l.exercisesEquipmentStepmillMachine,
    'stationary bike' => l.exercisesEquipmentStationaryBike,
    'skierg machine' => l.exercisesEquipmentSkiergMachine,
    'hammer' => l.exercisesEquipmentHammer,
    'elliptical machine' => l.exercisesEquipmentEllipticalMachine,
    _ => _fallback(key),
  };

  static String bodyPart(AppLocalizations l, String key) => switch (key) {
    'upper arms' => l.exercisesBodyPartUpperArms,
    'upper legs' => l.exercisesBodyPartUpperLegs,
    'back' => l.exercisesBodyPartBack,
    'waist' => l.exercisesBodyPartWaist,
    'chest' => l.exercisesBodyPartChest,
    'shoulders' => l.exercisesBodyPartShoulders,
    'lower legs' => l.exercisesBodyPartLowerLegs,
    'lower arms' => l.exercisesBodyPartLowerArms,
    'cardio' => l.exercisesBodyPartCardio,
    'neck' => l.exercisesBodyPartNeck,
    _ => _fallback(key),
  };

  // ---- Filter bar (Place / Muscle Group / Equipment) ----------------------

  static String filterKind(AppLocalizations l, FilterKind k) => switch (k) {
    FilterKind.place => l.exercisesFilterPlace,
    FilterKind.muscle => l.exercisesFilterMuscle,
    FilterKind.equipment => l.exercisesFilterEquipment,
  };

  /// Visible chip label (short; [filterKind] is the sheet title + semantics).
  static String filterChip(AppLocalizations l, FilterKind k) =>
      k == FilterKind.muscle ? l.exercisesFilterMuscleChip : filterKind(l, k);

  /// Name of one filter card (ids from data/*_mapping.json).
  static String filterOption(AppLocalizations l, FilterKind k, String id) => switch (k) {
    FilterKind.place => switch (id) {
      'gym' => l.exercisesPlaceGym,
      'home' => l.exercisesPlaceHome,
      'bands' => l.exercisesPlaceBands,
      _ => _fallbackId(id),
    },
    FilterKind.muscle => switch (id) {
      'abs' => l.exercisesGroupAbs,
      'biceps' => l.exercisesGroupBiceps,
      'chest' => l.exercisesGroupChest,
      'forearms' => l.exercisesGroupForearms,
      'lats' => l.exercisesGroupLats,
      'lower_back' => l.exercisesGroupLowerBack,
      'neck' => l.exercisesGroupNeck,
      'shoulders' => l.exercisesGroupShoulders,
      'traps' => l.exercisesGroupTraps,
      'triceps' => l.exercisesGroupTriceps,
      'upper_back' => l.exercisesGroupUpperBack,
      'abductors' => l.exercisesGroupAbductors,
      'adductors' => l.exercisesGroupAdductors,
      'calves' => l.exercisesGroupCalves,
      'glutes' => l.exercisesGroupGlutes,
      'hamstrings' => l.exercisesGroupHamstrings,
      'quads' => l.exercisesGroupQuads,
      'cardio' => l.exercisesGroupCardio,
      'full_body' => l.exercisesGroupFullBody,
      'other' => l.exercisesGroupOther,
      _ => _fallbackId(id),
    },
    FilterKind.equipment => switch (id) {
      'none' => l.exercisesEquipGroupNone,
      'barbell' => l.exercisesEquipGroupBarbell,
      'dumbbell' => l.exercisesEquipGroupDumbbell,
      'kettlebell' => l.exercisesEquipGroupKettlebell,
      'machine' => l.exercisesEquipGroupMachine,
      'cable' => l.exercisesEquipGroupCable,
      'plate' => l.exercisesEquipGroupPlate,
      'resistance_band' => l.exercisesEquipGroupResistanceBand,
      'suspension_band' => l.exercisesEquipGroupSuspensionBand,
      'other' => l.exercisesEquipGroupOther,
      _ => _fallbackId(id),
    },
  };

  /// Section title of the Muscle Group sheet.
  static String muscleSection(AppLocalizations l, String id) => switch (id) {
    'upper' => l.exercisesMuscleSectionUpper,
    'lower' => l.exercisesMuscleSectionLower,
    'other' => l.exercisesMuscleSectionOther,
    _ => _fallbackId(id),
  };

  /// [FilterIcon] id of a card.
  static String filterIconId(FilterKind k, String id) => '${k.name}_$id';

  static String _fallbackId(String id) => _fallback(id.replaceAll('_', ' '));

  static String _fallback(String key) => key.isEmpty ? key : key[0].toUpperCase() + key.substring(1);
}
