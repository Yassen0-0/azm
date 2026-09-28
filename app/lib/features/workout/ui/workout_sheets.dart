import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/azm_theme.dart';
import '../../../core/widgets/azm_pressable.dart';
import '../../../core/widgets/rest_timer_bar.dart' show AzmTicker, formatClock;

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

/// Like [_sheet], but scrolls when the options don't fit (long lists).
Future<T?> _scrollSheet<T>(BuildContext context, {required String title, required List<Widget> Function(BuildContext) children}) =>
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

/// Rest choices offered per exercise and as manual timer presets (seconds).
const List<int> kWorkoutRestChoices = [30, 45, 60, 90, 120, 150, 180, 240, 300];

/// Presets of the manual rest timer (top-bar ⏱).
const List<int> kManualRestPresets = [30, 60, 90, 120, 180, 300];

/// Rest as `m:ss` (Western digits).
String formatRestSeconds(int seconds) => formatClock(Duration(seconds: seconds));

/// Keys for tests.
abstract final class WorkoutSheetKeys {
  static const restDefault = ValueKey('restPickDefault');
  static const restOff = ValueKey('restPickOff');
  static ValueKey<String> restChoice(int s) => ValueKey('restPick-$s');
  static ValueKey<String> manualPreset(int s) => ValueKey('manualRest-$s');
  static const manualSkip = ValueKey('manualRestSkip');
}

/// Per-exercise rest picker (the "Rest Timer" line): default, OFF, or a
/// fixed time. Returns `(seconds: null)` for default, `(seconds: 0)` for OFF,
/// `(seconds: s)` for a time, or null when dismissed.
Future<({int? seconds})?> showExerciseRestSheet(
  BuildContext context, {
  required String exerciseName,
  required int? current,
  required int defaultSeconds,
}) {
  final l = context.l10n;
  return _scrollSheet<({int? seconds})>(
    context,
    title: '${l.workoutRestPickerTitle} · $exerciseName',
    children: (ctx) => [
      SheetAction(
        key: WorkoutSheetKeys.restDefault,
        label: l.workoutRestPickerDefault(formatRestSeconds(defaultSeconds)),
        icon: Icons.settings_backup_restore_rounded,
        selected: current == null,
        onTap: () => Navigator.pop(ctx, (seconds: null)),
      ),
      SheetAction(
        key: WorkoutSheetKeys.restOff,
        label: l.workoutRestPickerOff,
        icon: Icons.timer_off_outlined,
        selected: current == 0,
        onTap: () => Navigator.pop(ctx, (seconds: 0)),
      ),
      for (final s in kWorkoutRestChoices)
        SheetAction(
          key: WorkoutSheetKeys.restChoice(s),
          label: formatRestSeconds(s),
          icon: Icons.timer_outlined,
          selected: current == s,
          onTap: () => Navigator.pop(ctx, (seconds: s)),
        ),
    ],
  );
}

