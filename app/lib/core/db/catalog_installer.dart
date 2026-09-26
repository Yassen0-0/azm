import 'dart:io';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sq;

import 'app_database.dart';

/// A full catalog snapshot (what tools/build_catalog.dart produces).
class CatalogData {
  const CatalogData({required this.version, required this.exercises, required this.programs});

  final int version;
  final List<Exercise> exercises;
  final List<CatalogProgram> programs;

  /// Reads a catalog.sqlite file written by tools/build_catalog.dart.
  factory CatalogData.fromSqliteFile(String path) {
    final db = sq.sqlite3.open(path, mode: sq.OpenMode.readOnly);
    try {
      final version = db.select('SELECT version FROM catalog_meta').single['version'] as int;
      final exercises = [
        for (final r in db.select('SELECT * FROM exercises ORDER BY id'))
          Exercise(
            id: r['id'] as String,
            nameEn: r['name_en'] as String,
            nameAr: r['name_ar'] as String?,
            aliasesAr: r['aliases_ar'] as String,
            bodyPart: r['body_part'] as String,
            target: r['target'] as String,
            secondaryMuscles: r['secondary_muscles'] as String,
            equipment: r['equipment'] as String,
            instructionsEn: r['instructions_en'] as String,
            instructionsAr: r['instructions_ar'] as String?,
            mediaId: r['media_id'] as String,
            searchNorm: r['search_norm'] as String,
          ),
      ];
      final programs = [
        for (final r in db.select('SELECT * FROM catalog_programs ORDER BY sort'))
          CatalogProgram(id: r['id'] as String, sort: r['sort'] as int, data: r['data'] as String),
      ];
      return CatalogData(version: version, exercises: exercises, programs: programs);
    } finally {
      db.close();
    }
  }
}

/// Installs / replaces the catalog tables. NEVER touches user tables.
class CatalogInstaller {
  CatalogInstaller(this.db);

  final AppDatabase db;

  static const _assetDb = 'assets/catalog/catalog.sqlite';
  static const _assetVersion = 'assets/catalog/catalog_version.txt';

  /// Installed catalog version, or null if none yet.
  Future<int?> installedVersion() async {
    final row = await db.select(db.catalogMeta).getSingleOrNull();
    return row?.version;
  }

  /// Replaces all catalog rows with [data] in ONE transaction if [data] is
  /// newer than what is installed (or nothing is installed). Returns true if
  /// it installed.
  Future<bool> installIfNewer(CatalogData data) async {
    final current = await installedVersion();
    if (current != null && current >= data.version) return false;
    await db.transaction(() async {
      await db.delete(db.exercises).go();
      await db.delete(db.catalogPrograms).go();
      await db.delete(db.catalogMeta).go();
      await db.batch((b) {
        b.insertAll(db.exercises, data.exercises);
        b.insertAll(db.catalogPrograms, data.programs);
        b.insert(db.catalogMeta, CatalogMetaData(version: data.version));
      });
    });
    return true;
  }

  /// App start: installs the catalog bundled in assets when it is newer.
  /// Only copies/opens the bundled DB when the cheap version check says so.
  Future<bool> installBundledIfNeeded({AssetBundle? bundle}) async {
    final assets = bundle ?? rootBundle;
    final bundledVersion = int.parse((await assets.loadString(_assetVersion)).trim());
    final current = await installedVersion();
    if (current != null && current >= bundledVersion) return false;

    final bytes = await assets.load(_assetDb);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/azm_catalog_$bundledVersion.sqlite');
    await file.writeAsBytes(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true);
    try {
      return await installIfNewer(CatalogData.fromSqliteFile(file.path));
    } finally {
      if (file.existsSync()) await file.delete();
    }
  }
}
