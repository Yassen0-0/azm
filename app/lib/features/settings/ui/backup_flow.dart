import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/azm_theme.dart';
import '../data/app_settings.dart';
import '../data/app_version.dart';
import '../data/backup/backup_codec.dart';
import '../data/backup/backup_files.dart';
import '../data/backup/backup_service.dart';

/// Builds the backup file for "now" and opens the share sheet.
/// Returns false (after telling the user) when it failed.
Future<bool> runBackupExport(BuildContext context, WidgetRef ref, {Rect? origin}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final failed = context.l10n.settingsExportFailed;
  try {
    final now = DateTime.now();
    final version = await ref.read(appVersionProvider.future);
    final text = await ref.read(backupServiceProvider).exportText(now: now.toUtc(), appVersion: version.full);
    await ref.read(backupFilesProvider).share(fileName: backupFileName(now), text: text, origin: origin);
    return true;
  } catch (_) {
    messenger?.showSnackBar(SnackBar(content: Text(failed)));
    return false;
  }
}

/// Pick → validate (nothing touched yet) → confirm with counts → replace
/// everything in one transaction. Every failure leaves the data unchanged.
Future<void> runBackupImport(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final service = ref.read(backupServiceProvider);
  final messenger = ScaffoldMessenger.maybeOf(context);

  if (await service.hasActiveWorkout()) {
    if (context.mounted) await showImportErrorDialog(context, message: l.settingsImportErrorActive);
    return;
  }

  final BackupContents contents;
  try {
    final text = await ref.read(backupFilesProvider).pickText();
    if (text == null) return; // cancelled
    contents = decodeBackup(text);
  } on BackupException catch (e) {
    if (context.mounted) await showImportErrorDialog(context, message: importErrorMessage(l, e.error));
    return;
  } catch (_) {
    if (context.mounted) await showImportErrorDialog(context, message: l.settingsImportErrorRead);
    return;
  }

  if (!context.mounted || !await showImportConfirmDialog(context, contents)) return;

  try {
    await service.restore(contents);
  } on ActiveWorkoutBlocksImport {
    if (context.mounted) await showImportErrorDialog(context, message: l.settingsImportErrorActive);
    return;
  } catch (_) {
    // The transaction rolled back: nothing changed.
    if (context.mounted) await showImportErrorDialog(context, message: l.settingsImportErrorCorrupt);
    return;
  }
  await ref.read(appSettingsProvider.notifier).reload();
  // Confirm in the restored language: wait for the rebuild it triggers.
  await WidgetsBinding.instance.endOfFrame;
  final done = context.mounted ? context.l10n.settingsImportDone : l.settingsImportDone;
  messenger?.showSnackBar(SnackBar(content: Text(done)));
}

String importErrorMessage(AppLocalizations l, BackupError error) => switch (error) {
      BackupError.notJson => l.settingsImportErrorNotJson,
      BackupError.notAzmBackup => l.settingsImportErrorNotAzm,
      BackupError.newerVersion => l.settingsImportErrorNewer,
      BackupError.corrupt => l.settingsImportErrorCorrupt,
    };

/// "Restore this backup?" with its date and counts. True on confirm.
Future<bool> showImportConfirmDialog(BuildContext context, BackupContents contents) async {
  final l = context.l10n;
  final tag = Localizations.localeOf(context).toLanguageTag();
  final date = (DateFormat.yMMMd(tag).add_Hm()..useNativeDigits = false).format(contents.exportedAt.toLocal());
  final ok = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) {
      final c = ctx.colors;
      final body = AzmType.body.copyWith(color: c.textSecondary);
      final strong = AzmType.body.copyWith(color: c.textPrimary);
      return AlertDialog(
        title: Text(l.settingsImportConfirmTitle, style: AzmType.cardTitle.copyWith(color: c.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.settingsImportFrom(date), style: strong),
            const SizedBox(height: AzmSpace.xs),
            Text(l.settingsImportCountRoutines(AzmNumbers.integer(contents.routines.length)), style: body),
            Text(l.settingsImportCountWorkouts(AzmNumbers.integer(contents.workouts.length)), style: body),
            Text(l.settingsImportCountSets(AzmNumbers.integer(contents.workoutSets.length)), style: body),
            const SizedBox(height: AzmSpace.md),
            Text(l.settingsImportWarning, style: AzmType.body.copyWith(color: c.destructiveText)),
          ],
        ),
        actions: [
          TextButton(
            key: const ValueKey('settings-import-cancel'),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.settingsCancel),
          ),
          TextButton(
            key: const ValueKey('settings-import-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: c.destructiveText),
            child: Text(l.settingsImportConfirm),
          ),
        ],
      );
    },
  );
  return ok ?? false;
}

/// Import error: what went wrong + "your data is unchanged".
Future<void> showImportErrorDialog(BuildContext context, {required String message}) {
  final l = context.l10n;
  return showDialog<void>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) {
      final c = ctx.colors;
      return AlertDialog(
        title: Text(l.settingsImportErrorTitle, style: AzmType.cardTitle.copyWith(color: c.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: AzmType.body.copyWith(color: c.textPrimary)),
            const SizedBox(height: AzmSpace.xs),
            Text(l.settingsImportUnchanged, style: AzmType.body.copyWith(color: c.textSecondary)),
          ],
        ),
        actions: [
          TextButton(
            key: const ValueKey('settings-import-error-ok'),
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.settingsOk),
          ),
        ],
      );
    },
  );
}
