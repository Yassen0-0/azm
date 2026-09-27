// Checks that parallel windows own disjoint paths (docs/PLAN.md).
//
//   source ./env.sh && dart run tools/check_plan_overlap.dart C D
//
// For each window letter it reads the section whose `## ` heading contains
// "<letter> window", takes the backticked ROOT-relative paths from its
// "**Owns (only these):**" sub-bullets (brace groups like `{ar,en}` expanded;
// `**` = any depth, `*` = one segment), and fails (exit 1) when:
// - a path of one window overlaps a path of another (pattern level, so files
//   that don't exist yet are covered too);
// - a tracked or untracked (not ignored) file is matched by two windows;
// - a window owns a frozen or generated path (the "Frozen for feature windows"
//   and "Generated, never hand-edited" lines at the top of PLAN.md).
import 'dart:io';

final root = Directory.fromUri(Platform.script.resolve('..')).absolute.path;

void main(List<String> args) {
  if (args.length < 2) {
    stderr.writeln('usage: dart run tools/check_plan_overlap.dart <window> <window> [...]   e.g. C D');
    exit(2);
  }
  final plan = File('${root}docs/PLAN.md').readAsLinesSync();
  final errors = <String>[];

  final frozen = _pathsOnLine(plan, '**Frozen for feature windows**');
  final generated = _pathsOnLine(plan, '**Generated, never hand-edited**');
  final owned = {for (final w in args) w: _ownedPaths(plan, w, errors)};
  final files = _repoFiles();

  for (final w in args) {
    final pats = owned[w]!;
    final hits = files.where((f) => pats.any((p) => p.matches(f))).length;
    stdout.writeln('Window $w owns ${pats.length} paths ($hits existing files):');
    for (final p in pats) {
      stdout.writeln('  ${p.raw}');
    }
    for (final p in pats) {
      for (final f in frozen) {
        if (p.overlaps(f)) errors.add('$w owns ${p.raw}, which overlaps FROZEN ${f.raw}');
      }
      for (final g in generated) {
        if (p.within(g)) errors.add('$w owns ${p.raw}, which is GENERATED (${g.raw})');
      }
    }
  }

  for (var i = 0; i < args.length; i++) {
    for (var j = i + 1; j < args.length; j++) {
      final (a, b) = (args[i], args[j]);
      for (final p in owned[a]!) {
        for (final q in owned[b]!) {
          if (p.overlaps(q)) errors.add('$a ${p.raw}  ↔  $b ${q.raw}');
        }
      }
    }
  }

  for (final f in files) {
    final by = [
      for (final w in args)
        if (owned[w]!.any((p) => p.matches(f))) w,
    ];
    if (by.length > 1) errors.add('file $f is owned by ${by.join(' + ')}');
  }

  if (errors.isNotEmpty) {
    stderr.writeln('\nOVERLAP CHECK FAILED:\n  ${errors.join('\n  ')}');
    exit(1);
  }
  stdout.writeln('\nOK: ${args.join(', ')} own disjoint paths; none frozen or generated.');
}

/// ROOT-relative path pattern.
class _Pat {
  _Pat(this.raw)
    : literal = raw.contains('*') ? raw.substring(0, raw.indexOf('*')) : raw,
      re = RegExp('^${raw.split('**').map((s) => s.split('*').map(RegExp.escape).join('[^/]*')).join('.*')}\$');

  final String raw;

  /// Text before the first wildcard (the whole path when there is none).
  final String literal;
  final RegExp re;

  bool get isGlob => raw.contains('*');

  /// A concrete path that stands for this pattern.
  String get sample => isGlob ? '${literal}__probe__/x.dart' : raw;

  bool matches(String path) => re.hasMatch(path);

  /// Everything this pattern owns is also matched by [other].
  bool within(_Pat other) => other.matches(sample);

  /// Some path could be matched by both.
  bool overlaps(_Pat o) {
    if (matches(o.sample) || o.matches(sample)) return true;
    // Two globs: overlap when one fixed prefix contains the other (conservative).
    if (isGlob && o.isGlob && literal.isNotEmpty && o.literal.isNotEmpty) {
      return literal.startsWith(o.literal) || o.literal.startsWith(literal);
    }
    return false;
  }
}

final _tick = RegExp('`([^`]+)`');

bool _isRootPath(String s) {
  if (!s.contains('/') || s.contains(' ')) return false;
  final first = s.split('/').first;
  return first.isNotEmpty && !first.contains('*') && Directory('$root$first').existsSync();
}

List<String> _expand(String s) {
  final m = RegExp(r'\{([^{}]*)\}').firstMatch(s);
  if (m == null) return [s];
  return [for (final alt in m.group(1)!.split(',')) ..._expand(s.replaceRange(m.start, m.end, alt.trim()))];
}

List<_Pat> _toPats(Iterable<String> ticks) => [
  for (final t in ticks)
    if (_isRootPath(t) || t.startsWith('*')) ..._expand(t).map(_Pat.new),
];

List<_Pat> _pathsOnLine(List<String> plan, String marker) {
  final line = plan.firstWhere((l) => l.contains(marker), orElse: () => '');
  if (line.isEmpty) throw StateError('PLAN.md: no line with $marker');
  return _toPats(_tick.allMatches(line).map((m) => m.group(1)!));
}

List<_Pat> _ownedPaths(List<String> plan, String w, List<String> errors) {
  final start = plan.indexWhere((l) => l.startsWith('## ') && RegExp('\\b$w window\\b').hasMatch(l));
  if (start < 0) {
    errors.add('no "## … $w window …" heading in PLAN.md');
    return [];
  }
  var i = plan.indexWhere((l) => l.contains('**Owns (only these):**'), start);
  final next = plan.indexWhere((l) => l.startsWith('## '), start + 1);
  if (i < 0 || (next >= 0 && i > next)) {
    errors.add('window $w: no "**Owns (only these):**" bullet');
    return [];
  }
  final ticks = <String>[];
  for (i++; i < plan.length && plan[i].startsWith('  '); i++) {
    // Parenthesised notes ("(pre-registered: `ui/x.dart` (…))") are not paths.
    var text = plan[i];
    for (String prev = ''; prev != text;) {
      prev = text;
      text = text.replaceAll(RegExp(r'\([^()]*\)'), '');
    }
    ticks.addAll(_tick.allMatches(text).map((m) => m.group(1)!));
  }
  final pats = _toPats(ticks);
  if (pats.isEmpty) errors.add('window $w: "Owns" lists no paths');
  return pats;
}

List<String> _repoFiles() {
  final r = Process.runSync('git', ['-C', root, 'ls-files', '-co', '--exclude-standard']);
  if (r.exitCode != 0) throw StateError('git ls-files failed: ${r.stderr}');
  return (r.stdout as String).split('\n').where((l) => l.isNotEmpty).toList();
}
