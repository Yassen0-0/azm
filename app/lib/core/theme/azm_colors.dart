import 'package:flutter/material.dart';

/// Colour tokens (Ather design system + Azm gym adaptations). See docs/DESIGN.md.
///
/// Read them with `context.colors` (extension in azm_theme.dart). Never use a
/// raw `Color(...)` outside this file.
///
/// Semantics:
/// - `accent` = ACTIVE (selected tab, primary button, ticked box). Never "done".
/// - `setDone*` = completed set (was Ather `right*`).
/// - `destructive*` = delete / missed / error (was Ather `wrong*`). Never a failure set.
/// - `warmup*` = warm-up set (amber, Azm's only new hue).
/// - `pr` = PR badge / numbers (reuses the accent; the trophy emoji carries meaning).
@immutable
class AzmColors extends ThemeExtension<AzmColors> {
  const AzmColors({
    required this.pageBackground,
    required this.card,
    required this.muted,
    required this.fill,
    required this.track,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textMicro,
    required this.textNoData,
    required this.weekLabel,
    required this.actionPrimary,
    required this.onPrimary,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.actionDisabled,
    required this.destructive,
    required this.destructiveTint,
    required this.destructiveText,
    required this.setDone,
    required this.setDoneText,
    required this.setDoneTint,
    required this.warmup,
    required this.warmupText,
    required this.warmupTint,
    required this.pr,
    required this.onState,
    required this.divider,
    required this.glassBorder,
    required this.switchOff,
    required this.switchKnob,
    required this.checkboxBorder,
    required this.dashedBorder,
    required this.scrim,
  });

  // Surfaces
  final Color pageBackground;
  final Color card;
  final Color muted;
  final Color fill;
  final Color track;

  // Text
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textMicro;
  final Color textNoData;
  final Color weekLabel;

  // Actions
  final Color actionPrimary;
  final Color onPrimary;
  final Color accent;
  final Color onAccent;
  final Color accentSoft;
  final Color actionDisabled;

  // States (gym semantics)
  final Color destructive;
  final Color destructiveTint;
  final Color destructiveText;
  final Color setDone;
  final Color setDoneText;
  final Color setDoneTint;
  final Color warmup;
  final Color warmupText;
  final Color warmupTint;
  final Color pr;
  final Color onState;

  // Lines and controls
  final Color divider;
  final Color glassBorder;
  final Color switchOff;
  final Color switchKnob;
  final Color checkboxBorder;
  final Color dashedBorder;
  final Color scrim;

