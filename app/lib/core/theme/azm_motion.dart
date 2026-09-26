import 'package:flutter/widgets.dart';

/// Motion tokens (design/theme.json → motion). Rules: interface motion < 300 ms,
/// ease-out only, exits shorter than entrances, badges/ticks never overshoot,
/// reduced motion jumps to the end state ([AzmMotion.reduced]).
abstract final class AzmMotion {
  // Easing
  static const Curve standard = Cubic(0.23, 1, 0.32, 1);
  static const Curve press = Cubic(0.34, 1.4, 0.64, 1);
  static const Curve sheet = Cubic(0.22, 1, 0.36, 1);
  static const Curve celebration = Cubic(0.34, 1.56, 0.64, 1);
  static const Curve value = Cubic(0.215, 0.61, 0.355, 1);

  // Durations
  static const Duration nav = Duration(milliseconds: 150);
  static const Duration microOut = Duration(milliseconds: 150);
  static const Duration pressDuration = Duration(milliseconds: 140);
  static const Duration flood = Duration(milliseconds: 120);
  static const Duration micro = Duration(milliseconds: 180);
  static const Duration exit = Duration(milliseconds: 200);
  static const Duration step = Duration(milliseconds: 200);
  static const Duration pop = Duration(milliseconds: 200);
  static const Duration page = Duration(milliseconds: 220);
  static const Duration tick = Duration(milliseconds: 220);
  static const Duration segment = Duration(milliseconds: 250);
  static const Duration enter = Duration(milliseconds: 260);
  static const Duration sheetDuration = Duration(milliseconds: 280);
  static const Duration celebrationDuration = Duration(milliseconds: 500);
  static const Duration valueDuration = Duration(milliseconds: 600);
  static const Duration toast = Duration(milliseconds: 2200);

  // Distances (px)
  static const double pageRise = 8;
  static const double enterRise = 12;
  static const double stepRise = 10;
  static const double microRise = 6;
  static const double toastRise = 12;

  // Stagger
  static const Duration staggerDelay = Duration(milliseconds: 40);
  static const int staggerMaxItems = 6;

  // Press feedback
  static const double pressScale = 0.97;

  // Springs
  static final SpringDescription crisp =
      SpringDescription.withDampingRatio(mass: 1, stiffness: 625, ratio: 1.0);
  static final SpringDescription select =
      SpringDescription.withDampingRatio(mass: 1, stiffness: 361, ratio: 0.70);
  static final SpringDescription settle =
      SpringDescription.withDampingRatio(mass: 1, stiffness: 220, ratio: 0.81);
  static final SpringDescription celebrate =
      SpringDescription.withDampingRatio(mass: 1, stiffness: 390, ratio: 0.45);

  /// True when the OS asks for reduced motion: jump to the end state.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [d], or zero under reduced motion.
  static Duration of(BuildContext context, Duration d) =>
      reduced(context) ? Duration.zero : d;
}
