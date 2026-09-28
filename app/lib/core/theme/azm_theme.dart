import 'package:flutter/material.dart';

import 'azm_colors.dart';
import 'azm_motion.dart';
import 'azm_tokens.dart';
import 'azm_type.dart';

export 'azm_colors.dart';
export 'azm_motion.dart';
export 'azm_tokens.dart';
export 'azm_type.dart';

/// `context.colors.accent` etc.
extension AzmThemeContext on BuildContext {
  AzmColors get colors => Theme.of(this).extension<AzmColors>()!;
}

/// Builds the Material theme from Azm tokens. Dark is the app default.
abstract final class AzmTheme {
  static ThemeData dark() => _build(AzmColors.dark, Brightness.dark);
  static ThemeData light() => _build(AzmColors.light, Brightness.light);

  static ThemeData _build(AzmColors c, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.accent,
      onPrimary: c.onAccent,
      primaryContainer: c.accentSoft,
      onPrimaryContainer: c.textPrimary,
      secondary: c.accent,
      onSecondary: c.onAccent,
      error: c.destructive,
      onError: c.onState,
      errorContainer: c.destructiveTint,
      onErrorContainer: c.destructiveText,
      surface: c.card,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      surfaceContainerLowest: c.pageBackground,
      surfaceContainerLow: c.muted,
      surfaceContainer: c.card,
      surfaceContainerHigh: c.fill,
      surfaceContainerHighest: c.fill,
      outline: c.checkboxBorder,
      outlineVariant: c.divider,
      scrim: c.scrim,
      shadow: const Color(0x00000000),
      surfaceTint: const Color(0x00000000),
      inverseSurface: c.actionPrimary,
      onInverseSurface: c.onPrimary,
    );

    TextStyle t(TextStyle s, Color color) => s.copyWith(color: color);
    final textTheme = TextTheme(
      displayLarge: t(AzmType.homeTitle, c.textPrimary),
      displayMedium: t(AzmType.sectionTitle, c.textPrimary),
      titleLarge: t(AzmType.screenTitle, c.textPrimary),
      titleMedium: t(AzmType.cardTitle, c.textPrimary),
      titleSmall: t(AzmType.rowTitle, c.textPrimary),
      bodyLarge: t(AzmType.body, c.textPrimary),
      bodyMedium: t(AzmType.body, c.textPrimary),
      bodySmall: t(AzmType.secondary, c.textSecondary),
      labelLarge: t(AzmType.button, c.textPrimary),
      labelMedium: t(AzmType.chipLabel, c.textPrimary),
      labelSmall: t(AzmType.micro, c.textMicro),
    );

    final pageTransitions = PageTransitionsTheme(
      builders: {
        for (final p in TargetPlatform.values) p: const AzmPageTransitionsBuilder(),
      },
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: AzmType.family,
      textTheme: textTheme,
      scaffoldBackgroundColor: c.pageBackground,
      canvasColor: c.pageBackground,
      extensions: [c],
      // No ripples / highlights anywhere: press feedback is scale(0.97).
      splashFactory: NoSplash.splashFactory,
      splashColor: const Color(0x00000000),
      highlightColor: const Color(0x00000000),
      hoverColor: const Color(0x00000000),
      pageTransitionsTheme: pageTransitions,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: AppBarTheme(
        backgroundColor: c.pageBackground,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: const Color(0x00000000),
        centerTitle: false,
        titleTextStyle: t(AzmType.screenTitle, c.textPrimary),
      ),
      iconTheme: IconThemeData(color: c.textPrimary, size: AzmSize.icon),
      dividerTheme: DividerThemeData(color: c.divider, thickness: 1, space: 1),
      cardTheme: CardThemeData(
        color: c.card,
        elevation: 0,
        margin: EdgeInsetsDirectional.zero,
        surfaceTintColor: const Color(0x00000000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AzmRadius.card)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: c.onAccent,
          disabledBackgroundColor: c.actionDisabled,
          minimumSize: const Size.fromHeight(AzmSize.primaryButton),
          textStyle: AzmType.button,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AzmRadius.button)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: c.textPrimary, textStyle: AzmType.button),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.muted,
        hintStyle: t(AzmType.body, c.textTertiary),
        contentPadding: AzmSpace.inputPadding,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AzmRadius.input),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AzmRadius.input),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AzmRadius.input),
          borderSide: BorderSide(color: c.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AzmRadius.input),
          borderSide: BorderSide(color: c.destructive, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AzmRadius.input),
          borderSide: BorderSide(color: c.destructive, width: 1.5),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.card,
        modalBackgroundColor: c.card,
        modalBarrierColor: c.scrim,
        elevation: 0,
        modalElevation: 0,
        surfaceTintColor: const Color(0x00000000),
        showDragHandle: true,
        dragHandleColor: c.fill,
        dragHandleSize: const Size(AzmSize.sheetHandleWidth, AzmSize.sheetHandleHeight),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadiusDirectional.vertical(top: Radius.circular(AzmRadius.sheet)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.card,
        elevation: 0,
        surfaceTintColor: const Color(0x00000000),
        barrierColor: c.scrim,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AzmRadius.dialog)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.fill,
        selectedColor: c.accent,
        labelStyle: t(AzmType.chipLabel, c.textPrimary),
        secondaryLabelStyle: t(AzmType.chipLabel, c.onAccent),
        side: BorderSide.none,
        shape: const StadiumBorder(),
        elevation: 0,
        pressElevation: 0,
        showCheckmark: false,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(c.switchKnob),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.setDone : c.switchOff,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Color(0x00000000)),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.accent : const Color(0x00000000),
        ),
        checkColor: WidgetStatePropertyAll(c.onAccent),
        side: BorderSide(color: c.checkboxBorder, width: 1.5),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.accent,
        linearTrackColor: c.track,
        linearMinHeight: AzmSize.barTrack,
        borderRadius: BorderRadius.circular(AzmRadius.pill),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.actionPrimary,
        contentTextStyle: t(AzmType.toastMessage, c.onPrimary),
        actionTextColor: c.onPrimary,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: c.actionPrimary,
          borderRadius: BorderRadius.circular(AzmRadius.segment),
        ),
        textStyle: t(AzmType.small, c.onPrimary),
      ),
    );
  }
}

/// Page transition: fade + rise vertically (direction-neutral, RTL-safe).
/// Reduced motion: no movement.
class AzmPageTransitionsBuilder extends PageTransitionsBuilder {
  const AzmPageTransitionsBuilder();

  @override
  Duration get transitionDuration => AzmMotion.page;

  @override
  Duration get reverseTransitionDuration => AzmMotion.exit;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (AzmMotion.reduced(context)) return child;
    final curved = CurvedAnimation(
      parent: animation,
      curve: AzmMotion.standard,
      reverseCurve: AzmMotion.standard.flipped,
    );
    return FadeTransition(
      opacity: curved,
      child: AnimatedBuilder(
        animation: curved,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, (1 - curved.value) * AzmMotion.pageRise),
          child: child,
        ),
        child: child,
      ),
    );
  }
}

/// No scrollbars anywhere; platform-default overscroll physics.
class AzmScrollBehavior extends MaterialScrollBehavior {
  const AzmScrollBehavior();

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) => child;
}
