#!/bin/bash
# Merge per-owner ARB fragments (app/lib/core/l10n/arb_src/<owner>/{ar,en}.arb)
# into app/lib/core/l10n/arb/app_{ar,en}.arb, then run `flutter gen-l10n`.
# Edit ONLY your owner's fragment; never the merged files. Run from anywhere.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source "$ROOT/env.sh"
dart run "$ROOT/tools/merge_arb.dart"
cd "$ROOT/app" && flutter gen-l10n 2>&1 | grep -vE 'Picked up|l10n.yaml exists|command line arguments|^\s*$' || true
