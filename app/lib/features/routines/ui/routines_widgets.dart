import 'package:flutter/material.dart';

import '../../../core/db/app_database.dart';
import '../../../core/l10n/exercise_names.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/azm_theme.dart';
import '../../../core/widgets/azm_pressable.dart';

// Feature-local widgets and formatting for routines, programs and onboarding.
// (Set rows, the keypad and set-type labels are the shared core ones:
// core/widgets/set_row.dart, set_keypad.dart, set_type_sheet.dart and
// core/l10n/set_labels.dart.)

extension RoutinesFormat on AppLocalizations {
  /// e.g. `3 × 8–12` (left-to-right in both languages).
  String routinesSetsRepsRange(int sets, int repsMin, int repsMax) => ltrIsolate(routinesSetsReps(
        AzmNumbers.integer(sets),
        repsMin == repsMax ? AzmNumbers.integer(repsMax) : '${AzmNumbers.integer(repsMin)}–${AzmNumbers.integer(repsMax)}',
      ));

  String routineName(Routine r) => r.name.trim().isEmpty ? routinesUntitled : r.name.trim();
}

/// Wraps a numeric expression in a left-to-right isolate so bidi can't
/// reorder it inside Arabic text.
String ltrIsolate(String s) => '\u2066$s\u2069';

/// Rest as `m:ss` (Western digits).
String formatRest(int seconds) => '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

/// Primary/secondary names, or "Unknown exercise (id)".
ExerciseNames routineNamesFor(BuildContext context, Exercise? e, String exerciseId) =>
    e == null ? (primary: context.l10n.routinesUnknownExercise(exerciseId), secondary: null) : context.namesOf(e);

/// Full-width button: primary (accent), secondary (fill) or destructive text.
class RoutinesWideButton extends StatelessWidget {
  const RoutinesWideButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.primary = false,
    this.destructive = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool primary;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bg = onTap == null ? c.actionDisabled : (primary ? c.accent : (destructive ? Colors.transparent : c.fill));
    final fg = onTap == null ? c.textTertiary : (primary ? c.onAccent : (destructive ? c.destructiveText : c.textPrimary));
    return AzmPressable(
      onTap: onTap,
      semanticLabel: label,
      child: ExcludeSemantics(
        child: Container(
          height: AzmSize.primaryButton,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AzmRadius.button)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: fg, size: AzmSize.icon),
                const SizedBox(width: AzmSpace.xs),
              ],
              Flexible(
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AzmType.button.copyWith(color: fg)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small pill (days a week, level, rest).
class RoutinesPill extends StatelessWidget {
  const RoutinesPill({super.key, required this.label, this.icon, this.accent = false});

  final String label;
  final IconData? icon;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = accent ? c.accent : c.textSecondary;
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AzmSpace.xs, vertical: AzmSpace.xxs),
      decoration: BoxDecoration(
        color: accent ? c.accentSoft : c.fill,
        borderRadius: BorderRadius.circular(AzmRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AzmSize.tabBarBadgeDisc, color: fg),
            const SizedBox(width: AzmSpace.xxs),
          ],
          Text(label, style: AzmType.smallStrong.copyWith(color: fg)),
        ],
      ),
    );
  }
}

/// Placeholder thumbnail for an exercise missing from the catalog.
class RoutinesUnknownThumb extends StatelessWidget {
  const RoutinesUnknownThumb({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: AzmSize.thumbnailList,
      height: AzmSize.thumbnailList,
      decoration: BoxDecoration(color: c.fill, borderRadius: BorderRadius.circular(AzmRadius.input)),
      child: Icon(Icons.help_outline_rounded, color: c.textTertiary),
    );
  }
}

/// Round placeholder for an exercise missing from the catalog (avatar size).
class RoutineUnknownAvatar extends StatelessWidget {
  const RoutineUnknownAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: AzmSize.avatar,
      height: AzmSize.avatar,
      decoration: BoxDecoration(color: c.fill, shape: BoxShape.circle),
      child: Icon(Icons.help_outline_rounded, color: c.textTertiary, size: AzmSize.icon - AzmSpace.xxs),
    );
  }
}

