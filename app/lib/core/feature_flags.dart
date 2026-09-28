import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ready-made programs (SPEC → Routines). Hidden by the owner on 2026-09-28:
/// no Workout-tab entry, onboarding is one screen (unit only), and the
/// programs routes redirect to the Workout tab. All code, catalog data and
/// tests stay; set this to true to bring the feature back.
const bool kProgramsEnabled = false;

/// [kProgramsEnabled], as a provider so tests (and the programs screenshot
/// suite) can exercise the hidden screens without changing the shipped flag.
final programsEnabledProvider = Provider<bool>((ref) => kProgramsEnabled);