/// Manual rest timer (top-bar ⏱): presets start a countdown; while one runs
/// it shows the time left and "Skip". Returns the seconds to start, 0 to
/// skip the running one, or null when dismissed.
Future<int?> showManualRestSheet(
  BuildContext context, {
  required DateTime? runningEndsAt,
  required DateTime Function() now,
}) {
  final l = context.l10n;
  return showModalBottomSheet<int>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (ctx) {
      final c = ctx.colors;
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.fromSTEB(AzmSpace.xxl, 0, AzmSpace.xxl, AzmSpace.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.workoutTimerTitle, style: AzmType.cardTitle.copyWith(color: c.textPrimary)),
              const SizedBox(height: AzmSpace.xxs),
              Text(l.workoutTimerBody, style: AzmType.secondary.copyWith(color: c.textSecondary)),
              if (runningEndsAt != null) ...[
                const SizedBox(height: AzmSpace.md),
                Row(
                  children: [
                    Expanded(
                      child: AzmTicker(
                        now: now,
                        builder: (_, t) => Text(
                          l.workoutTimerRunning(formatClock(runningEndsAt.difference(t))),
                          style: AzmType.rowNumberCompact.copyWith(color: c.accent),
                        ),
                      ),
                    ),
                    AzmPressable(
                      key: WorkoutSheetKeys.manualSkip,
                      onTap: () => Navigator.pop(ctx, 0),
                      semanticLabel: l.workoutRestSkip,
                      child: ExcludeSemantics(
                        child: Center(
                          child: Text(l.workoutRestSkip, style: AzmType.controlLabel.copyWith(color: c.accent)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AzmSpace.md),
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: AzmSpace.xs,
                  crossAxisSpacing: AzmSpace.xs,
                  mainAxisExtent: AzmSize.buttonCompact,
                ),
                children: [
                  for (final s in kManualRestPresets)
                    AzmPressable(
                      key: WorkoutSheetKeys.manualPreset(s),
                      onTap: () => Navigator.pop(ctx, s),
                      semanticLabel: formatRestSeconds(s),
                      child: ExcludeSemantics(
                        child: Container(
                          alignment: AlignmentDirectional.center,
                          decoration: BoxDecoration(color: c.fill, borderRadius: BorderRadius.circular(AzmRadius.input)),
                          child: Text(formatRestSeconds(s), style: AzmType.rowNumberCompact.copyWith(color: c.textPrimary)),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AzmSpace.xs),
            ],
          ),
        ),
      );
    },
  );
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

/// Choice in the "finish with unticked sets" dialog.
enum FinishChoice { markAllDone, removeThem }

/// Finish confirmation when [unchecked] sets have no ✓ ([empty] of them have
/// no reps and are removed whatever the choice). "Mark all done" is offered
/// only when at least one of them can be logged.
Future<FinishChoice?> showFinishUncheckedDialog(BuildContext context, {required int unchecked, required int empty}) {
  final l = context.l10n;
  final canMark = unchecked > empty;
  return showDialog<FinishChoice>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) {
      final c = ctx.colors;
      final body = [
        l.workoutFinishUncheckedBody(unchecked, AzmNumbers.integer(unchecked)),
        if (empty > 0) l.workoutFinishEmptyNote(empty, AzmNumbers.integer(empty)),
      ].join('\n');
      return AlertDialog(
        title: Text(l.workoutFinishTitle, style: AzmType.cardTitle.copyWith(color: c.textPrimary)),
        content: Text(body, style: AzmType.body.copyWith(color: c.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.workoutCancel)),
          TextButton(
            key: const ValueKey('workoutFinishRemoveThem'),
            onPressed: () => Navigator.pop(ctx, FinishChoice.removeThem),
            style: TextButton.styleFrom(foregroundColor: c.destructiveText),
            child: Text(l.workoutFinishRemoveThem),
          ),
          if (canMark)
            TextButton(
              key: const ValueKey('workoutFinishMarkAllDone'),
              onPressed: () => Navigator.pop(ctx, FinishChoice.markAllDone),
              style: TextButton.styleFrom(foregroundColor: c.accent),
              child: Text(l.workoutFinishMarkAllDone),
            ),
        ],
      );
    },
  );
}

/// Android-only, shown once on the first rest timer: why "Alarms & reminders"
/// helps. Returns true when the user wants to open the system screen.
Future<bool> showExactAlarmSheet(BuildContext context) async {
  final l = context.l10n;
  final allow = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true, // long text / landscape / large fonts scroll instead of overflowing
    builder: (ctx) {
      final c = ctx.colors;
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.fromSTEB(AzmSpace.xxl, 0, AzmSpace.xxl, AzmSpace.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.alarm_rounded, color: c.accent, size: AzmSize.minTouchTarget),
              const SizedBox(height: AzmSpace.md),
              Text(l.workoutExactAlarmTitle, style: AzmType.cardTitle.copyWith(color: c.textPrimary)),
              const SizedBox(height: AzmSpace.xs),
              Text(l.workoutExactAlarmBody, style: AzmType.body.copyWith(color: c.textSecondary)),
              const SizedBox(height: AzmSpace.xxl),
              FilledButton(
                key: const ValueKey('workoutExactAlarmAllow'),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l.workoutExactAlarmAllow),
              ),
              const SizedBox(height: AzmSpace.xs),
              TextButton(
                key: const ValueKey('workoutExactAlarmLater'),
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.workoutExactAlarmLater),
              ),
            ],
          ),
        ),
      );
    },
  );
  return allow ?? false;
}