/// Bottom-sheet list row: icon + label (optionally destructive / selected).
class RoutinesSheetAction extends StatelessWidget {
  const RoutinesSheetAction({
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
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
          child: SingleChildScrollView(
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
        ),
      ),
    );

/// Rest choices offered for a per-exercise override (seconds).
const List<int> kRestChoices = [30, 45, 60, 90, 120, 150, 180, 240, 300];

/// Rest menu. Returns `(seconds: null)` for "default", `(seconds: s)` for an
/// override, or null when dismissed.
Future<({int? seconds})?> showRoutineRestSheet(BuildContext context, {required int? current, required int defaultSeconds}) {
  final l = context.l10n;
  return _sheet<({int? seconds})>(
    context,
    title: l.routinesRestTitle,
    children: (ctx) => [
      RoutinesSheetAction(
        label: l.routinesRestUseDefault(formatRest(defaultSeconds)),
        icon: Icons.settings_backup_restore_rounded,
        selected: current == null,
        onTap: () => Navigator.pop(ctx, (seconds: null)),
      ),
      for (final s in kRestChoices)
        RoutinesSheetAction(
          label: formatRest(s),
          icon: Icons.timer_outlined,
          selected: current == s,
          onTap: () => Navigator.pop(ctx, (seconds: s)),
        ),
    ],
  );
}

enum RoutineMenuAction { edit, delete }

/// ⋯ menu of a routine card: edit, delete.
Future<RoutineMenuAction?> showRoutineMenu(BuildContext context, String routineName) {
  final l = context.l10n;
  return _sheet<RoutineMenuAction>(
    context,
    title: routineName,
    children: (ctx) => [
      RoutinesSheetAction(
        key: const ValueKey('routineMenuEdit'),
        label: l.routinesEditTitle,
        icon: Icons.edit_outlined,
        onTap: () => Navigator.pop(ctx, RoutineMenuAction.edit),
      ),
      RoutinesSheetAction(
        key: const ValueKey('routineMenuDelete'),
        label: l.routinesDelete,
        icon: Icons.delete_outline_rounded,
        destructive: true,
        onTap: () => Navigator.pop(ctx, RoutineMenuAction.delete),
      ),
    ],
  );
}

/// Full-width accent start button holding ONLY a dumbbell icon (no text);
/// screen readers hear "Start routine" / "ابدأ الروتين".
class RoutineStartButton extends StatelessWidget {
  const RoutineStartButton({super.key, required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AzmPressable(
      onTap: onTap,
      semanticLabel: context.l10n.routinesStartRoutine,
      child: ExcludeSemantics(
        child: Container(
          height: AzmSize.buttonCompact,
          decoration: BoxDecoration(
            color: onTap == null ? c.actionDisabled : c.accent,
            borderRadius: BorderRadius.circular(AzmRadius.input),
          ),
          child: Icon(Icons.fitness_center_rounded, color: onTap == null ? c.textTertiary : c.onAccent, size: AzmSize.icon),
        ),
      ),
    );
  }
}

/// Deletes a routine after confirming. Returns true when deleted.
Future<bool> confirmDeleteRoutine(BuildContext context, Future<void> Function() delete) async {
  final l = context.l10n;
  final ok = await routinesConfirm(
    context,
    title: l.routinesDeleteTitle,
    body: l.routinesDeleteBody,
    confirm: l.routinesDeleteConfirm,
    destructive: true,
  );
  if (ok) await delete();
  return ok;
}

enum RoutineExerciseAction { rest, reorder, remove }

Future<RoutineExerciseAction?> showRoutineExerciseMenu(BuildContext context, String exerciseName) {
  final l = context.l10n;
  return _sheet<RoutineExerciseAction>(
    context,
    title: exerciseName,
    children: (ctx) => [
      RoutinesSheetAction(
        label: l.routinesRestTitle,
        icon: Icons.timer_outlined,
        onTap: () => Navigator.pop(ctx, RoutineExerciseAction.rest),
      ),
      RoutinesSheetAction(
        label: l.routinesReorder,
        icon: Icons.swap_vert_rounded,
        onTap: () => Navigator.pop(ctx, RoutineExerciseAction.reorder),
      ),
      RoutinesSheetAction(
        label: l.routinesRemoveExercise,
        icon: Icons.delete_outline_rounded,
        destructive: true,
        onTap: () => Navigator.pop(ctx, RoutineExerciseAction.remove),
      ),
    ],
  );
}

/// Drag-to-reorder sheet; [onReorder] gets the ids in the new order after
/// every drop (the caller persists it immediately).
Future<void> showRoutineReorderSheet(
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
                      Expanded(child: Text(l.routinesReorder, style: AzmType.cardTitle.copyWith(color: c.textPrimary))),
                      TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.routinesDone)),
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
Future<bool> routinesConfirm(
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.routinesCancel)),
          TextButton(
            key: const ValueKey('routinesConfirm'),
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
