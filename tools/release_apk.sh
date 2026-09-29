#!/bin/bash
# Tester APK release (owner only; the GitHub repo is private).
#
#   tools/release_apk.sh --build-only   # build + verify dist/azm-<ver>[-<label>]-<build>.apk, publish nothing
#   tools/release_apk.sh                # build + verify + GitHub prerelease v<ver>[-<label>]-b<build>
#   ... [--label rc2 | --final]         # change the release label (default: the newest tag's)
#
# Version (tools/lib/release_version.sh): app/pubspec.yaml `version: <ver>+<build>`
# with a NUMERIC <ver> (1.0.0: iOS rejects anything else). <build> is the next
# tester build: this script releases it, tags that commit v<ver>-<label>-b<build>
# (e.g. v1.0.0-rc1-b3; v1.0.0-b3 for a final release), then bumps pubspec to
# <build>+1 and commits + pushes that. The label ("rc1") lives only in the tag,
# the release name/notes and the app's AZM_RELEASE_LABEL dart-define (About,
# backups); by default it is the one of the newest tester tag of <ver>.
# Release notes: docs/release_notes/<tag>.md (Arabic + English, short,
# committed BEFORE running; if missing, the script lists the commits since the
# previous tester release and stops).
#
# Signing: .tooling/secrets/azm-upload.jks + its password from the macOS
# Keychain (tools/upload_key.sh), handed to Gradle through environment
# variables for this build only (no file). The APK's certificate is checked
# against the upload key, so a debug-signed APK can never be published.
# Media (committed in azm since 2026-09-28, NEVER in a tester build): the APK's
# asset list is printed; the release aborts if any entry is
# under media/, is a GIF/video, or is byte-identical to a file in media/.
# GitHub goes through ./gh_env (token in the Keychain). Every wait is capped.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$ROOT"
source "$ROOT/env.sh" || exit 1   # fails fast if flutter is not the sandbox one
source "$ROOT/tools/lib/github_guard.sh"
source "$ROOT/tools/lib/release_version.sh"

MODE=publish
LABEL_OPT=()
while [ $# -gt 0 ]; do
  case "$1" in
    --build-only) MODE=build ;;
    --label) LABEL_OPT=(--label "${2:-}"); shift ;;
    --final) LABEL_OPT=(--final) ;;
    *) echo "usage: tools/release_apk.sh [--build-only] [--label <label> | --final]"; exit 1 ;;
  esac
  shift
done
REPO="Yassen0-0/azm"
GH="$ROOT/gh_env"
BUILD_TOOLS="$(ls -d "$ANDROID_HOME"/build-tools/* | sort -V | tail -1)"
LOG="$TMPDIR/release-apk.log"

fail() { echo "FAILED: $*"; exit 1; }
step() { echo; echo "==> $*"; }

# ---- Version (numeric name + build from pubspec, label from the tags) -----------
[ "$MODE" = publish ] && "$GH" git fetch -q origin --tags   # the label comes from the newest tag
azm_release_version ${LABEL_OPT[@]+"${LABEL_OPT[@]}"}
NAME="$AZM_VER_NAME"; BUILD="$AZM_VER_BUILD"; LABEL="$AZM_VER_LABEL"
SHOWN="${NAME}${LABEL:+-$LABEL}"   # what About shows: 1.0.0-rc1
TAG="v${SHOWN}-b${BUILD}"
APK="dist/azm-${SHOWN}-${BUILD}.apk"
NOTES="docs/release_notes/${TAG}.md"
echo "version $NAME, label '${LABEL}', build $BUILD → $APK, tag $TAG ($MODE)"

prev_tag() { git tag -l 'v*-b*' --sort=-creatordate | grep -v "^$TAG\$" | head -1; }

# ---- Pre-flight (publish only) -------------------------------------------------
if [ "$MODE" = publish ]; then
  step "Pre-flight"
  [ -z "$(git status --porcelain)" ] || fail "working tree not clean (commit first; the tag must match the build)"
  [ "$(git rev-parse --abbrev-ref HEAD)" = main ] || fail "not on main"
  "$GH" git fetch -q origin main --tags
  [ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ] || fail "HEAD is not origin/main (push or pull first)"
  git rev-parse -q --verify "refs/tags/$TAG" >/dev/null && fail "tag $TAG already exists (bump pubspec)"
  if [ ! -f "$NOTES" ]; then
    p="$(prev_tag)"
    echo "Missing $NOTES (Arabic + English). Commits since ${p:-the start}:"
    git log --no-merges --format='  - %s' ${p:+"$p"..HEAD} | head -40
    exit 1
  fi
  azm_require_private_repo   # azm PRIVATE + owner-only (it contains unlicensed media)
fi

