import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Rect;

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'backup_codec.dart';

/// The platform side of backups: hand a file to the share sheet, pick a file.
/// Overridden in tests and screenshot runs (no system UI there).
abstract interface class BackupFiles {
  /// Writes [text] to a temporary file named [fileName] and opens the system
  /// share sheet for it. [origin] anchors the sheet on iPad.
  Future<void> share({required String fileName, required String text, Rect? origin});

  /// Lets the user pick a file and returns its text, or null if cancelled.
  /// Throws [BackupException] (`notJson`) when the file is not UTF-8 text.
  Future<String?> pickText();
}

class PlatformBackupFiles implements BackupFiles {
  const PlatformBackupFiles();

  @override
  Future<void> share({required String fileName, required String text, Rect? origin}) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(text, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json', name: fileName)],
        sharePositionOrigin: origin,
      ),
    );
  }

  @override
  Future<String?> pickText() async {
    // Any type: many Android providers label .json as octet-stream, which a
    // json-only filter would grey out. The content is validated anyway.
    final picked = await FilePicker.pickFile();
    if (picked == null) return null;
    final bytes = await picked.readAsBytes();
    try {
      return utf8.decode(bytes);
    } on FormatException catch (e) {
      throw BackupException(BackupError.notJson, e.message);
    }
  }
}

final backupFilesProvider = Provider<BackupFiles>((ref) => const PlatformBackupFiles());
