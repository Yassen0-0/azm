import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/azm_theme.dart';

/// Workouts-per-week bar chart (AzmSize.chartHeight). Oldest week at the
/// START edge, so time flows in reading direction and the chart mirrors in
/// RTL. Bars in `accent` (the current week) / `accentSoft`; empty weeks show
/// a `track` stub; grid lines in `divider`. No fills, no glows.
class HistoryWeekChart extends StatelessWidget {
  const HistoryWeekChart({super.key, required this.counts});

  /// Oldest first; the last one is the current week.
  final List<int> counts;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final top = math.max(1, counts.fold(0, math.max));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SizedBox(
            height: AzmSize.chartHeight,
            child: CustomPaint(
              painter: _BarsPainter(
                counts: counts,
                top: top,
                rtl: Directionality.of(context) == TextDirection.rtl, // directionality: ignore (painter works in physical space)
                bar: c.accentSoft,
                current: c.accent,
                empty: c.track,
                grid: c.divider,
              ),
            ),
          ),
        ),
        const SizedBox(width: AzmSpace.xs),
        // Scale: max at the top, 0 at the bottom (end edge).
        SizedBox(
          height: AzmSize.chartHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AzmNumbers.integer(top), style: AzmType.chartLabel.copyWith(color: c.textSecondary)),
              Text(AzmNumbers.integer(0), style: AzmType.chartLabel.copyWith(color: c.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.counts,
    required this.top,
    required this.rtl,
    required this.bar,
    required this.current,
    required this.empty,
    required this.grid,
  });

  final List<int> counts;
  final int top;
  final bool rtl;
  final Color bar;
  final Color current;
  final Color empty;
  final Color grid;

  static const double _gap = AzmSpace.xs;
  static const double _radius = AzmSize.chartDot;
  static const double _stub = AzmSize.chartStroke;

  @override
  void paint(Canvas canvas, Size size) {
    if (counts.isEmpty) return;
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = AzmGlass.borderWidth;
    for (final y in [0.0, size.height / 2, size.height]) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final n = counts.length;
    final w = (size.width - _gap * (n - 1)) / n;
    for (var i = 0; i < n; i++) {
      final slot = rtl ? n - 1 - i : i; // oldest at the start edge
      final x = slot * (w + _gap);
      final isCurrent = i == n - 1;
      if (counts[i] == 0) {
        canvas.drawRect(Rect.fromLTWH(x, size.height - _stub, w, _stub), Paint()..color = empty);
        continue;
      }
      final h = size.height * counts[i] / top;
      // Rounded top, square base: a rounded bar with its lower corners
      // squared off by a plain rect (painter works in physical space).
      final paint = Paint()..color = isCurrent ? current : bar;
      final rect = Rect.fromLTWH(x, size.height - h, w, h);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(_radius)), paint);
      if (h > _radius) {
        canvas.drawRect(Rect.fromLTWH(x, size.height - _radius, w, _radius), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.rtl != rtl ||
      old.top != top ||
      old.bar != bar ||
      old.current != current ||
      old.counts.length != counts.length ||
      !Iterable.generate(counts.length).every((i) => old.counts[i] == counts[i]);
}
