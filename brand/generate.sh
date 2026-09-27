#!/bin/bash
# Regenerates EVERY icon and splash asset from brand/logo-concept-a.svg.
#
#   brand/generate.sh           regenerate into app/ and brand/exports/
#   brand/generate.sh --check   regenerate into a temp dir and fail (exit 1) if
#                               any committed asset differs, is missing or is stale
#
# Only macOS tools: swiftc (Xcode) compiles brand/pipeline/azm_brand.swift,
# AppKit renders the SVG. Nothing is installed. Deterministic: running it twice
# changes nothing. Every step is capped (CLAUDE.md → Waiting and polling).
# See brand/README.md for the source contract and the list of outputs.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source "$ROOT/env.sh"
cd "$ROOT"

SVG=brand/logo-concept-a.svg
THEME=design/theme.json
SWIFT=brand/pipeline/azm_brand.swift
CAP="${AZM_BRAND_TIMEOUT:-300}"  # seconds per step
RES=app/android/app/src/main/res
IOS=app/ios/Runner
mkdir -p "$TMPDIR"
LOG="$TMPDIR/brand-generate.log"

MODE=write
case "${1:-}" in
  "") ;;
  --check) MODE=check ;;
  *) echo "usage: brand/generate.sh [--check]"; exit 2 ;;
esac

run_capped() { # run_capped <label> <command...>: fails on timeout or non-zero exit
  local label="$1" pid rc=0 t=0
  shift
  "$@" >>"$LOG" 2>&1 &
  pid=$!
  while kill -0 "$pid" 2>/dev/null; do
    if [ "$t" -ge "$((CAP * 5))" ]; then
      kill "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true
      echo "TIMEOUT ($CAP s): $label"; tail -50 "$LOG"; exit 1
    fi
    sleep 0.2
    t=$((t + 1))
  done
  wait "$pid" || rc=$?
  [ "$rc" = 0 ] || { echo "FAILED: $label (exit $rc)"; tail -50 "$LOG"; exit 1; }
}

# Every path the pipeline owns (relative to ROOT). Directories are owned whole.
managed_dirs() {
  local b="$1" d
  for d in "$b/$RES"/mipmap-* "$b/$RES"/drawable-*dpi "$b/$RES/values-v31" "$b/$RES/values-night-v31" \
           "$b/$IOS/Assets.xcassets/AppIcon.appiconset" "$b/$IOS/Assets.xcassets/LaunchImage.imageset" "$b/brand/exports"; do
    if [ -e "$d" ]; then echo "$d"; fi
  done
  return 0
}
MANAGED_FILES="$RES/drawable/launch_background.xml $RES/drawable-v21/launch_background.xml $RES/values/colors.xml
$RES/values/styles.xml $RES/values-night/styles.xml $IOS/Base.lproj/LaunchScreen.storyboard"
# Replaced by drawable-*dpi/ic_stat_azm.png (same resource name, see DECISIONS_LOG).
OBSOLETE="$RES/drawable/ic_stat_azm.xml"

list_outputs() { # list_outputs <base>: every managed file under <base>, relative, sorted
  local b="$1"
  { managed_dirs "$b" | while read -r d; do find "$d" -type f; done
    for f in $MANAGED_FILES $OBSOLETE; do if [ -f "$b/$f" ]; then echo "$b/$f"; fi; done
  } | sed "s#^$b/##" | LC_ALL=C sort
}

: >"$LOG"
# Compile once per source version (cached in .tooling/tmp).
HASH="$(shasum "$SWIFT" | cut -c1-12)"
BIN="$TMPDIR/azm_brand-$HASH"
if [ ! -x "$BIN" ]; then
  echo "==> compiling $SWIFT"
  run_capped "swiftc" /usr/bin/xcrun swiftc -O -module-cache-path "$TMPDIR/swift-module-cache" "$SWIFT" -o "$BIN"
fi

if [ "$MODE" = write ]; then
  echo "==> regenerating from $SVG"
  managed_dirs "$ROOT" | while read -r d; do rm -rf "$d"; done
  for f in $MANAGED_FILES $OBSOLETE; do rm -f "$f"; done
  run_capped "azm_brand" "$BIN" "$SVG" "$THEME" "$ROOT"
  grep '^azm_brand:' "$LOG" || true
  echo "==> $(list_outputs "$ROOT" | wc -l | tr -d ' ') files written:"
  list_outputs "$ROOT" | sed 's/^/   /'
  exit 0
fi

OUT="$TMPDIR/brand-check"
rm -rf "$OUT"
mkdir -p "$OUT"
run_capped "azm_brand (check)" "$BIN" "$SVG" "$THEME" "$OUT"
FRESH="$(list_outputs "$OUT")"
COMMITTED="$(list_outputs "$ROOT")"
bad=0
if [ "$FRESH" != "$COMMITTED" ]; then
  echo "file list differs (< fresh run, > committed):"
  diff <(echo "$FRESH") <(echo "$COMMITTED") | grep '^[<>]' || true
  bad=1
fi
while read -r f; do
  [ -f "$ROOT/$f" ] || continue
  cmp -s "$OUT/$f" "$ROOT/$f" || { echo "stale: $f"; bad=1; }
done <<<"$FRESH"
rm -rf "$OUT"
if [ "$bad" = 1 ]; then
  echo "brand/generate.sh --check: FAILED. Committed assets are not what $SVG produces; run brand/generate.sh."
  exit 1
fi
echo "brand/generate.sh --check: OK ($(echo "$FRESH" | wc -l | tr -d ' ') files match $SVG)"
