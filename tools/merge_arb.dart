// Merges per-owner ARB fragments into the two files gen-l10n reads, so parallel
// feature windows never edit the same ARB file.
//
//   tools/gen_l10n.sh        (runs this, then `flutter gen-l10n`)
//
// Sources (one folder per owner, each with ar.arb + en.arb):
//   app/lib/core/l10n/arb_src/<owner>/ar.arb   Arabic = template: values + "@key" metadata
//   app/lib/core/l10n/arb_src/<owner>/en.arb   English: values only
// Output (GENERATED — never edit by hand):
//   app/lib/core/l10n/arb/app_ar.arb, app/lib/core/l10n/arb/app_en.arb
//
// Rules enforced (build fails otherwise):
// - every key of owner X starts with X in camelCase (`workoutStartButton`);
//   the `core` owner may use the prefixes app / shell / common;
// - no key defined twice; ar and en of an owner have exactly the same keys;
// - every Arabic key has an "@key" entry with a "description".
import 'dart:convert';
import 'dart:io';

const corePrefixes = ['app', 'shell', 'common'];

void main() {
  final root = Directory.fromUri(Platform.script.resolve('..')).absolute.path;
  final src = Directory('${root}app/lib/core/l10n/arb_src');
  final outDir = Directory('${root}app/lib/core/l10n/arb');
  final errors = <String>[];

  final owners = src.listSync().whereType<Directory>().map((d) => d.uri.pathSegments.reversed.skip(1).first).toList()
    ..sort((a, b) => a == 'core' ? -1 : (b == 'core' ? 1 : a.compareTo(b)));

  final merged = {'ar': <String, dynamic>{'@@locale': 'ar'}, 'en': <String, dynamic>{'@@locale': 'en'}};
  final ownerOf = <String, String>{};

  for (final owner in owners) {
    final maps = <String, Map<String, dynamic>>{};
    for (final lang in ['ar', 'en']) {
      final f = File('${src.path}/$owner/$lang.arb');
      if (!f.existsSync()) {
        errors.add('$owner: missing $lang.arb');
        maps[lang] = {};
        continue;
      }
      maps[lang] = (jsonDecode(f.readAsStringSync()) as Map<String, dynamic>)..remove('@@locale');
    }
    final arKeys = maps['ar']!.keys.where((k) => !k.startsWith('@')).toSet();
    final enKeys = maps['en']!.keys.where((k) => !k.startsWith('@')).toSet();
    for (final k in arKeys.difference(enKeys)) {
      errors.add('$owner: "$k" missing in en.arb');
    }
    for (final k in enKeys.difference(arKeys)) {
      errors.add('$owner: "$k" missing in ar.arb');
    }
    for (final k in arKeys) {
      final prefixes = owner == 'core' ? corePrefixes : [owner];
      if (!prefixes.any((p) => k.startsWith(p) && k.length > p.length && _isUpper(k[p.length]))) {
        errors.add('$owner: key "$k" must start with ${prefixes.join('/')} + UpperCase');
      }
      if (ownerOf.containsKey(k)) errors.add('"$k" defined by both ${ownerOf[k]} and $owner');
      ownerOf[k] = owner;
      final meta = maps['ar']!['@$k'];
      if (meta is! Map || (meta['description'] as String?)?.isNotEmpty != true) {
        errors.add('$owner: "@$k" with a "description" is required in ar.arb');
      }
    }
    merged['ar']!.addAll(maps['ar']!);
    for (final e in maps['en']!.entries) {
      if (!e.key.startsWith('@')) merged['en']![e.key] = e.value;
    }
  }

  if (errors.isNotEmpty) {
    stderr.writeln('ARB merge FAILED:\n  ${errors.join('\n  ')}');
    exit(1);
  }
  const enc = JsonEncoder.withIndent('  ');
  for (final lang in ['ar', 'en']) {
    File('${outDir.path}/app_$lang.arb').writeAsStringSync('${enc.convert(merged[lang])}\n');
  }
  stdout.writeln('ARB merged: ${ownerOf.length} keys from ${owners.join(', ')}');
}

bool _isUpper(String c) => c.toUpperCase() == c && c.toLowerCase() != c;
