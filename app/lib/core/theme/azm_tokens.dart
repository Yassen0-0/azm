import 'package:flutter/widgets.dart';

/// Spacing ladder — 4 · 8 · 12 · 16 · 20 · 24 ONLY. No invented sizes at call sites.
abstract final class AzmSpace {
  static const double xxs = 4;
  static const double xs = 8;
  static const double md = 12;
  static const double xl = 16;
  static const double xxl = 20;
  static const double xxxl = 24;

  static const double opticalInset = 2;
  static const double textGap = 6;
  static const double pageMargin = 16;
  static const double cardPadding = 16;
  static const double listGap = 12;
  static const EdgeInsetsDirectional inputPadding =
      EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 12);
}

/// Corner radii. Concentric rule: inner = outer − padding between them.
abstract final class AzmRadius {
  static const double card = 16;
  static const double button = 14;
  static const double input = 12;
  static const double segment = 8;
  static const double sheet = 22;
  static const double dialog = 16;
  static const double pill = 999;
}

/// Component sizes (Ather + gym additions, see docs/DESIGN.md → Sizes).
abstract final class AzmSize {
  static const double primaryButton = 52;
  static const double headerButton = 36;
  static const double input = 46;
  static const double inputTall = 50;
  static const double bigNumberField = 72;
  static const double checkbox = 24;
  static const double minTouchTarget = 48;
  static const double dayPicker = 48;
  static const double barTrack = 8;
  static const double barTrackSmall = 6;
  static const double sheetHandleWidth = 36;
  static const double sheetHandleHeight = 5;
  static const double toastBottom = 104;
  static const double icon = 24;

  // Floating glass tab bar
  static const double tabBarHeight = 64;
  static const double tabBarLift = 12;
  static const double tabBarIcon = 25;
  static const double tabBarBadgeDisc = 16;

  // Gym additions
  static const double setRowMinHeight = 52;
  static const double setCellMinWidth = 48;
  static const double keypadKeyHeight = 52;
  static const double restBarHeight = 64;
  static const double activeBarHeight = 56;
  static const double thumbnailList = 48;
  static const double thumbnailCard = 72;

  // Library filters
  /// Icon on a filter card (place / muscle-group silhouette / equipment).
  static const double filterIcon = 44;
  /// Height of a filter card in a filter sheet (icon + up to two label lines).
  static const double filterCard = 108;
  /// Count bubble on an active filter chip.
  static const double filterCount = 18;

  // Exercise detail
  /// Height of the per-exercise progress chart.
  static const double chartHeight = 144;
  /// Max edge of the exercise GIF / fallback square on the detail screen.
  static const double exerciseMedia = 216;
  /// Line width of the progress chart.
  static const double chartStroke = 2;
  /// Radius of a data point on the progress chart.
  static const double chartDot = 4;

  /// Bottom space a tab page must leave so its last item clears the floating
  /// tab bar. The shell Scaffold uses extendBody, so the body's bottom padding
  /// already contains tab bar + lift + device inset + ActiveWorkoutBarSlot;
  /// add one ladder step of breathing room.
  static double tabBarReserve(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom + AzmSpace.xl;
}

/// Glass — the floating tab bar ONLY (the one blur in the app).
abstract final class AzmGlass {
  static const double blurSigma = 24;
  static const double tintOpacity = 0.85;
  static const double borderWidth = 1;
}
