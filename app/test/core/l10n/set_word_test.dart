import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// "ست" / "ستات" without a kasra reads as "lady / ladies" in Egyptian Arabic.
/// A workout set is always written "سِت" / "سِتات" (with ِ on the س), also with
/// prefixes/suffixes (السِت، والسِتات، سِتاتك). Words that merely contain the
/// letters (استك، ستة، ستين) are fine.
final _arabicWord = RegExp('[؀-ۿ]+');
final _diacritics = RegExp('[ً-ٰٟ]');
final _setWord = RegExp(r'^(و|ف|ب|ل|ك)?(ال|لل)?ستا?ت?(ك|ه|ها|ي|نا|كم|هم)?$');

/// The "set" words in [text] written WITHOUT the kasra on the س.
List<String> bareSetWords(String text) => [
      for (final m in _arabicWord.allMatches(text))
        if (_setWord.hasMatch(m[0]!.replaceAll(_diacritics, '')) && !_hasKasraOnSeen(m[0]!)) m[0]!,
    ];

bool _hasKasraOnSeen(String word) {
  final i = word.indexOf('س');
  return i >= 0 && i + 1 < word.length && word[i + 1] == 'ِ';
}

/// Every string in a decoded JSON value (map values, list items, nested).
Iterable<String> _strings(Object? json) sync* {
  if (json is String) {
    yield json;
  } else if (json is Map) {
    for (final v in json.values) {
      yield* _strings(v);
    }
  } else if (json is List) {
    for (final v in json) {
      yield* _strings(v);
    }
  }
}

void main() {
  test('detector: bare forms are caught, kasra forms and other words pass', () {
    expect(bareSetWords('ضيف ست'), ['ست']);
    expect(bareSetWords('٣ ستات · الستات · والست · ستاتك'), ['ستات', 'الستات', 'والست', 'ستاتك']);
    expect(bareSetWords('ضيف سِت · ٣ سِتات · السِتات · والسِت · سِتاتك'), isEmpty);
    expect(bareSetWords('استك · ستة · ستين · استاد'), isEmpty);
    expect(bareSetWords('بست'), ['بست']); // ب + ست ("with a set")
  });

  final arbFiles = [
    ...Directory('lib/core/l10n/arb_src').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('/ar.arb')),
    File('lib/core/l10n/arb/app_ar.arb'),
  ];

  test('found the Arabic ARB files', () => expect(arbFiles.length, greaterThanOrEqualTo(8)));

  for (final f in arbFiles) {
    test('no bare "ست/ستات" in ${f.path}', () {
      final json = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      final bad = <String>[
        for (final e in json.entries)
          for (final s in _strings(e.value))
            for (final w in bareSetWords(s)) '${e.key}: $w',
      ];
      expect(bad, isEmpty, reason: 'write "سِت" / "سِتات" (with kasra)');
    });
  }

  test('no bare "ست/ستات" in Arabic exercise names, programs and release notes', () {
    final bad = <String>[
      for (final path in ['../data/ar/exercise_names_ar.json', '../data/programs/programs.json'])
        for (final s in _strings(jsonDecode(File(path).readAsStringSync())))
          for (final w in bareSetWords(s)) '$path: $w',
      if (Directory('../docs/release_notes').existsSync())
        for (final f in Directory('../docs/release_notes').listSync().whereType<File>())
          for (final w in bareSetWords(f.readAsStringSync())) '${f.path}: $w',
    ];
    expect(bad, isEmpty, reason: 'write "سِت" / "سِتات" (with kasra)');
  });
}
