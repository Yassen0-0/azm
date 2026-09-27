// Builds the read-only exercise catalog shipped with the app.
//
//   source ./env.sh && (cd tools && dart run build_catalog.dart)
//   (or: tools/build_catalog.sh)
//
// Inputs : data/raw/exercises.json, data/ar/exercise_names_ar.json,
//          data/programs/programs.json
// Outputs: data/catalog/catalog.sqlite            (gitignored build output)
//          data/catalog/catalog_version.json      (committed: version + input hash)
//          app/assets/catalog/catalog.sqlite      (bundled into the app)
//          app/assets/catalog/catalog_version.txt (bundled; cheap version check)
//
//   --check : validate the inputs and print coverage, write NOTHING (for the
//             Arabic-names window; the integrator rebuilds the asset at merge).
//
// The version is bumped ONLY when the input hash changes. The app replaces its
// catalog tables when the bundled version is newer (docs/DATA.md).
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:sqlite3/sqlite3.dart';

// Shared with the app. Must stay import-free (see that file's header).
// ignore: avoid_relative_lib_imports — deliberate: one normalizer for app + tool
import '../app/lib/core/utils/arabic_normalize.dart';

/// Bump when the builder's OUTPUT logic changes (forces a new catalog version
/// even if the input files did not change).
const int builderRevision = 1;