  static const AzmColors light = AzmColors(
    pageBackground: Color(0xFFEFEFF2),
    card: Color(0xFFFFFFFF),
    muted: Color(0xFFF4F4F6),
    fill: Color(0xFFF1F1F4),
    track: Color(0xFFE9E9EC),
    textPrimary: Color(0xFF000000),
    textSecondary: Color(0xFF63636A),
    textTertiary: Color(0xFF7A7A80),
    textMicro: Color(0xFF7C7C82),
    textNoData: Color(0xFF70707A),
    weekLabel: Color(0xFF676770),
    actionPrimary: Color(0xFF000000),
    onPrimary: Color(0xFFFFFFFF),
    accent: Color(0xFF1B6EF3),
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0x1F1B6EF3),
    actionDisabled: Color(0xFFE9E9EC),
    destructive: Color(0xFFFF3B30),
    destructiveTint: Color(0x1AFF3B30),
    destructiveText: Color(0xFFC93229),
    setDone: Color(0xFF34C759),
    setDoneText: Color(0xFF1B7F3B),
    setDoneTint: Color(0x1F34C759),
    warmup: Color(0xFFFF9F0A),
    warmupText: Color(0xFFB25F00),
    warmupTint: Color(0x1FFF9F0A),
    pr: Color(0xFF1B6EF3),
    onState: Color(0xFFFFFFFF),
    divider: Color(0x0F000000),
    glassBorder: Color(0x12000000),
    switchOff: Color(0xFFDCDCE0),
    switchKnob: Color(0xFFFFFFFF),
    checkboxBorder: Color(0xFFD5D5DA),
    dashedBorder: Color(0xFFC6C6CB),
    scrim: Color(0x59000000),
  );

  /// Dark is the DEFAULT theme. It is a re-mapping of light; state fills keep
  /// identical values in both themes.
  static const AzmColors dark = AzmColors(
    pageBackground: Color(0xFF000000),
    card: Color(0xFF1C1C1E),
    muted: Color(0xFF161618),
    fill: Color(0xFF2A2A2E),
    track: Color(0xFF2C2C2E),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFA1A1A8),
    textTertiary: Color(0xFF88888E),
    textMicro: Color(0xFF8E8E94),
    textNoData: Color(0xFF5A5A60),
    weekLabel: Color(0xFF8E8E94),
    actionPrimary: Color(0xFFFFFFFF),
    onPrimary: Color(0xFF000000),
    accent: Color(0xFF4D9BFF),
    onAccent: Color(0xFF04203F),
    accentSoft: Color(0x2E4D9BFF),
    actionDisabled: Color(0xFF2C2C2E),
    destructive: Color(0xFFFF3B30),
    destructiveTint: Color(0x26FF3B30),
    destructiveText: Color(0xFFFF3B30),
    setDone: Color(0xFF34C759),
    setDoneText: Color(0xFF34C759),
    setDoneTint: Color(0x2634C759),
    warmup: Color(0xFFFF9F0A),
    warmupText: Color(0xFFFF9F0A),
    warmupTint: Color(0x26FF9F0A),
    pr: Color(0xFF4D9BFF),
    onState: Color(0xFFFFFFFF),
    divider: Color(0x14FFFFFF),
    glassBorder: Color(0x1AFFFFFF),
    switchOff: Color(0xFF3A3A3E),
    switchKnob: Color(0xFFF2F2F5),
    checkboxBorder: Color(0xFF48484C),
    dashedBorder: Color(0xFF48484C),
    scrim: Color(0x8C000000),
  );

  @override
  AzmColors copyWith() => this;

  @override
  AzmColors lerp(ThemeExtension<AzmColors>? other, double t) {
    if (other is! AzmColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AzmColors(
      pageBackground: l(pageBackground, other.pageBackground),
      card: l(card, other.card),
      muted: l(muted, other.muted),
      fill: l(fill, other.fill),
      track: l(track, other.track),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textTertiary: l(textTertiary, other.textTertiary),
      textMicro: l(textMicro, other.textMicro),
      textNoData: l(textNoData, other.textNoData),
      weekLabel: l(weekLabel, other.weekLabel),
      actionPrimary: l(actionPrimary, other.actionPrimary),
      onPrimary: l(onPrimary, other.onPrimary),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      accentSoft: l(accentSoft, other.accentSoft),
      actionDisabled: l(actionDisabled, other.actionDisabled),
      destructive: l(destructive, other.destructive),
      destructiveTint: l(destructiveTint, other.destructiveTint),
      destructiveText: l(destructiveText, other.destructiveText),
      setDone: l(setDone, other.setDone),
      setDoneText: l(setDoneText, other.setDoneText),
      setDoneTint: l(setDoneTint, other.setDoneTint),
      warmup: l(warmup, other.warmup),
      warmupText: l(warmupText, other.warmupText),
      warmupTint: l(warmupTint, other.warmupTint),
      pr: l(pr, other.pr),
      onState: l(onState, other.onState),
      divider: l(divider, other.divider),
      glassBorder: l(glassBorder, other.glassBorder),
      switchOff: l(switchOff, other.switchOff),
      switchKnob: l(switchKnob, other.switchKnob),
      checkboxBorder: l(checkboxBorder, other.checkboxBorder),
      dashedBorder: l(dashedBorder, other.dashedBorder),
      scrim: l(scrim, other.scrim),
    );
  }
}
