import 'package:flutter/material.dart';

import '../theme/azm_theme.dart';
import 'azm_pressable.dart';

/// Round 36px header icon button on a `fill` disc (48px hit area).
class AzmHeaderButton extends StatelessWidget {
  const AzmHeaderButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AzmPressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: Center(
        child: Container(
          width: AzmSize.headerButton,
          height: AzmSize.headerButton,
          decoration: BoxDecoration(color: c.fill, shape: BoxShape.circle),
          child: Icon(icon, size: AzmSize.icon - AzmSpace.xxs, color: c.textPrimary),
        ),
      ),
    );
  }
}

/// Header of a top-level tab: large title at the start, actions at the end.
class AzmTabHeader extends StatelessWidget {
  const AzmTabHeader({super.key, required this.title, this.actions = const []});

  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AzmSpace.pageMargin,
        AzmSpace.xs,
        AzmSpace.xs,
        AzmSpace.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: AzmType.homeTitle.copyWith(color: context.colors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

/// Header of a pushed (inner) screen: back button at the start, screenTitle.
class AzmInnerHeader extends StatelessWidget {
  const AzmInnerHeader({
    super.key,
    required this.title,
    required this.backLabel,
    required this.onBack,
  });

  final String title;
  final String backLabel;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AzmSpace.xs,
        AzmSpace.xs,
        AzmSpace.pageMargin,
        AzmSpace.xs,
      ),
      child: Row(
        children: [
          // arrow_back mirrors automatically in RTL (matchTextDirection).
          AzmHeaderButton(icon: Icons.arrow_back_rounded, semanticLabel: backLabel, onTap: onBack),
          const SizedBox(width: AzmSpace.xxs),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: AzmType.screenTitle.copyWith(color: context.colors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
