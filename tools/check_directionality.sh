#!/bin/bash
# Fails if physical left/right layout APIs appear in app/lib/ (Azm is RTL-first:
# use EdgeInsetsDirectional, AlignmentDirectional, PositionedDirectional,
# BorderRadiusDirectional, TextAlign.start/end, start:/end:).
#
#   tools/check_directionality.sh          # from anywhere
#
# Escape hatch (rare, e.g. a painter drawing in physical space): append
#   // directionality: ignore (<reason>)
# to the offending line. Generated code (*.g.dart, core/l10n/gen/) is skipped.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source "$ROOT/env.sh" || exit 1   # fails fast if flutter is not the sandbox one
DIR="$ROOT/app/lib"
[ -d "$DIR" ] || { echo "no app/lib yet"; exit 0; }

# label|extended regex
RULES=(
  "EdgeInsets.only / fromLTRB (use EdgeInsetsDirectional)|EdgeInsets\.(only|fromLTRB)\("
  "Alignment.*Left/*Right (use AlignmentDirectional)|\bAlignment\.(topLeft|topRight|centerLeft|centerRight|bottomLeft|bottomRight)\b"
  "TextAlign.left/right (use start/end)|\bTextAlign\.(left|right)\b"
  "left:/right: named argument (use start:/end:)|(^|[(,[:space:]])(left|right)[[:space:]]*:"
  "topLeft/topRight/bottomLeft/bottomRight corner (use BorderRadiusDirectional)|(^|[(,[:space:]])(topLeft|topRight|bottomLeft|bottomRight)[[:space:]]*:"
  "BorderRadius.horizontal(left:/right:) (use BorderRadiusDirectional.horizontal)|BorderRadius\.horizontal\("
  "Positioned(left:/right:) (use PositionedDirectional)|Positioned\([^)]*\b(left|right)[[:space:]]*:"
  "Hard-coded TextDirection.ltr/rtl (let Directionality decide)|\bTextDirection\.(ltr|rtl)\b"
)

FILES=$(find "$DIR" -name '*.dart' ! -name '*.g.dart' ! -path '*/core/l10n/gen/*' | sort)
fail=0
for rule in "${RULES[@]}"; do
  label="${rule%%|*}"
  re="${rule#*|}"
  # shellcheck disable=SC2086
  hits=$(grep -nE "$re" $FILES 2>/dev/null | grep -v 'directionality: ignore' | grep -vE '^[^:]+:[0-9]+:[[:space:]]*//' || true)
  if [ -n "$hits" ]; then
    fail=1
    echo "✗ $label"
    echo "$hits" | sed "s#^$ROOT/#   #"
  fi
done

if [ $fail -ne 0 ]; then
  echo
  echo "Directionality check FAILED — use start/end APIs (see CLAUDE.md)."
  exit 1
fi
echo "✓ directionality check passed ($(echo "$FILES" | wc -l | tr -d ' ') files)"
