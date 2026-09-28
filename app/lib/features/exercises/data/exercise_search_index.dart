import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/catalog_repository.dart';
import '../../../core/utils/arabic_normalize.dart';
import 'exercise_filters.dart';
import 'exercise_library.dart';

/// In-memory copy of the catalog for typing-speed search.
///
/// `CatalogRepository.search` re-reads and re-ranks full rows (instructions
/// included) on every call, which measured 75–236 ms for broad queries on the
/// debug Android emulator. The catalog only changes at app start
/// (CatalogInstaller), so the library loads it ONCE and filters here, with the
/// exact matching and ranking of `CatalogRepository.search` (docs/DATA.md →
/// Matching); a unit test checks both give the same results.
///
/// The filter bar (Place / Muscle Group / Equipment, [ExerciseFilters]) is
/// applied here too, from tags precomputed once per exercise with the
/// bundled [ExerciseFilterMapping]: OR within a type, AND across types and
/// with the search text.
class ExerciseSearchIndex {
  ExerciseSearchIndex(Iterable<Exercise> exercises, {this.mapping})
    : _entries = [for (final e in exercises) _Entry(e, mapping?.tagsOf(e))]
        ..sort((a, b) => a.e.nameEn.compareTo(b.e.nameEn));

  static Future<ExerciseSearchIndex> load(CatalogRepository repo, {ExerciseFilterMapping? mapping}) async =>
      ExerciseSearchIndex(await repo.search(''), mapping: mapping);

  /// Null = no filter mapping (then any non-empty [ExerciseFilters] matches nothing).
  final ExerciseFilterMapping? mapping;
  final List<_Entry> _entries;

  int get length => _entries.length;

  List<_Entry> _matches(ExerciseQuery query, List<String> tokens) {
    final f = query.filters;
    return [
      for (final x in _entries)
        if ((query.target == null || x.e.target == query.target) &&
            (query.equipment == null || x.e.equipment == query.equipment) &&
            (f.isEmpty || (x.tags != null && f.matches(x.tags!))) &&
            tokens.every(x.norm.contains))
          x,
    ];
  }

  /// Number of results [query] would list (the sheets' live "Show N results").
  int count(ExerciseQuery query) => _matches(query, searchTokens(query.text)).length;

  List<Exercise> search(ExerciseQuery query) {
    final tokens = searchTokens(query.text);
    final matches = _matches(query, tokens);
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
  _Entry(this.e, this.tags)
    : norm = e.searchNorm,
      names = [
        normalizeForSearch(e.nameEn),
        if (e.nameAr != null) normalizeForSearch(e.nameAr!),
        for (final a in (jsonDecode(e.aliasesAr) as List).cast<String>()) normalizeForSearch(a),
      ];

  final Exercise e;
  final ExerciseTags? tags;
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
  (ref) async => ExerciseSearchIndex.load(
    ref.watch(catalogRepositoryProvider),
    mapping: ref.watch(exerciseFilterMappingProvider),
  ),
  retry: (_, _) => null,
);
