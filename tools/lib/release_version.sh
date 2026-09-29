# Sourced by tools/release_apk.sh and tools/release_personal.sh (after env.sh).
#
# Version scheme (owner's decision, 2026-09-29; iOS only accepts numbers in
# CFBundleShortVersionString):
#   - app/pubspec.yaml `version: <name>+<build>`: <name> is NUMERIC only
#     (1.0.0), <build> is the tester build number and only goes up.
#   - The release label ("rc1", empty for a final release) lives only in git
#     tags and release names/notes: tester tag v<name>-<label>-b<build>
#     (v<name>-b<build> without a label).
#   - The label reaches the app at build time through
#     --dart-define=AZM_RELEASE_LABEL=<label> (About, licences, backups);
#     a plain `flutter run` / debug build has no label.
#
# azm_release_version [--label <label> | --final]
#   Sets AZM_VER_NAME, AZM_VER_BUILD, AZM_VER_LABEL. Without an option the
#   label is the one of the newest tester tag of this <name> (fetch tags
#   first); no such tag → no label.

azm_release_version() {
  local full explicit="" label="" t
  full="$(awk '/^version:/{print $2; exit}' "$ROOT/app/pubspec.yaml")"
  AZM_VER_NAME="${full%+*}"
  AZM_VER_BUILD="${full##*+}"
  if [ "$AZM_VER_NAME" = "$full" ] || ! [[ "$AZM_VER_BUILD" =~ ^[0-9]+$ ]]; then
    echo "FAILED: pubspec version must be <name>+<build>, got '$full'"; exit 1
  fi
  if ! [[ "$AZM_VER_NAME" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "FAILED: pubspec version name must be numeric (e.g. 1.0.0+3; iOS rejects '$AZM_VER_NAME'). Put rc/beta labels in the tag: --label rc1"; exit 1
  fi
  case "${1:-}" in
    --label) explicit=1; label="${2:-}"
      [ -n "$label" ] || { echo "FAILED: --label needs a value (or use --final)"; exit 1; } ;;
    --final) explicit=1; label="" ;;
    "") ;;
    *) echo "FAILED: unknown option '$1' (--label <label> | --final)"; exit 1 ;;
  esac
  if [ -z "$explicit" ]; then
    # Newest tester tag of this version name, e.g. v1.0.0-rc1-b2 → rc1.
    t="$(git -C "$ROOT" tag -l "v${AZM_VER_NAME}-*" --sort=-creatordate \
      | grep -E "^v${AZM_VER_NAME//./\\.}(-[a-z][a-z0-9.]*)?-b[0-9]+\$" | head -1)"
    label="$(printf '%s' "$t" | sed -nE "s/^v${AZM_VER_NAME//./\\.}-([a-z][a-z0-9.]*)-b[0-9]+\$/\\1/p")"
  fi
  if [ -n "$label" ] && ! [[ "$label" =~ ^[a-z][a-z0-9.]*$ ]]; then
    echo "FAILED: release label '$label' must be lower-case letters/digits/dots, starting with a letter (e.g. rc1)"; exit 1
  fi
  AZM_VER_LABEL="$label"
}
