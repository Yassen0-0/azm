// Arabic/Latin search normalization — shared by the app and
// tools/build_catalog.dart. KEEP THIS FILE FREE OF IMPORTS: the build tool
// imports it by relative path from outside the Flutter package.
//
// Index (`exercises.search_norm`) and query MUST go through the same function.
// Spec: docs/DATA.md → "Arabic search normalization".

/// Normalizes [input] for search:
/// 1. strip tashkeel (U+064B–U+065F, U+0670, U+06D6–U+06ED)
/// 2. strip tatweel (U+0640) and invisible marks (U+200B–U+200F, U+FEFF)
/// 3. أ إ آ ٱ → ا
/// 4. ة → ه
/// 5. ى → ي
/// 6. ؤ → و
/// 7. ئ → ي
/// 7b. Egyptian spelling variants: ظ → ض, ذ → د, ث → ت
///     (ظهر/ضهر, ذراع/دراع, ثقيل/تقيل)
/// 8. lowercase Latin
/// 9. collapse whitespace, trim
String normalizeForSearch(String input) {
  final out = StringBuffer();
  var pendingSpace = false;
  for (final rune in input.runes) {
    // 1–2: drop diacritics and tatweel.
    if ((rune >= 0x064B && rune <= 0x065F) ||
        rune == 0x0670 ||
        (rune >= 0x06D6 && rune <= 0x06ED) ||
        rune == 0x0640 ||
        // invisible marks (ZWSP, ZWNJ, ZWJ, LRM, RLM, BOM) — removed, not spaces
        (rune >= 0x200B && rune <= 0x200F) ||
        rune == 0xFEFF) {
      continue;
    }
    // 9: whitespace runs → a single space (emitted lazily, so trimmed).
    if (_isSpace(rune)) {
      pendingSpace = out.isNotEmpty;
      continue;
    }
    if (pendingSpace) {
      out.writeCharCode(0x20);
      pendingSpace = false;
    }
    out.writeCharCode(_mapRune(rune));
  }
  return out.toString();
}

/// Splits a normalized query into non-empty tokens.
List<String> searchTokens(String query) {
  final n = normalizeForSearch(query);
  return n.isEmpty ? const [] : n.split(' ');
}

int _mapRune(int r) {
  switch (r) {
    case 0x0623: // أ
    case 0x0625: // إ
    case 0x0622: // آ
    case 0x0671: // ٱ
      return 0x0627; // ا
    case 0x0629: // ة
      return 0x0647; // ه
    case 0x0649: // ى
      return 0x064A; // ي
    case 0x0624: // ؤ
      return 0x0648; // و
    case 0x0626: // ئ
      return 0x064A; // ي
    // 7b: Egyptian colloquial spelling (ظهر → ضهر, ذراع → دراع, ثقيل → تقيل).
    case 0x0638: // ظ
      return 0x0636; // ض
    case 0x0630: // ذ
      return 0x062F; // د
    case 0x062B: // ث
      return 0x062A; // ت
  }
  // 8: ASCII A–Z → a–z. Non-ASCII Latin is left as is (dataset is ASCII).
  if (r >= 0x41 && r <= 0x5A) return r + 0x20;
  return r;
}

bool _isSpace(int r) =>
    r == 0x20 ||
    r == 0x09 ||
    r == 0x0A ||
    r == 0x0D ||
    r == 0x0B ||
    r == 0x0C ||
    r == 0xA0 || // no-break space
    r == 0x3000 ||
    (r >= 0x2000 && r <= 0x200A);
