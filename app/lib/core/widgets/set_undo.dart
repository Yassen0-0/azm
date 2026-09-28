import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/azm_theme.dart';

/// "Set deleted · Undo" after a set is deleted (swipe or long-press menu),
/// shared by the live workout, past workout editing and the routine editor.
///
/// The set is already gone from the DB when this shows (every change is
/// persisted at once), so nothing ever counts it; [onUndo] puts the same row
/// back. Stays [AzmMotion.undoWindow] (~4 s), then disappears on its own; a
/// second delete replaces it.
void showSetDeletedSnackBar(BuildContext context, {required Future<void> Function() onUndo}) {
  final l = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  // Remove (not hide): the previous snackbar's Undo must not stay tappable
  // while it animates out; the new one targets the latest deletion.
  messenger
    ..removeCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        key: setDeletedSnackBarKey,
        content: Text(l.commonSetDeleted),
        duration: AzmMotion.undoWindow,
        persist: false,
        action: SnackBarAction(label: l.commonUndo, onPressed: () => onUndo()),
      ),
    );
}

/// Removes the undo snackbar (e.g. the screen is leaving for good).
void hideSetDeletedSnackBar(BuildContext context) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger?.hideCurrentSnackBar();
}

/// Key of the snackbar (tests).
const setDeletedSnackBarKey = ValueKey('setDeletedSnackBar');
