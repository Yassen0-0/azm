import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// CLAUDE.md → Drift watch queries: every watched `customSelect` reads real
/// tables with a matching `readsFrom`, never dummy SQL like `SELECT 1`
/// (Drift shares streams with identical SQL whatever their readsFrom, so a
/// dummy query silently stole another screen's table set once).
void main() {
  test('every customSelect reads real tables and declares readsFrom', () {
    final offenders = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart') || f.path.endsWith('.g.dart') || f.path.contains('/l10n/gen/')) continue;
      final src = f.readAsStringSync();
      for (final m in RegExp(r'customSelect\(([\s\S]*?)\)\s*\.(watch|get)', multiLine: true).allMatches(src)) {
        final call = m.group(1)!;
        final watched = m.group(2) == 'watch';
        final sql = RegExp(r"'''([\s\S]*?)'''|'([^']*)'").firstMatch(call);
        final text = (sql?.group(1) ?? sql?.group(2) ?? '').toUpperCase();
        if (!RegExp(r'\bFROM\s+\w+').hasMatch(text)) offenders.add('${f.path}: no FROM <table> in "$text"');
        if (watched && !call.contains('readsFrom:')) offenders.add('${f.path}: watched query without readsFrom');
      }
    }
    expect(offenders, isEmpty);
  });
}
