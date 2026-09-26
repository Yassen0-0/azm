import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/azm_theme.dart';

/// Size variants (DESIGN.md → LiftedCounter).
enum LiftedCounterSize {
  /// Workout header (`rowNumber`).
  header,

  /// Post-workout summary (`summaryNumber`).
  summary,

  /// History header (`liftedNumber`).
  history,
}

/// Lifted (شِلت) number + unit + optional comparison line. Counts up to each
/// new [value] with motion `value` (600 ms); reduced motion jumps.
/// [value] is already in the display unit.
class LiftedCounter extends StatelessWidget {
  const LiftedCounter({
    super.key,
    required this.value,
    required this.unit,
    this.size = LiftedCounterSize.header,
    this.comparison,
    this.fromZero = false,
  });

  final double value;
  final String unit;
  final LiftedCounterSize size;
  final String? comparison;

  /// Count up from 0 on first build (summary); otherwise start at [value].
  final bool fromZero;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final numberStyle = switch (size) {
      LiftedCounterSize.header => AzmType.rowNumber,
      LiftedCounterSize.summary => AzmType.summaryNumber,
      LiftedCounterSize.history => AzmType.liftedNumber,
    };
    final unitStyle = size == LiftedCounterSize.header ? AzmType.small : AzmType.rowTitle;
    final align = size == LiftedCounterSize.header ? CrossAxisAlignment.center : CrossAxisAlignment.start;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: align,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: fromZero ? 0 : value, end: value),
          duration: AzmMotion.of(context, AzmMotion.valueDuration),
          curve: AzmMotion.value,
          builder: (context, v, _) => Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(AzmNumbers.integer(v), style: numberStyle.copyWith(color: c.textPrimary)),
              const SizedBox(width: AzmSpace.xxs),
              Text(unit, style: unitStyle.copyWith(color: c.textSecondary)),
            ],
          ),
        ),
        if (comparison != null) ...[
          const SizedBox(height: AzmSpace.xs),
          Text(comparison!, style: AzmType.body.copyWith(color: c.textSecondary)),
        ],
      ],
    );
  }
}
