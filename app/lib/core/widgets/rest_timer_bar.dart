import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/azm_theme.dart';
import 'azm_pressable.dart';

/// `m:ss`, or `h:mm:ss` from one hour. Western digits, for tabular display.
String formatClock(Duration d) {
  final total = d.isNegative ? 0 : d.inSeconds;
  final h = total ~/ 3600, m = (total % 3600) ~/ 60, s = total % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
}

/// Remaining time shown for an end timestamp, rounded UP to the second.
Duration _remaining(DateTime endsAt, DateTime now) {
  final ms = endsAt.difference(now).inMilliseconds;
  return Duration(seconds: ms <= 0 ? 0 : (ms / 1000).ceil());
}

/// Rebuilds [builder] every [period] with the current time. Display only:
/// every value shown is derived from timestamps, never counted down.
class AzmTicker extends StatefulWidget {
  const AzmTicker({
    super.key,
    required this.builder,
    this.period = const Duration(milliseconds: 250),
    this.now = DateTime.now,
  });

  final Widget Function(BuildContext context, DateTime now) builder;
  final Duration period;
  final DateTime Function() now;

  @override
  State<AzmTicker> createState() => _AzmTickerState();
}

class _AzmTickerState extends State<AzmTicker> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.period, (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, widget.now());
}

/// Bottom bar of a running rest: remaining `m:ss`, progress, −15, +15, skip.
/// Derived from [endsAt] (DESIGN.md → RestTimerBar).
class RestTimerBar extends StatelessWidget {
  const RestTimerBar({
    super.key,
    required this.endsAt,
    required this.totalSeconds,
    required this.label,
    required this.skipLabel,
    required this.lessLabel,
    required this.moreLabel,
    required this.adjustSeconds,
    required this.onLess,
    required this.onMore,
    required this.onSkip,
    this.now = DateTime.now,
  });

  final DateTime endsAt;
  final int totalSeconds;
  final String label;
  final String skipLabel;

  /// Semantics labels of the −/+ buttons.
  final String lessLabel;
  final String moreLabel;
  final int adjustSeconds;
  final VoidCallback onLess;
  final VoidCallback onMore;
  final VoidCallback onSkip;
  final DateTime Function() now;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: AzmSize.restBarHeight,
      margin: const EdgeInsetsDirectional.fromSTEB(AzmSpace.pageMargin, 0, AzmSpace.pageMargin, AzmSpace.xs),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.md),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(AzmRadius.card)),
      child: Row(
        children: [
          Expanded(
            child: AzmTicker(
              now: now,
              builder: (context, t) {
                final left = _remaining(endsAt, t);
                final fraction = totalSeconds <= 0 ? 0.0 : (left.inMilliseconds / (totalSeconds * 1000)).clamp(0.0, 1.0);
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(label, style: AzmType.statLabel.copyWith(color: c.textSecondary)),
                        const SizedBox(width: AzmSpace.xs),
                        Text(formatClock(left), style: AzmType.rowNumber.copyWith(color: c.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: AzmSpace.textGap),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AzmRadius.pill),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: AzmSize.barTrackSmall,
                        color: c.accent,
                        backgroundColor: c.track,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: AzmSpace.xs),
          _PillButton(text: '−$adjustSeconds', semanticLabel: lessLabel, onTap: onLess),
          _PillButton(text: '+$adjustSeconds', semanticLabel: moreLabel, onTap: onMore),
          _PillButton(text: skipLabel, onTap: onSkip, emphasized: true),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({required this.text, required this.onTap, this.semanticLabel, this.emphasized = false});

  final String text;
  final String? semanticLabel;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AzmPressable(
      onTap: onTap,
      semanticLabel: semanticLabel ?? text,
      child: Center(
        child: Container(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.md, vertical: AzmSpace.xs),
          margin: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.opticalInset),
          decoration: BoxDecoration(
            color: emphasized ? c.accentSoft : c.fill,
            borderRadius: BorderRadius.circular(AzmRadius.pill),
          ),
          child: ExcludeSemantics(
            child: Text(
              text,
              style: AzmType.controlLabel.copyWith(color: emphasized ? c.accent : c.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mini rest timer (time only), used inside the ActiveWorkoutBar.
class RestTimerMini extends StatelessWidget {
  const RestTimerMini({super.key, required this.endsAt, this.now = DateTime.now});

  final DateTime endsAt;
  final DateTime Function() now;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.xs, vertical: AzmSpace.xxs),
      decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(AzmRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: AzmSize.tabBarBadgeDisc, color: c.accent),
          const SizedBox(width: AzmSpace.xxs),
          AzmTicker(
            now: now,
            builder: (context, t) => Text(
              formatClock(_remaining(endsAt, t)),
              style: AzmType.controlLabel.copyWith(color: c.accent),
            ),
          ),
        ],
      ),
    );
  }
}