# ---- Build (signed with the upload key) -----------------------------------------
step "Build universal release APK"
# Tester builds NEVER contain media: the personal flavor's asset folders must
# be empty here (tools/release_personal.sh cleans them up after its build).
leftover="$(find app/assets/media -type f ! -name .gitkeep | head -3)"
[ -z "$leftover" ] || fail "media files in app/assets/media (e.g. $leftover): remove them; tester builds never include media"
[ -f "$AZM_TOOLING/secrets/azm-upload.jks" ] || fail "no upload keystore (tools/upload_key.sh create)"
EXPECTED_CERT="$(tools/upload_key.sh sha256)"
[ -n "$EXPECTED_CERT" ] || fail "can't read the upload key password from the Keychain"
(cd app/android && ./gradlew --stop -q >/dev/null 2>&1) || true   # fresh daemon env
(
  export AZM_UPLOAD_KEYSTORE="$AZM_TOOLING/secrets/azm-upload.jks"
  AZM_UPLOAD_STORE_PASSWORD="$(HOME="$AZM_REAL_HOME" /usr/bin/security find-generic-password -s azm.android.upload -a keystore -w)"
  export AZM_UPLOAD_STORE_PASSWORD
  cd app && flutter build apk --release --dart-define=AZM_RELEASE_LABEL="$LABEL"
) >"$LOG" 2>&1 &
pid=$!
for _ in $(seq 1 360); do kill -0 "$pid" 2>/dev/null || break; sleep 5; done
if kill -0 "$pid" 2>/dev/null; then kill "$pid"; echo "TIMEOUT (30 min)"; tail -50 "$LOG"; exit 1; fi
wait "$pid" || { tail -50 "$LOG"; fail "flutter build apk"; }
(cd app/android && ./gradlew --stop -q >/dev/null 2>&1) || true   # drop the daemon that saw the password
grep -E '✓ Built' "$LOG" || true
mkdir -p dist
cp app/build/app/outputs/flutter-apk/app-release.apk "$APK"

# ---- Verify ------------------------------------------------------------------------
step "Verify signature, version, contents"
# One signer expected; its label varies by apksigner version ("Signer #1", "V2 Signer").
CERTS="$("$BUILD_TOOLS/apksigner" verify --print-certs "$APK" 2>/dev/null | awk -F': ' '/certificate SHA-256 digest/{print $NF}' | sort -u)"
[ "$(echo "$CERTS" | grep -c .)" = 1 ] || fail "expected exactly one signing certificate, got: ${CERTS:-none}"
CERT="$CERTS"
[ "$CERT" = "$EXPECTED_CERT" ] || fail "APK is not signed with the upload key (got '${CERT:-none}')"
echo "signed with the upload key (SHA-256 $CERT)"
BADGING="$("$BUILD_TOOLS/aapt2" dump badging "$APK")"
PKG_LINE="$(echo "$BADGING" | head -1)"
echo "$PKG_LINE"
echo "$PKG_LINE" | grep -q "name='app.azm.gym'" || fail "wrong package"
echo "$PKG_LINE" | grep -q "versionCode='$BUILD'" || fail "versionCode is not $BUILD"
echo "$PKG_LINE" | grep -q "versionName='$NAME'" || fail "versionName is not $NAME"
MIN_SDK="$(echo "$BADGING" | awk -F"'" '/^minSdkVersion:|^sdkVersion:/{print $2; exit}')"
TARGET_SDK="$(echo "$BADGING" | awk -F"'" '/^targetSdkVersion:/{print $2; exit}')"
ABIS="$(echo "$BADGING" | awk -F"native-code: " '/^native-code:/{print $2}')"
SIZE_MB="$(awk -v b="$(stat -f %z "$APK")" 'BEGIN{printf "%.1f", b/1048576}')"
echo "minSdk $MIN_SDK, targetSdk $TARGET_SDK, ABIs $ABIS, size $SIZE_MB MB"

ENTRIES="$(unzip -Z1 "$APK")"
echo "assets in the APK:"
echo "$ENTRIES" | grep '^assets/' | sed 's/^/  /'
BAD="$(echo "$ENTRIES" | grep -Ei '(^|/)media/|\.(gif|mp4|m4v|mov|webm|avi)$' || true)"
[ -z "$BAD" ] || { echo "$BAD"; fail "the APK contains media-like files"; }
if [ -d media ]; then
  MEDIA_HASHES="$TMPDIR/media-hashes.txt"
  find media -type f -print0 | xargs -0 shasum -a 256 | awk '{print $1}' | sort -u >"$MEDIA_HASHES"
  X="$TMPDIR/apk-extract"; rm -rf "$X"; mkdir -p "$X"; unzip -q "$APK" -d "$X"
  HITS="$(find "$X" -type f -print0 | xargs -0 shasum -a 256 | awk '{print $1}' | sort -u | comm -12 - "$MEDIA_HASHES")"
  rm -rf "$X"
  [ -z "$HITS" ] || fail "the APK contains $(echo "$HITS" | wc -l | tr -d ' ') file(s) identical to files in media/"
  echo "no file from media/ ($(wc -l <"$MEDIA_HASHES" | tr -d ' ') checked by SHA-256)"
fi

if [ "$MODE" = build ]; then
  echo; echo "BUILD ONLY: $APK ($SIZE_MB MB, versionCode $BUILD). Not published."
  exit 0
fi

# ---- Publish ----------------------------------------------------------------------
step "Tag $TAG and publish the GitHub prerelease"
git tag -a "$TAG" -m "Azm $SHOWN tester build $BUILD"
"$GH" git push -q origin "$TAG"
"$GH" gh release create "$TAG" "$APK" --repo "$REPO" --verify-tag --prerelease \
  --title "Azm $SHOWN — tester build $BUILD" --notes-file "$NOTES" >/dev/null
URL="$("$GH" gh release view "$TAG" --repo "$REPO" --json url,isPrerelease -q 'select(.isPrerelease) | .url')"
[ -n "$URL" ] || fail "release $TAG not found as a prerelease"
azm_require_private_repo

step "Next build number"
NEXT=$((BUILD + 1))
sed -i '' "s/^version: .*/version: ${NAME}+${NEXT}/" app/pubspec.yaml
git add app/pubspec.yaml
git commit -q -m "Tester build $BUILD released ($TAG); next build $NEXT"
"$GH" git push -q origin main
echo "Released $TAG: $URL"
echo "APK $APK, $SIZE_MB MB, minSdk $MIN_SDK. pubspec is now ${NAME}+${NEXT}."
