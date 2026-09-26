import 'package:flutter/painting.dart';

/// Type scale (Ather, renamed for gym use). Generated once from design/theme.json;
/// see docs/DESIGN.md. Sizes in logical px, `height` is a multiplier.
///
/// Every style: Readex Pro, tabular figures, weight driven through BOTH
/// `fontWeight` and the variable-font `wght` axis. Styles carry NO colour —
/// apply one from `context.colors` (the comment says which token is intended).
/// To change a weight use [AzmType.withWeight], never `copyWith(fontWeight:)`
/// alone (the variable axis would not follow).
abstract final class AzmType {
  static const String family = 'ReadexPro';
  static const List<FontFeature> _tnum = [FontFeature.tabularFigures()];

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  /// Returns [style] with weight [w] applied to both fontWeight and the wght axis.
  static TextStyle withWeight(TextStyle style, FontWeight w) => style.copyWith(
        fontWeight: w,
        fontVariations: [FontVariation('wght', w.value.toDouble())],
      );

  /// Big Lifted total on the workout summary.
  static const TextStyle summaryNumber = TextStyle(
    fontFamily: family,
    fontSize: 56,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    height: 1,
    letterSpacing: -2,
    fontFeatures: _tnum,
  );

  /// PR celebration number.
  static const TextStyle prNumber = TextStyle(
    fontFamily: family,
    fontSize: 44,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    height: 1.1,
    letterSpacing: -1.5,
    fontFeatures: _tnum,
  );

  /// عزم / Azm wordmark on splash.
  static const TextStyle wordmark = TextStyle(
    fontFamily: family,
    fontSize: 38,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    height: 1.1,
    letterSpacing: -0.6,
    fontFeatures: _tnum,
  );

  /// LiftedCounter in the history header.
  static const TextStyle liftedNumber = TextStyle(
    fontFamily: family,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    height: 1.1,
    letterSpacing: -0.5,
    fontFeatures: _tnum,
  );

  /// Workout tab title (display).
  static const TextStyle homeTitle = TextStyle(
    fontFamily: family,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    height: 1.2,
    letterSpacing: -0.5,
    fontFeatures: _tnum,
  );

  /// Summary-card number.
  static const TextStyle cardNumber = TextStyle(
    fontFamily: family,
    fontSize: 30,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    height: 1.1,
    letterSpacing: -0.5,
    fontFeatures: _tnum,
  );

  /// Value shown above the WeightKeypad.
  static const TextStyle keypadValue = TextStyle(
    fontFamily: family,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    height: 1.2,
    fontFeatures: _tnum,
  );

  /// Wizard step heading.
  static const TextStyle stepTitle = TextStyle(
    fontFamily: family,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    height: 1.25,
    letterSpacing: -0.4,
    fontFeatures: _tnum,
  );

