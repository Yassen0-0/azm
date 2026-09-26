import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/arabic_normalize.dart';
import 'app_database.dart';

/// Read access to the catalog: search, lookup, ready programs.
class CatalogRepository {
  CatalogRepository(this.db);

  final AppDatabase db;

  Future<Exercise?> exercise(String id) =>
      (db.select(db.exercises)..where((e) => e.id.equals(id))).getSingleOrNull();

  Future<List<Exercise>> exercisesByIds(Iterable<String> ids) =>
      (db.select(db.exercises)..where((e) => e.id.isIn(ids.toList()))).get();

  /// Ready-made programs as decoded JSON docs (format: docs/DATA.md).
  Future<List<Map<String, dynamic>>> programs() async {
    final rows = await (db.select(db.catalogPrograms)
          ..orderBy([(p) => OrderingTerm(expression: p.sort)]))
        .get();
    return [for (final r in rows) jsonDecode(r.data) as Map<String, dynamic>];
  }

  /// Bilingual search (Arabic, Egyptian slang aliases, English).
  ///
  /// Every normalized query token must be a substring of `search_norm`.
  /// Ranking: exact name/alias match → prefix match → substring, then English
  /// name. Empty query → all exercises by English name. Optional filters use
  /// dataset keys (`target`, `equipment`).
  Future<List<Exercise>> search(String query, {String? target, String? equipment}) async {
    final tokens = searchTokens(query);
    final q = db.select(db.exercises);
    for (final t in tokens) {
      q.where((e) => e.searchNorm.like('%${_escapeLike(t)}%', escapeChar: r'\'));
    }
    if (target != null) q.where((e) => e.target.equals(target));
    if (equipment != null) q.where((e) => e.equipment.equals(equipment));
    q.orderBy([(e) => OrderingTerm(expression: e.nameEn)]);
    final rows = await q.get();
    if (tokens.isEmpty) return rows;

    final needle = tokens.join(' ');
    final ranked = [for (final r in rows) (rank: _rank(r, needle), row: r)]
      ..sort((a, b) {
        final c = a.rank.compareTo(b.rank);
        return c != 0 ? c : a.row.nameEn.compareTo(b.row.nameEn);
      });
    return [for (final r in ranked) r.row];
  }

  static int _rank(Exercise e, String needle) {
    final names = <String>[
      normalizeForSearch(e.nameEn),
      if (e.nameAr != null) normalizeForSearch(e.nameAr!),
      for (final a in (jsonDecode(e.aliasesAr) as List).cast<String>()) normalizeForSearch(a),
    ];
    if (names.any((n) => n == needle)) return 0;
    if (names.any((n) => n.startsWith(needle))) return 1;
    return 2;
  }

  static String _escapeLike(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');
}

final catalogRepositoryProvider =
    Provider<CatalogRepository>((ref) => CatalogRepository(ref.watch(appDatabaseProvider)));