void main(List<String> args) {
  final root = Directory.fromUri(Platform.script.resolve('..')).absolute.path;
  String p(String rel) => '$root/$rel';

  final raw = (jsonDecode(File(p('data/raw/exercises.json')).readAsStringSync()) as List)
      .cast<Map<String, dynamic>>();
  final arFile = File(p('data/ar/exercise_names_ar.json'));
  final ar = arFile.existsSync()
      ? (jsonDecode(arFile.readAsStringSync()) as Map<String, dynamic>)
      : <String, dynamic>{};
  final programsDoc =
      jsonDecode(File(p('data/programs/programs.json')).readAsStringSync()) as Map<String, dynamic>;

  // ---- Validate -------------------------------------------------------------
  final errors = <String>[];
  final byId = <String, Map<String, dynamic>>{};
  for (final e in raw) {
    final id = e['id'] as String;
    if (byId.containsKey(id)) errors.add('duplicate exercise id $id');
    byId[id] = e;
  }
  ar.forEach((id, v) {
    if (!byId.containsKey(id)) errors.add('exercise_names_ar.json: unknown id $id');
    final m = v as Map<String, dynamic>;
    if ((m['ar'] as String?)?.trim().isEmpty ?? true) errors.add('exercise_names_ar.json: $id has no "ar"');
    if (m['aliases'] is! List) errors.add('exercise_names_ar.json: $id "aliases" must be a list');
    if (m['reviewed'] is! bool) errors.add('exercise_names_ar.json: $id "reviewed" must be a bool');
  });
  final programs = (programsDoc['programs'] as List).cast<Map<String, dynamic>>();
  final programIds = <String>{};
  for (final prog in programs) {
    if (!programIds.add(prog['id'] as String)) errors.add('programs.json: duplicate id ${prog['id']}');
    for (final r in (prog['routines'] as List).cast<Map<String, dynamic>>()) {
      for (final x in (r['exercises'] as List).cast<Map<String, dynamic>>()) {
        final id = x['exercise_id'] as String;
        if (!byId.containsKey(id)) errors.add('programs.json: ${r['id']} uses unknown exercise $id');
      }
    }
  }
  // Warnings (not fatal): the same Arabic primary name on two exercises.
  final warnings = <String>[];
  final idsByName = <String, List<String>>{};
  ar.forEach((id, v) {
    final name = normalizeForSearch((v as Map<String, dynamic>)['ar'] as String? ?? '');
    if (name.isNotEmpty) (idsByName[name] ??= []).add(id);
  });
  idsByName.forEach((name, ids) {
    if (ids.length > 1) warnings.add('same Arabic name on ${ids.join(', ')}');
  });
  if (errors.isNotEmpty) {
    stderr.writeln('Catalog validation FAILED:\n  ${errors.join('\n  ')}');
    exit(1);
  }
  if (args.contains('--check')) {
    final reviewed = ar.values.where((v) => (v as Map<String, dynamic>)['reviewed'] == true).length;
    stdout.writeln('Catalog inputs OK: ${byId.length} exercises, ${ar.length} with Arabic names '
        '($reviewed reviewed), ${byId.length - ar.length} still English-only. Nothing written (--check).');
    for (final w in warnings) {
      stdout.writeln('  warning: $w');
    }
    return;
  }

  // ---- Version --------------------------------------------------------------
  final hash = sha256.convert(utf8.encode([
    'rev:$builderRevision',
    File(p('data/raw/exercises.json')).readAsStringSync(),
    arFile.existsSync() ? arFile.readAsStringSync() : '',
    File(p('data/programs/programs.json')).readAsStringSync(),
  ].join('\u0000'))).toString();
  final versionFile = File(p('data/catalog/catalog_version.json'));
  var version = 0;
  var previousHash = '';
  if (versionFile.existsSync()) {
    final v = jsonDecode(versionFile.readAsStringSync()) as Map<String, dynamic>;
    version = v['version'] as int;
    previousHash = v['input_sha256'] as String;
  }
  if (hash != previousHash) version++;

  // ---- Write SQLite ---------------------------------------------------------
  final out = File(p('data/catalog/catalog.sqlite'));
  out.parent.createSync(recursive: true);
  if (out.existsSync()) out.deleteSync();
  final db = sqlite3.open(out.path);
  db.execute('''
    CREATE TABLE catalog_meta (version INTEGER NOT NULL);
    CREATE TABLE exercises (
      id TEXT NOT NULL PRIMARY KEY,
      name_en TEXT NOT NULL,
      name_ar TEXT,
      aliases_ar TEXT NOT NULL,
      body_part TEXT NOT NULL,
      target TEXT NOT NULL,
      secondary_muscles TEXT NOT NULL,
      equipment TEXT NOT NULL,
      instructions_en TEXT NOT NULL,
      instructions_ar TEXT,
      media_id TEXT NOT NULL,
      search_norm TEXT NOT NULL
    );
    CREATE TABLE catalog_programs (
      id TEXT NOT NULL PRIMARY KEY,
      sort INTEGER NOT NULL,
      data TEXT NOT NULL
    );
  ''');
  db.execute('BEGIN');
  db.execute('INSERT INTO catalog_meta (version) VALUES (?)', [version]);
  final ins = db.prepare('INSERT INTO exercises VALUES (?,?,?,?,?,?,?,?,?,?,?,?)');
  final sorted = byId.keys.toList()..sort();
  for (final id in sorted) {
    final e = byId[id]!;
    final names = ar[id] as Map<String, dynamic>?;
    final nameEn = displayNameEn(e['name'] as String);
    final nameAr = (names?['ar'] as String?)?.trim();
    final aliases = ((names?['aliases'] as List?) ?? const []).cast<String>().map((a) => a.trim()).toList();
    final steps = ((e['instruction_steps'] as Map)['en'] as List).cast<String>();
    ins.execute([
      id,
      nameEn,
      nameAr,
      jsonEncode(aliases),
      e['body_part'],
      e['target'],
      jsonEncode(e['secondary_muscles']),
      e['equipment'],
      jsonEncode(steps),
      null,
      e['media_id'],
      normalizeForSearch([nameEn, ?nameAr, ...aliases].join(' ')),
    ]);
  }
  ins.close();
  final insP = db.prepare('INSERT INTO catalog_programs VALUES (?,?,?)');
  for (var i = 0; i < programs.length; i++) {
    insP.execute([programs[i]['id'], i, jsonEncode(programs[i])]);
  }
  insP.close();
  db.execute('COMMIT');
  db.execute('VACUUM');
  db.close();

  versionFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert({'version': version, 'input_sha256': hash})}\n',
  );

  // ---- Copy into app assets ------------------------------------------------
  final assets = Directory(p('app/assets/catalog'))..createSync(recursive: true);
  out.copySync('${assets.path}/catalog.sqlite');
  File('${assets.path}/catalog_version.txt').writeAsStringSync('$version\n');

  final kb = (out.lengthSync() / 1024).round();
  stdout.writeln('catalog v$version${hash == previousHash ? ' (unchanged)' : ''}: '
      '${sorted.length} exercises, ${ar.length} with Arabic names, '
      '${programs.length} programs, $kb KB → data/catalog/ + app/assets/catalog/');
}

/// Dataset names are lowercase ("barbell bench press"); show Title Case
/// ("Barbell Bench Press"), fix known encoding glitches, keep acronyms.
String displayNameEn(String raw) {
  const acronyms = {'ez': 'EZ', 'pov': 'POV', 'rdl': 'RDL', 'v.': 'V.'};
  final cleaned = raw.replaceAll('в°', '°').replaceAll(RegExp(r'\s+'), ' ').trim();
  return cleaned.replaceAllMapped(RegExp(r"[A-Za-z][A-Za-z.']*"), (m) {
    final w = m[0]!;
    final lower = w.toLowerCase();
    if (acronyms.containsKey(lower)) return acronyms[lower]!;
    return w[0].toUpperCase() + w.substring(1);
  });
}
