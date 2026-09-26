import 'package:flutter/widgets.dart';

import '../theme/azm_theme.dart';

/// Press feedback for every tappable surface: scale to 0.97 (no ripple).
/// Guarantees a minimum 48×48 hit area. Reduced motion → no scaling.
class AzmPressable extends StatefulWidget {
  const AzmPressable({
    super.key,
    required this.onTap,
    required this.child,
    this.semanticLabel,
    this.selected,
  });

  final VoidCallback? onTap;
  final Widget child;
  final String? semanticLabel;
  final bool? selected;

  @override
  State<AzmPressable> createState() => _AzmPressableState();
}

class _AzmPressableState extends State<AzmPressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null || _down == v) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AzmMotion.reduced(context);
    return Semantics(
      button: true,
      enabled: widget.onTap != null,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AzmSize.minTouchTarget,
            minHeight: AzmSize.minTouchTarget,
          ),
          child: AnimatedScale(
            scale: _down && !reduced ? AzmMotion.pressScale : 1,
            duration: AzmMotion.pressDuration,
            curve: AzmMotion.press,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
