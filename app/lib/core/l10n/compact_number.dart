import 'l10n.dart';

/// Scale suffix of a compact number.
enum CompactScale { none, thousand, million, billion }

/// A compact number: [number] (Western digits) + [scale], e.g. ("1.2", million).
typedef CompactNumber = ({String number, CompactScale scale});

/// Compact form of a big total (e.g. the all-time Lifted):
/// - below 100,000: the full integer with separators (`84,500`), so normal
///   totals stay exact;
/// - thousands: integer thousands (`450` K);
/// - millions / billions: one decimal, trailing `.0` dropped (`1.2` M, `3` M).
/// Rounding that reaches the next scale moves up (999,999 → `1` M).
CompactNumber compactNumber(double value) {
  final v = value < 0 ? 0.0 : value;
  if (v < 100000) return (number: AzmNumbers.integer(v), scale: CompactScale.none);
  final k = (v / 1000).round();
  if (k < 1000) return (number: AzmNumbers.integer(k), scale: CompactScale.thousand);
  final m = _round1(v / 1e6);
  if (m < 1000) return (number: AzmNumbers.decimal(m), scale: CompactScale.million);
  return (number: AzmNumbers.decimal(_round1(v / 1e9)), scale: CompactScale.billion);
}

double _round1(double v) => (v * 10).roundToDouble() / 10;

extension CompactNumbers on AppLocalizations {
  /// `84,500` / `450K` / `1.2M` (Arabic `450 ألف` / `1.2 مليون` / `2 مليار`).
  /// Not wrapped in an LTR isolate: in Arabic the scale word must follow the
  /// paragraph direction (`165 ألف`, not `ألف 165`).
  String compactNumberText(double value) {
    final c = compactNumber(value);
    return switch (c.scale) {
      CompactScale.none => c.number,
      CompactScale.thousand => commonCompactThousand(c.number),
      CompactScale.million => commonCompactMillion(c.number),
      CompactScale.billion => commonCompactBillion(c.number),
    };
  }
}
