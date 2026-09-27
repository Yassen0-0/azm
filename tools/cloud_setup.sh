#!/bin/bash
# Cloud / Linux setup (Claude Code on the web, CI): no devices, no Android SDK,
# no Xcode. Installs the PINNED Flutter SDK into ROOT/.tooling/flutter (same
# place as on the Mac, so env.sh and its sandbox guard work unchanged), then:
#   pub get (app + tools) → regenerate everything generated (l10n, Drift code,
#   catalog) and FAIL if it differs from what's committed → flutter analyze,
#   dart analyze (tools), flutter test, directionality check.
#
#   tools/cloud_setup.sh              # full run (idempotent; re-running skips the SDK download)
#   tools/cloud_setup.sh --no-tests   # setup + codegen check only
#
# System packages: in a cloud/Linux container (ephemeral) the script installs
# what it needs with apt-get (git, curl, unzip, xz-utils, libsqlite3-dev),
# which CLAUDE.md allows there. On the Mac it NEVER installs anything; it only
# checks and stops. Everything else lives in ROOT/.tooling. Device work
# (screenshots, E2E) is Mac-only: CLAUDE.md → "Cloud / no devices".
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$ROOT"

FLUTTER_VERSION="3.47.5"
FLUTTER_COMMIT="6a19cca56475dbfba1478ee68d7bd0c2ef891da1" # README → Pinned toolchain
RUN_TESTS=1
[ "${1:-}" = "--no-tests" ] && RUN_TESTS=0

step() { echo; echo "==> $*"; }

# ---- 0. System packages (cloud container only) --------------------------------
missing_pkgs=()
needed="git:git curl:curl unzip:unzip"
[ "$(uname -s)" = Linux ] && needed="$needed xz:xz-utils" # Flutter's Linux downloads are .tar.xz
for tool_pkg in $needed; do
  command -v "${tool_pkg%%:*}" >/dev/null 2>&1 || missing_pkgs+=("${tool_pkg##*:}")
done
if [ "$(uname -s)" = Linux ]; then
  # SQLite for the Drift tests (package:sqlite3 loads libsqlite3.so if its own
  # build hook can't provide a library).
  if ! { ldconfig -p 2>/dev/null | grep -q 'libsqlite3\.so'; }; then missing_pkgs+=(libsqlite3-dev); fi
  if [ ${#missing_pkgs[@]} -gt 0 ]; then
    step "Cloud container: installing system packages ${missing_pkgs[*]} (apt-get; allowed in the cloud only, never on the Mac: CLAUDE.md)"
    command -v apt-get >/dev/null 2>&1 || { echo "FAILED: need ${missing_pkgs[*]} but apt-get isn't available; install them with this image's package manager."; exit 1; }
    SUDO=""
    if [ "$(id -u)" != 0 ]; then
      command -v sudo >/dev/null 2>&1 || { echo "FAILED: need root or sudo to apt-get install ${missing_pkgs[*]}."; exit 1; }
      SUDO="sudo"
    fi
    $SUDO apt-get update -qq
    $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends "${missing_pkgs[@]}"
  else
    step "System packages present (git, curl, unzip, xz, libsqlite3)"
  fi
elif [ ${#missing_pkgs[@]} -gt 0 ]; then
  echo "FAILED: missing ${missing_pkgs[*]}. On the Mac nothing is installed automatically (sandbox rule): ask the owner."
  exit 1
fi

# .tooling must exist before env.sh is sourced (it looks for it next to itself).
mkdir -p .tooling/tmp .tooling/home .tooling/pub-cache

# ---- 1. Pinned Flutter SDK ---------------------------------------------------
SDK="$ROOT/.tooling/flutter"
if [ -d "$SDK/.git" ] && [ "$(git -C "$SDK" rev-parse HEAD)" = "$FLUTTER_COMMIT" ]; then
  step "Flutter $FLUTTER_VERSION already in .tooling/flutter"
else
  step "Installing Flutter $FLUTTER_VERSION ($FLUTTER_COMMIT) into .tooling/flutter"
  rm -rf "$SDK"
  git clone --quiet --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$SDK"
  got="$(git -C "$SDK" rev-parse HEAD)"
  [ "$got" = "$FLUTTER_COMMIT" ] || { echo "FAILED: tag $FLUTTER_VERSION is $got, expected $FLUTTER_COMMIT"; exit 1; }
fi

# ---- 2. Sandbox environment (guard: flutter must resolve inside ROOT) ---------
# shellcheck source=../env.sh
source "$ROOT/env.sh" || exit 1
echo "flutter: $(command -v flutter)"
flutter --disable-analytics >/dev/null 2>&1 || true
dart --disable-analytics >/dev/null 2>&1 || true
flutter config --no-cli-animations --no-enable-web --no-enable-linux-desktop \
  --no-enable-macos-desktop --no-enable-windows-desktop >/dev/null
flutter --version

# ---- 3. Dependencies ------------------------------------------------------------
step "pub get (app, tools)"
(cd app && flutter pub get)
(cd tools && dart pub get)

# ---- 4. Regenerate every generated file; fail if the committed copy is stale --
step "Code generation: l10n, Drift (build_runner), catalog"
tools/gen_l10n.sh
(cd app && dart run build_runner build --delete-conflicting-outputs)
tools/build_catalog.sh
GENERATED=(app/lib/core/l10n/arb app/lib/core/l10n/gen app/assets/catalog data/catalog/catalog_version.json)
while IFS= read -r f; do GENERATED+=("$f"); done < <(git ls-files '*.g.dart')
if ! git diff --quiet -- "${GENERATED[@]}"; then
  echo "FAILED: generated files differ from the committed ones (commit the regenerated files):"
  git diff --stat -- "${GENERATED[@]}"
  exit 1
fi
untracked="$(git ls-files --others --exclude-standard -- "${GENERATED[@]}")"
[ -z "$untracked" ] || { echo "FAILED: new generated files not committed:"; echo "$untracked"; exit 1; }
echo "generated files: up to date"

# ---- 5. Checks ---------------------------------------------------------------
step "flutter analyze / dart analyze (tools) / directionality"
(cd app && flutter analyze)
(cd tools && dart analyze)
tools/check_directionality.sh

if [ "$RUN_TESTS" = 1 ]; then
  step "flutter test (unit + widget; integration tests need devices → Mac)"
  (cd app && flutter test)
fi

step "cloud setup OK. Device verification (screenshots, E2E) is pending on the Mac: see CLAUDE.md."
