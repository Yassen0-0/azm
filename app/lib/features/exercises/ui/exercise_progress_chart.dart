import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/azm_theme.dart';

/// One point of the progress chart: a finished workout and its value (kg).
typedef ProgressPoint = ({DateTime date, double valueKg});

/// Minimal line chart for the exercise detail: one point per workout, oldest
/// at the START edge (so time flows in reading direction and the chart
/// mirrors in RTL). Accent line on `divider` grid lines; no fills, no glows.
class ExerciseProgressChart extends StatelessWidget {
  const ExerciseProgressChart({super.key, required this.points});

  /// Chronological (oldest first), at least 2.
  final List<ProgressPoint> points;

  // Derived from existing tokens (no chart tokens in the theme yet, see
  // docs/PLAN.md → Requests).
  static const double height = AzmSize.thumbnailCard * 2;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _ChartPainter(
          values: [for (final p in points) p.valueKg],
          rtl:
              Directionality.of(context) ==
              TextDirection.rtl, // directionality: ignore (painter works in physical space)
          line: c.accent,
          grid: c.divider,
          dotHole: c.card,
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.values,
    required this.rtl,
    required this.line,
    required this.grid,
    required this.dotHole,
  });

  final List<double> values;
  final bool rtl;
  final Color line;
  final Color grid;
  final Color dotHole;

  static const double _stroke = AzmSpace.opticalInset;
  static const double _dot = AzmSpace.xxs;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = AzmGlass.borderWidth;
    for (var i = 0; i < 3; i++) {
      final y = _dot + (size.height - 2 * _dot) * i / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    var lo = values.reduce(math.min);
    var hi = values.reduce(math.max);
    if (hi - lo < 1e-9) {
      lo -= 1;
      hi += 1;
    }
    final w = size.width - 2 * _dot;
    final h = size.height - 2 * _dot;
    Offset at(int i) {
      final t = i / (values.length - 1);
      // Physical x: oldest at the start edge (right in RTL).
      final x = _dot + (rtl ? 1 - t : t) * w;
      final y = _dot + (1 - (values[i] - lo) / (hi - lo)) * h;
      return Offset(x, y);
    }

    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    final fill = Paint()..color = line;
    final hole = Paint()..color = dotHole;
    for (var i = 0; i < values.length; i++) {
      canvas.drawCircle(at(i), _dot, fill);
      canvas.drawCircle(at(i), _dot - _stroke, hole);
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.rtl != rtl || old.line != line || old.grid != grid || !_same(old.values, values);

  static bool _same(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
