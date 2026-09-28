// Builds the read-only exercise catalog shipped with the app.
//
//   source ./env.sh && (cd tools && dart run build_catalog.dart)
//   (or: tools/build_catalog.sh)
//
// Inputs : data/raw/exercises.json, data/ar/exercise_names_ar.json,
//          data/programs/programs.json, data/hidden_exercises.json,
//          data/{equipment,place,muscle}_mapping.json (library filters)
// Outputs: data/catalog/catalog.sqlite            (gitignored build output)
//          data/catalog/catalog_version.json      (committed: version + input hash)
//          app/assets/catalog/catalog.sqlite      (bundled into the app)
//          app/assets/catalog/catalog_version.txt (bundled; cheap version check)
//          app/lib/features/exercises/data/exercise_filters_data.dart
//              (generated Dart: the three filter mappings, merged, as JSON)
//
//   --check : validate the inputs and print coverage + the filter report
//             (unmapped dataset values, results per filter), write NOTHING.
//
// The filter mappings don't change the SQLite catalog (the app classifies
// exercises from their dataset keys at runtime), so they are not part of the
// catalog version hash: editing a mapping never forces a catalog reinstall.
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
const int builderRevision = 2; // 2: `hidden` column

void main(List<String> args) {
  final root = Directory.fromUri(Platform.script.resolve('..')).absolute.path;
  String p(String rel) => '$root/$rel';

  final raw = (jsonDecode(File(p('data/raw/exercises.json')).readAsStringSync()) as List)
      .cast<Map<String, dynamic>>();
  final arFile = File(p('data/ar/exercise_names_ar.json'));
  final ar = arFile.existsSync()
      ? (jsonDecode(arFile.readAsStringSync()) as Map<String, dynamic>)
      : <String, dynamic>{};
  final hiddenFile = File(p('data/hidden_exercises.json'));
  // Hidden id → the visible id it duplicates (docs/review/duplicates.md).
  final hidden = hiddenFile.existsSync()
      ? ((jsonDecode(hiddenFile.readAsStringSync()) as Map<String, dynamic>)['hidden'] as Map<String, dynamic>)
          .cast<String, String>()
      : <String, String>{};
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
  hidden.forEach((id, keep) {
    if (!byId.containsKey(id)) errors.add('hidden_exercises.json: unknown id $id');
    if (!byId.containsKey(keep)) errors.add('hidden_exercises.json: $id duplicates unknown id $keep');
    if (hidden.containsKey(keep)) errors.add('hidden_exercises.json: $id duplicates $keep, which is hidden too');
    final nameA = (ar[id] as Map<String, dynamic>?)?['ar'];
    final nameK = (ar[keep] as Map<String, dynamic>?)?['ar'];
    if (nameA != nameK) errors.add('hidden_exercises.json: $id ("$nameA") and $keep ("$nameK") must share one Arabic name');
  });
  final programs = (programsDoc['programs'] as List).cast<Map<String, dynamic>>();
  final programIds = <String>{};
  for (final prog in programs) {
    if (!programIds.add(prog['id'] as String)) errors.add('programs.json: duplicate id ${prog['id']}');
    for (final r in (prog['routines'] as List).cast<Map<String, dynamic>>()) {
      for (final x in (r['exercises'] as List).cast<Map<String, dynamic>>()) {
        final id = x['exercise_id'] as String;
        if (!byId.containsKey(id)) errors.add('programs.json: ${r['id']} uses unknown exercise $id');
        if (hidden.containsKey(id)) errors.add('programs.json: ${r['id']} uses hidden exercise $id');
      }
    }
  }
  final filters = buildFilters(p, byId, hidden, errors);
  // Warnings (not fatal): the same Arabic primary name on two VISIBLE exercises.
  final warnings = <String>[];
  final idsByName = <String, List<String>>{};
  ar.forEach((id, v) {
    if (hidden.containsKey(id)) return;
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
        '($reviewed reviewed), ${byId.length - ar.length} still English-only, ${hidden.length} hidden, '
        '${warnings.length} same-name warnings among visible exercises. Nothing written (--check).');
    for (final w in warnings) {
      stdout.writeln('  warning: $w');
    }
    stdout.writeln(filters.report);
    return;
  }

  // ---- Version --------------------------------------------------------------
  final hash = sha256.convert(utf8.encode([
    'rev:$builderRevision',
    File(p('data/raw/exercises.json')).readAsStringSync(),
    arFile.existsSync() ? arFile.readAsStringSync() : '',
    File(p('data/programs/programs.json')).readAsStringSync(),
    hiddenFile.existsSync() ? hiddenFile.readAsStringSync() : '',
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
      search_norm TEXT NOT NULL,
      hidden INTEGER NOT NULL DEFAULT 0
    );
    CREATE TABLE catalog_programs (
      id TEXT NOT NULL PRIMARY KEY,
      sort INTEGER NOT NULL,
      data TEXT NOT NULL
    );
  ''');
  db.execute('BEGIN');
  db.execute('INSERT INTO catalog_meta (version) VALUES (?)', [version]);
  final ins = db.prepare('INSERT INTO exercises VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)');
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
      hidden.containsKey(id) ? 1 : 0,
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
  File(p(filtersDart)).writeAsStringSync(filtersDartSource(filters.asset));

  final kb = (out.lengthSync() / 1024).round();
  stdout.writeln('catalog v$version${hash == previousHash ? ' (unchanged)' : ''}: '
      '${sorted.length} exercises (${hidden.length} hidden), ${ar.length} with Arabic names, '
      '${programs.length} programs, $kb KB → data/catalog/ + app/assets/catalog/');
  stdout.writeln(filters.report);
}

/// Generated Dart holding the merged filter mappings (the app reads it
/// synchronously; no asset loading).
const filtersDart = 'app/lib/features/exercises/data/exercise_filters_data.dart';

String filtersDartSource(Map<String, dynamic> asset) {
  final json = const JsonEncoder.withIndent(' ').convert(asset);
  if (json.contains("'''")) throw StateError('mapping JSON must not contain triple quotes');
  return '// GENERATED by tools/build_catalog.dart from data/{equipment,place,muscle}_mapping.json.\n'
      '// Do not edit: change the mapping files, then run tools/build_catalog.sh.\n'
      '// Read by ExerciseFilterMapping (exercise_filters.dart).\n'
      '\n'
      "const String exerciseFiltersJson = r'''\n$json\n''';\n";
}

/// Validates data/{equipment,place,muscle}_mapping.json against the dataset
/// (errors go to [errors]) and returns the merged app asset plus a
/// human-readable report: dataset values without a mapping, and how many
/// VISIBLE exercises each filter card matches.
({Map<String, dynamic> asset, String report}) buildFilters(
  String Function(String) p,
  Map<String, Map<String, dynamic>> byId,
  Map<String, String> hidden,
  List<String> errors,
) {
  Map<String, dynamic> read(String rel) {
    final f = File(p(rel));
    if (!f.existsSync()) {
      errors.add('$rel is missing');
      return {};
    }
    return jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
  }

  final eqDoc = read('data/equipment_mapping.json');
  final placeDoc = read('data/place_mapping.json');
  final muscleDoc = read('data/muscle_mapping.json');
  final groups = ((eqDoc['groups'] as List?) ?? const []).cast<String>();
  final eqMap = ((eqDoc['map'] as Map?) ?? const {}).cast<String, String>();
  final places = ((placeDoc['places'] as Map?) ?? const {})
      .map((k, v) => MapEntry(k as String, (v as List).cast<String>()));
  final sections = ((muscleDoc['sections'] as Map?) ?? const {})
      .map((k, v) => MapEntry(k as String, (v as List).cast<String>()));
  final byTarget = ((muscleDoc['target'] as Map?) ?? const {}).cast<String, String>();
  final byBodyPart = ((muscleDoc['body_part'] as Map?) ?? const {}).cast<String, String>();
  final fallback = muscleDoc['fallback'] as String? ?? '';
  final fullBody = ((muscleDoc['full_body'] as List?) ?? const []).cast<String>();
  final muscles = [for (final g in sections.values) ...g];

  Set<String> values(String field) => {for (final e in byId.values) e[field] as String};
  final equipmentValues = values('equipment'), targets = values('target'), bodyParts = values('body_part');

  if (groups.toSet().length != groups.length) errors.add('equipment_mapping.json: duplicate group');
  for (final v in equipmentValues) {
    if (!eqMap.containsKey(v)) errors.add('equipment_mapping.json: dataset equipment "$v" is not mapped');
  }
  eqMap.forEach((k, g) {
    if (!equipmentValues.contains(k)) errors.add('equipment_mapping.json: "$k" is not a dataset equipment value');
    if (!groups.contains(g)) errors.add('equipment_mapping.json: "$k" → unknown group "$g"');
  });
  if (!places.containsKey('gym')) errors.add('place_mapping.json: "gym" is missing');
  places.forEach((place, gs) {
    for (final g in gs) {
      if (!groups.contains(g)) errors.add('place_mapping.json: $place lists unknown equipment group "$g"');
    }
  });
  for (final g in groups) {
    if (!(places['gym'] ?? const []).contains(g)) errors.add('place_mapping.json: gym must include every group ("$g" missing)');
  }
  if (muscles.toSet().length != muscles.length) errors.add('muscle_mapping.json: a group is in two sections');
  for (final t in targets) {
    if (!byTarget.containsKey(t)) errors.add('muscle_mapping.json: dataset target "$t" is not mapped');
  }
  for (final e in [...byTarget.entries, ...byBodyPart.entries, MapEntry('fallback', fallback)]) {
    if (!muscles.contains(e.value)) errors.add('muscle_mapping.json: "${e.key}" → unknown group "${e.value}"');
  }
  if (!muscles.contains('full_body')) errors.add('muscle_mapping.json: no "full_body" group');
  for (final id in fullBody) {
    if (!byId.containsKey(id)) errors.add('muscle_mapping.json: full_body lists unknown id $id');
    if (hidden.containsKey(id)) errors.add('muscle_mapping.json: full_body lists hidden id $id');
  }

  final asset = <String, dynamic>{
    'version': 1,
    'equipment': {'groups': groups, 'map': eqMap},
    'place': {'places': places},
    'muscle': {
      'sections': sections,
      'target': byTarget,
      'body_part': byBodyPart,
      'fallback': fallback,
      'full_body': fullBody,
    },
  };

  // Report: counts over VISIBLE exercises (what the library lists).
  final visible = [for (final e in byId.values) if (!hidden.containsKey(e['id'])) e];
  String equipmentOf(Map<String, dynamic> e) => eqMap[e['equipment']] ?? 'other';
  Set<String> musclesOf(Map<String, dynamic> e) => {
        byTarget[e['target']] ?? byBodyPart[e['body_part']] ?? fallback,
        if (fullBody.contains(e['id'])) 'full_body',
      };
  final out = StringBuffer('Filters (${visible.length} visible exercises):\n');
  final unmappedTargets = targets.where((t) => !byTarget.containsKey(t)).toList()..sort();
  final unmappedBodyParts = bodyParts.where((b) => !byBodyPart.containsKey(b)).toList()..sort();
  final unmappedEquipment = equipmentValues.where((v) => !eqMap.containsKey(v)).toList()..sort();
  out.writeln('  unmapped equipment: ${unmappedEquipment.isEmpty ? 'none' : unmappedEquipment.join(', ')}');
  out.writeln('  unmapped targets: ${unmappedTargets.isEmpty ? 'none' : unmappedTargets.join(', ')}');
  out.writeln('  body_part values without a fallback (every exercise still maps by target): '
      '${unmappedBodyParts.isEmpty ? 'none' : unmappedBodyParts.join(', ')}');
  out.writeln('  place: ${[for (final pl in places.entries) '${pl.key} ${visible.where((e) => pl.value.contains(equipmentOf(e))).length}'].join(' · ')}');
  for (final sec in sections.entries) {
    out.writeln('  muscle/${sec.key}: '
        '${[for (final g in sec.value) '$g ${visible.where((e) => musclesOf(e).contains(g)).length}'].join(' · ')}');
  }
  out.write('  equipment: ${[for (final g in groups) '$g ${visible.where((e) => equipmentOf(e) == g).length}'].join(' · ')}');
  return (asset: asset, report: out.toString());
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
