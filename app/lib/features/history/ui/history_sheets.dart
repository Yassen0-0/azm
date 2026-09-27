import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/azm_theme.dart';
import '../../../core/widgets/azm_pressable.dart';

/// Bottom-sheet row: icon/leading + label (optionally destructive / selected).
class HistorySheetAction extends StatelessWidget {
  const HistorySheetAction({
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

Future<T?> showHistorySheet<T>(
  BuildContext context, {
  required String title,
  required List<Widget> Function(BuildContext) children,
}) =>
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


/// Confirmation dialog. Returns true on confirm.
Future<bool> historyConfirm(
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.historyCancel)),
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

/// Rename dialog. Returns the new name (trimmed, non-empty) or null.
Future<String?> showRenameDialog(BuildContext context, String current) =>
    showDialog<String>(context: context, useRootNavigator: true, builder: (_) => _RenameDialog(current: current));

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.current});

  final String current;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _text = TextEditingController(text: widget.current)
    ..selection = TextSelection(baseOffset: 0, extentOffset: widget.current.length);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _save() {
    final v = _text.text.trim();
    Navigator.pop(context, v.isEmpty ? null : v);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.historyRenameTitle, style: AzmType.cardTitle.copyWith(color: c.textPrimary)),
      content: TextField(
        controller: _text,
        autofocus: true,
        maxLength: 60,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _save(),
        style: AzmType.input.copyWith(color: c.textPrimary),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.historyCancel)),
        TextButton(
          onPressed: _save,
          style: TextButton.styleFrom(foregroundColor: c.accent),
          child: Text(l.historySave),
        ),
      ],
    );
  }
}
