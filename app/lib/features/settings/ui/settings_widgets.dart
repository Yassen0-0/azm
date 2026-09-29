import 'package:flutter/material.dart';

import '../../../core/theme/azm_theme.dart';
import '../../../core/widgets/azm_pressable.dart';

/// Group heading + a card of rows separated by hairlines.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.heading, required this.children, this.footer});

  final String heading;
  final List<Widget> children;

  /// Optional small text under the card.
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: AzmSpace.xxs, bottom: AzmSpace.xs),
          child: Text(heading, style: AzmType.groupHeading.copyWith(color: c.textSecondary)),
        ),
        DecoratedBox(
          decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(AzmRadius.card)),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) Divider(indent: AzmSpace.cardPadding, height: 1, color: c.divider),
                children[i],
              ],
            ],
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(AzmSpace.xxs, AzmSpace.xs, AzmSpace.xxs, 0),
            child: Text(footer!, style: AzmType.secondary.copyWith(color: c.textTertiary)),
          ),
      ],
    );
  }
}

/// Single-choice row: optional leading icon, label, check when selected.
class SettingsOptionRow extends StatelessWidget {
  const SettingsOptionRow({super.key, required this.label, required this.selected, required this.onTap, this.icon});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Leading icon (accent while selected), e.g. the theme choices.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AzmPressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: label,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.cardPadding, vertical: AzmSpace.md),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: selected ? c.accent : c.textSecondary, size: AzmSize.icon),
                const SizedBox(width: AzmSpace.md),
              ],
              Expanded(child: Text(label, style: AzmType.listTitle.copyWith(color: c.textPrimary))),
              AnimatedOpacity(
                opacity: selected ? 1 : 0,
                duration: AzmMotion.of(context, AzmMotion.micro),
                child: Icon(Icons.check_rounded, color: c.accent, size: AzmSize.icon),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Row that opens something: icon, title (+ optional subtitle), current
/// value at the end, chevron (mirrors in RTL).
class SettingsNavRow extends StatelessWidget {
  const SettingsNavRow({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.value,
    this.busy = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? value;

  /// Shows a spinner instead of the chevron and ignores taps.
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AzmPressable(
      onTap: busy ? null : onTap,
      semanticLabel: [title, ?value, ?subtitle].join(', '),
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AzmSize.minTouchTarget),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.cardPadding, vertical: AzmSpace.md),
            child: Row(
              children: [
                Icon(icon, color: c.textSecondary, size: AzmSize.icon),
                const SizedBox(width: AzmSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AzmType.listTitle.copyWith(color: c.textPrimary)),
                      if (subtitle != null) ...[
                        const SizedBox(height: AzmSpace.xxs),
                        Text(subtitle!, style: AzmType.secondary.copyWith(color: c.textTertiary)),
                      ],
                    ],
                  ),
                ),
                if (value != null) ...[
                  const SizedBox(width: AzmSpace.xs),
                  Text(value!, style: AzmType.listTitle.copyWith(color: c.textSecondary)),
                ],
                const SizedBox(width: AzmSpace.xxs),
                SizedBox.square(
                  dimension: AzmSize.icon,
                  child: busy
                      ? Padding(
                          padding: const EdgeInsetsDirectional.all(AzmSpace.xxs),
                          child: CircularProgressIndicator(strokeWidth: AzmSize.chartStroke, color: c.accent),
                        )
                      // chevron_right mirrors in RTL (directional icon).
                      : Icon(Icons.chevron_right_rounded, color: c.textTertiary, size: AzmSize.icon),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet with a title, optional hint and single-choice rows.
/// Returns the chosen value, or null when dismissed.
Future<T?> showSettingsChoiceSheet<T>(
  BuildContext context, {
  required String title,
  String? hint,
  required List<({T value, String label, Key key})> choices,
  required T current,
}) =>
    showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (ctx) {
        final c = ctx.colors;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.8),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(AzmSpace.xxl, 0, AzmSpace.xxl, AzmSpace.xs),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AzmType.cardTitle.copyWith(color: c.textPrimary)),
                        if (hint != null) ...[
                          const SizedBox(height: AzmSpace.xxs),
                          Text(hint, style: AzmType.secondary.copyWith(color: c.textTertiary)),
                        ],
                      ],
                    ),
                  ),
                  for (final choice in choices)
                    Padding(
                      padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.xs),
                      child: SettingsOptionRow(
                        key: choice.key,
                        label: choice.label,
                        selected: choice.value == current,
                        onTap: () => Navigator.pop(ctx, choice.value),
                      ),
                    ),
                  const SizedBox(height: AzmSpace.xs),
                ],
              ),
            ),
          ),
        );
      },
    );
