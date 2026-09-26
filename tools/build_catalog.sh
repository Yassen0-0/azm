#!/bin/bash
# Rebuild the exercise catalog (see tools/build_catalog.dart). Run from anywhere.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source "$ROOT/env.sh"
cd "$ROOT/tools" && dart run build_catalog.dart