  /// Section heading.
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: family,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    height: 1.3,
    letterSpacing: -0.3,
    fontFeatures: _tnum,
  );

  /// Inner-screen / app-bar title.
  static const TextStyle screenTitle = TextStyle(
    fontFamily: family,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    height: 1.3,
    letterSpacing: -0.3,
    fontFeatures: _tnum,
  );

  /// Set-row weight/reps (SetRow), stat values.
  static const TextStyle rowNumber = TextStyle(
    fontFamily: family,
    fontSize: 19,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    height: 1.2,
    fontFeatures: _tnum,
  );

  /// Smaller row trailing number.
  static const TextStyle rowNumberSmall = TextStyle(
    fontFamily: family,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    height: 1.2,
    fontFeatures: _tnum,
  );

  /// Empty-state heading.
  static const TextStyle emptyTitle = TextStyle(
    fontFamily: family,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    height: 1.3,
    fontFeatures: _tnum,
  );

  /// List row title.
  static const TextStyle rowTitle = TextStyle(
    fontFamily: family,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    height: 1.3,
    fontFeatures: _tnum,
  );

  /// Numeric input text.
  static const TextStyle input = TextStyle(
    fontFamily: family,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    height: 1.2,
    fontFeatures: _tnum,
  );

  /// Denser row title.
  static const TextStyle rowTitleSmall = TextStyle(
    fontFamily: family,
    fontSize: 16.5,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    height: 1.3,
    fontFeatures: _tnum,
  );

  /// Card heading.
  static const TextStyle cardTitle = TextStyle(
    fontFamily: family,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    height: 1.3,
    fontFeatures: _tnum,
  );

  /// Label inside a card.
  static const TextStyle cardLabel = TextStyle(
    fontFamily: family,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
    height: 1.3,
    fontFeatures: _tnum,
  );

  /// Button label.  colour: onAccent (filled) / textPrimary (text button)
  static const TextStyle button = TextStyle(
    fontFamily: family,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    height: 1.2,
    fontFeatures: _tnum,
  );

  /// Number on a row inside a card.
  static const TextStyle rowNumberCompact = TextStyle(
    fontFamily: family,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    height: 1.2,
    fontFeatures: _tnum,
  );

  /// Body text.
  static const TextStyle body = TextStyle(
    fontFamily: family,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    fontVariations: [FontVariation('wght', 500)],
    height: 1.5,
    fontFeatures: _tnum,
  );

  /// Row title inside a card.
  static const TextStyle listTitle = TextStyle(
    fontFamily: family,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
    height: 1.3,
    fontFeatures: _tnum,
  );

  /// Checklist / task label.
  static const TextStyle itemLabel = TextStyle(
    fontFamily: family,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    fontVariations: [FontVariation('wght', 500)],
    height: 1.3,
    fontFeatures: _tnum,
  );

  /// Segment, tally, quiet action.
  static const TextStyle controlLabel = TextStyle(
    fontFamily: family,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    height: 1.2,
    fontFeatures: _tnum,
  );

  /// Label on an accent pill.  colour: onAccent
  static const TextStyle pillLabel = TextStyle(
    fontFamily: family,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    height: 1.2,
    fontFeatures: _tnum,
  );

  /// Status line under a row title (wrong or textSecondary).
  static const TextStyle rowStatus = TextStyle(
    fontFamily: family,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontVariations: [FontVariation('wght', 500)],
    height: 1.4,
    fontFeatures: _tnum,
  );

  /// Stat label.
  static const TextStyle statLabel = TextStyle(
    fontFamily: family,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
    height: 1.3,
    fontFeatures: _tnum,
  );

  /// Secondary text.  colour: textSecondary
  static const TextStyle secondary = TextStyle(
    fontFamily: family,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontVariations: [FontVariation('wght', 500)],
    height: 1.5,
    fontFeatures: _tnum,
  );

  /// Emphasised secondary text.  colour: textSecondary
  static const TextStyle secondaryStrong = TextStyle(
    fontFamily: family,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
    height: 1.5,
    fontFeatures: _tnum,
  );

  /// Toast text.  colour: onPrimary
  static const TextStyle toastMessage = TextStyle(
    fontFamily: family,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
    height: 1.35,
    fontFeatures: _tnum,
  );

  /// Short verdict line.
  static const TextStyle statusLine = TextStyle(
    fontFamily: family,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
    height: 1.4,
    fontFeatures: _tnum,
  );

  /// Chip label.
  static const TextStyle chipLabel = TextStyle(
    fontFamily: family,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    height: 1.2,
    fontFeatures: _tnum,
  );

  /// Explanation under a card heading.  colour: textSecondary
  static const TextStyle sublabel = TextStyle(
    fontFamily: family,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    fontVariations: [FontVariation('wght', 500)],
    height: 1.5,
    fontFeatures: _tnum,
  );

  /// Settings group heading.  colour: textSecondary
  static const TextStyle groupHeading = TextStyle(
    fontFamily: family,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
    height: 1.3,
    fontFeatures: _tnum,
  );

  /// '/ 24' under a count.  colour: textSecondary
  static const TextStyle statDenominator = TextStyle(
    fontFamily: family,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
    height: 1.2,
    fontFeatures: _tnum,
  );

  /// Weekday letters.  colour: weekLabel
  static const TextStyle dayLabel = TextStyle(
    fontFamily: family,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
    height: 1.2,
    fontFeatures: _tnum,
  );

  /// Value above a chart column.
  static const TextStyle chartValue = TextStyle(
    fontFamily: family,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    height: 1.2,
    fontFeatures: _tnum,
  );

  /// Breadcrumbs, chart labels.  colour: textSecondary
  static const TextStyle small = TextStyle(
    fontFamily: family,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    fontVariations: [FontVariation('wght', 500)],
    height: 1.4,
    fontFeatures: _tnum,
  );

  /// Strong small text.  colour: textSecondary
  static const TextStyle smallStrong = TextStyle(
    fontFamily: family,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    height: 1.35,
    fontFeatures: _tnum,
  );

  /// Label above an input.  colour: textSecondary
  static const TextStyle fieldLabel = TextStyle(
    fontFamily: family,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
    height: 1.3,
    fontFeatures: _tnum,
  );

  /// Tab-bar label.
  static const TextStyle tabLabel = TextStyle(
    fontFamily: family,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    height: 1.2,
    fontFeatures: _tnum,
  );

  /// Mini badge.
  static const TextStyle badgeLabel = TextStyle(
    fontFamily: family,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    height: 1.2,
    fontFeatures: _tnum,
  );

  /// Name under a chart column.  colour: textSecondary
  static const TextStyle chartLabel = TextStyle(
    fontFamily: family,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
    height: 1.2,
    fontFeatures: _tnum,
  );

  /// Fine print.  colour: textMicro
  static const TextStyle micro = TextStyle(
    fontFamily: family,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    fontVariations: [FontVariation('wght', 400)],
    height: 1.5,
    fontFeatures: _tnum,
  );

  /// Count inside a 16px badge disc (only size below 11).
  static const TextStyle badgeCount = TextStyle(
    fontFamily: family,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    height: 1.2,
    fontFeatures: _tnum,
  );
}
