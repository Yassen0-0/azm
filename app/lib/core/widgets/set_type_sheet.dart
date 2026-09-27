import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../l10n/set_labels.dart';
import '../theme/azm_theme.dart';
import '../utils/workout_math.dart';
import 'azm_pressable.dart';
import 'set_row.dart';

/// Set type menu (tap on a set label), shared by the live workout, past
/// workout editing and the routine editor. Returns the chosen type, or null.
Future<SetType?> showSetTypeSheet(BuildContext context, SetType current) {
  final l = context.l10n;
  return showModalBottomSheet<SetType>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(AzmSpace.xxl, 0, AzmSpace.xxl, AzmSpace.xs),
            child: Text(l.commonSetTypeTitle, style: AzmType.cardTitle.copyWith(color: ctx.colors.textPrimary)),
          ),
          for (final t in SetType.values)
            _TypeOption(type: t, selected: t == current, onTap: () => Navigator.pop(ctx, t)),
          const SizedBox(height: AzmSpace.xs),
        ],
      ),
    ),
  );
}

class _TypeOption extends StatelessWidget {
  const _TypeOption({required this.type, required this.selected, required this.onTap});

  final SetType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final name = l.setTypeName(type);
    return AzmPressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: name,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.xxl, vertical: AzmSpace.md),
          child: Row(
            children: [
              SetLabelChip(label: l.setLabel(type, 1), kind: setLabelKind(type)),
              const SizedBox(width: AzmSpace.md),
              Expanded(child: Text(name, style: AzmType.itemLabel.copyWith(color: c.textPrimary))),
              if (selected) Icon(Icons.check_rounded, color: c.accent, size: AzmSize.icon),
            ],
          ),
        ),
      ),
    );
  }
}
