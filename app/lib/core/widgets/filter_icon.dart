import 'package:flutter/widgets.dart';

import '../theme/azm_theme.dart';
import 'filter_icon_paths.dart';

/// Icon of a library filter card (docs/DESIGN.md → Filter icons): a place, an
/// equipment group, or a body silhouette with the muscle group highlighted.
///
/// Original Azm vectors: `brand/icons/*.svg` → `brand/generate.sh` →
/// `filter_icon_paths.dart` (generated). Two tones from the theme: [base]
/// (silhouette / lines, default `textTertiary`) and [accent] (the highlight,
/// default `accent`). Not mirrored in RTL (nothing directional). An unknown
/// [id] draws nothing.
class FilterIcon extends StatelessWidget {
  const FilterIcon(this.id, {super.key, required this.size, this.base, this.accent});

  /// `place_<id>`, `muscle_<group>` or `equipment_<group>`.
  final String id;
  final double size;
  final Color? base;
  final Color? accent;

  static bool exists(String id) => filterIconData.containsKey(id);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _FilterIconPainter(id, base ?? c.textTertiary, accent ?? c.accent),
      ),
    );
  }
}

typedef _Shape = ({bool accent, double stroke, Path path});

class _FilterIconPainter extends CustomPainter {
  _FilterIconPainter(this.id, this.base, this.accent);

  final String id;
  final Color base;
  final Color accent;

  static final _cache = <String, List<_Shape>>{};

  static List<_Shape> _shapes(String id) => _cache.putIfAbsent(id, () {
        return [
          for (final (tone, stroke, evenOdd, cmds) in filterIconData[id] ?? const <(int, double, bool, List<double>)>[])
            (accent: tone == 1, stroke: stroke, path: _decode(cmds)..fillType = evenOdd ? PathFillType.evenOdd : PathFillType.nonZero),
        ];
      });

  static Path _decode(List<double> p) {
    final path = Path();
    var i = 0;
    while (i < p.length) {
      switch (p[i++].toInt()) {
        case 0:
          path.moveTo(p[i++], p[i++]);
        case 1:
          path.lineTo(p[i++], p[i++]);
        case 2:
          path.cubicTo(p[i++], p[i++], p[i++], p[i++], p[i++], p[i++]);
        default:
          path.close();
      }
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / filterIconViewBox, size.height / filterIconViewBox);
    for (final s in _shapes(id)) {
      final paint = Paint()
        ..isAntiAlias = true
        ..color = s.accent ? accent : base;
      if (s.stroke > 0) {
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = s.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
      }
      canvas.drawPath(s.path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FilterIconPainter old) => old.id != id || old.base != base || old.accent != accent;
}
