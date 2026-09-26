import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/azm_theme.dart';
import '../../../core/utils/workout_math.dart';
import '../../../core/widgets/azm_pressable.dart';
import 'workout_format.dart';

/// Bottom-sheet list row: icon + label (optionally destructive / selected).
class SheetAction extends StatelessWidget {
  const SheetAction({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.leading,
    this.destructive = false,
    this.selected = false,
  });

  final String label;
  final IconData? icon;
  final Widget? leading;
  final VoidCallback onTap;
  final bool destructive;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = destructive ? c.destructiveText : c.textPrimary;
    return AzmPressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: label,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.xxl, vertical: AzmSpace.md),
          child: Row(
            children: [
              if (leading != null) leading! else if (icon != null) Icon(icon, color: color, size: AzmSize.icon),
              const SizedBox(width: AzmSpace.md),
              Expanded(child: Text(label, style: AzmType.itemLabel.copyWith(color: color))),
              if (selected) Icon(Icons.check_rounded, color: c.accent, size: AzmSize.icon),
            ],
          ),
        ),
      ),
    );
  }
}

Future<T?> _sheet<T>(BuildContext context, {required String title, required List<Widget> Function(BuildContext) children}) =>
    showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(AzmSpace.xxl, 0, AzmSpace.xxl, AzmSpace.xs),
              child: Text(title, style: AzmType.cardTitle.copyWith(color: context.colors.textPrimary)),
            ),
            ...children(context),
            const SizedBox(height: AzmSpace.xs),
          ],
        ),
      ),
    );

/// Set type menu (tap on the set label). Returns the chosen type.
Future<SetType?> showSetTypeSheet(BuildContext context, SetType current) {
  final l = context.l10n;
  return _sheet<SetType>(
    context,
    title: l.workoutSetTypeTitle,
    children: (ctx) => [
      for (final t in SetType.values)
        SheetAction(
          label: l.setTypeName(t),
          selected: t == current,
          leading: _TypeChip(type: t),
          onTap: () => Navigator.pop(ctx, t),
        ),
    ],
  );
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});

  final SetType type;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final warm = type == SetType.warmup;
    return Container(
      width: AzmSize.headerButton,
      height: AzmSize.headerButton,
      alignment: AlignmentDirectional.center,
      decoration: BoxDecoration(
        color: warm ? c.warmupTint : c.fill,
        borderRadius: BorderRadius.circular(AzmRadius.segment),
      ),
      child: Text(
        context.l10n.setLabelFor(type, 1),
        style: AzmType.controlLabel.copyWith(
          color: warm ? c.warmupText : (type == SetType.normal ? c.textSecondary : c.textPrimary),
        ),
      ),
    );
  }
}

enum ExerciseMenuAction { reorder, remove }

Future<ExerciseMenuAction?> showExerciseMenu(BuildContext context, String exerciseName) {
  final l = context.l10n;
  return _sheet<ExerciseMenuAction>(
    context,
    title: exerciseName,
    children: (ctx) => [
      SheetAction(
        label: l.workoutReorder,
        icon: Icons.swap_vert_rounded,
        onTap: () => Navigator.pop(ctx, ExerciseMenuAction.reorder),
      ),
      SheetAction(
        label: l.workoutRemoveExercise,
        icon: Icons.delete_outline_rounded,
        destructive: true,
        onTap: () => Navigator.pop(ctx, ExerciseMenuAction.remove),
      ),
    ],
  );
}

/// Drag-to-reorder sheet. [onReorder] receives ids in the new order and is
/// called (and persisted by the caller) on every drop.
Future<void> showReorderSheet(
  BuildContext context, {
  required List<({String id, String name})> items,
  required ValueChanged<List<String>> onReorder,
}) {
  final l = context.l10n;
  var order = [...items];
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: StatefulBuilder(
        builder: (ctx, setState) {
          final c = ctx.colors;
          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.7),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(AzmSpace.xxl, 0, AzmSpace.xs, 0),
                  child: Row(
                    children: [
                      Expanded(child: Text(l.workoutReorder, style: AzmType.cardTitle.copyWith(color: c.textPrimary))),
                      TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.workoutDone)),
                    ],
                  ),
                ),
                Flexible(
                  child: ReorderableListView(
                    shrinkWrap: true,
                    buildDefaultDragHandles: false,
                    onReorderItem: (from, to) {
                      setState(() => order.insert(to, order.removeAt(from)));
                      onReorder([for (final i in order) i.id]);
                    },
                    children: [
                      for (var i = 0; i < order.length; i++)
                        ReorderableDragStartListener(
                          key: ValueKey(order[i].id),
                          index: i,
                          child: Container(
                            color: c.card,
                            padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.xxl, vertical: AzmSpace.md),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(order[i].name, style: AzmType.itemLabel.copyWith(color: c.textPrimary)),
                                ),
                                Icon(Icons.drag_handle_rounded, color: c.textTertiary),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

/// Confirmation dialog. Returns true on confirm.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirm,
  bool destructive = false,
}) async {
  final l = context.l10n;
  final ok = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) {
      final c = ctx.colors;
      return AlertDialog(
        title: Text(title, style: AzmType.cardTitle.copyWith(color: c.textPrimary)),
        content: Text(body, style: AzmType.body.copyWith(color: c.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.workoutCancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: destructive ? c.destructiveText : c.accent),
            child: Text(confirm),
          ),
        ],
      );
    },
  );
  return ok ?? false;
}
