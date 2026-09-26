import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/catalog_repository.dart';
import '../../../core/utils/arabic_normalize.dart';
import 'exercise_library.dart';

/// In-memory copy of the catalog for typing-speed search.
///
/// `CatalogRepository.search` re-reads and re-ranks full rows (instructions
/// included) on every call, which measured 75–236 ms for broad queries on the
/// debug Android emulator. The catalog only changes at app start
/// (CatalogInstaller), so the library loads it ONCE and filters here, with the
/// exact matching and ranking of `CatalogRepository.search` (docs/DATA.md →
/// Matching); a unit test checks both give the same results.
class ExerciseSearchIndex {
  ExerciseSearchIndex(Iterable<Exercise> exercises)
    : _entries = [for (final e in exercises) _Entry(e)]..sort((a, b) => a.e.nameEn.compareTo(b.e.nameEn));

  static Future<ExerciseSearchIndex> load(CatalogRepository repo) async => ExerciseSearchIndex(await repo.search(''));

  final List<_Entry> _entries;

  int get length => _entries.length;

  List<Exercise> search(ExerciseQuery query) {
    final tokens = searchTokens(query.text);
    final matches = [
      for (final x in _entries)
        if ((query.target == null || x.e.target == query.target) &&
            (query.equipment == null || x.e.equipment == query.equipment) &&
            tokens.every(x.norm.contains))
          x,
    ];
    if (tokens.isEmpty) return [for (final x in matches) x.e];

    final needle = tokens.join(' ');
    final ranked = [for (final x in matches) (rank: x.rank(needle), x: x)]
      ..sort((a, b) {
        final c = a.rank.compareTo(b.rank);
        return c != 0 ? c : a.x.e.nameEn.compareTo(b.x.e.nameEn);
      });
    return [for (final r in ranked) r.x.e];
  }
}

class _Entry {
  _Entry(this.e)
    : norm = e.searchNorm,
      names = [
        normalizeForSearch(e.nameEn),
        if (e.nameAr != null) normalizeForSearch(e.nameAr!),
        for (final a in (jsonDecode(e.aliasesAr) as List).cast<String>()) normalizeForSearch(a),
      ];

  final Exercise e;
  final String norm;
  final List<String> names;

  /// 0 exact name/alias, 1 prefix, 2 substring (same as CatalogRepository).
  int rank(String needle) {
    if (names.any((n) => n == needle)) return 0;
    if (names.any((n) => n.startsWith(needle))) return 1;
    return 2;
  }
}

/// Loaded once per app run (the catalog is only replaced before runApp).
final exerciseSearchIndexProvider = FutureProvider<ExerciseSearchIndex>(
  (ref) => ExerciseSearchIndex.load(ref.watch(catalogRepositoryProvider)),
  retry: (_, _) => null,
);
