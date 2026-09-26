import 'package:flutter/widgets.dart';

/// Slot rendered by AppShell directly ABOVE the floating tab bar, on every tab.
/// The workout feature fills it with the ActiveWorkoutBar (minimized workout +
/// mini rest timer) and returns nothing when no workout is active.
/// Its height is automatically added to the tabs' bottom padding (Scaffold
/// extendBody), so pages need no changes. Keep the class name/constructor.
class ActiveWorkoutBarSlot extends StatelessWidget {
  const ActiveWorkoutBarSlot({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
