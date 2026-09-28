#!/bin/bash
# OWNER-ONLY personal APK with the exercise media bundled (works offline at the
# gym), published as a prerelease `personal-b<N>` in the PRIVATE azm repo. The
# media is Gym visual's and NOT licensed (docs/LICENSES.md): this build is for
# the owner's own phone only. Never share the APK or the link.
#
#   tools/release_personal.sh --build-only   # build + verify dist/azm-personal-*.apk
#   tools/release_personal.sh                # build + verify + release in azm
#
# - Android flavor `personal` (defined only with -PazmPersonal): app id
#   app.azm.gym.personal (installs next to the tester app), launcher
#   "عزم تجريبي" / "Azm Dev", media from app/assets/media/ (flavor-only assets).
# - media/ is committed in azm (since 2026-09-28) and must match HEAD (no local
#   edits). Its files are copied into app/assets/media/{images,videos}/
#   (gitignored) for the build and removed again on exit, even on failure.
# - Version: <pubspec version>-personal; build number = highest personal-b<N>
#   release in azm + 1 (separate app id, so its own counter; tester releases
#   are v<ver>-b<N>).
# - Publish: clean tree, HEAD pushed to origin/main; the tag points at HEAD.
# - Signed with the upload key (tools/upload_key.sh), same as tester builds.
# - Aborts unless azm is PRIVATE and owner-only (tools/lib/github_guard.sh).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$ROOT"
source "$ROOT/env.sh" || exit 1   # fails fast if flutter is not the sandbox one
source "$ROOT/tools/lib/github_guard.sh"

MODE=publish
[ "${1:-}" = "--build-only" ] && MODE=build
BUILD_TOOLS="$(ls -d "$ANDROID_HOME"/build-tools/* | sort -V | tail -1)"
LOG="$TMPDIR/release-personal.log"
MAX_MB=400
fail() { echo "FAILED: $*"; exit 1; }
step() { echo; echo "==> $*"; }

azm_require_private_repo

# ---- Inputs -----------------------------------------------------------------
N_IMG="$(git ls-files 'media/images/*.jpg' | wc -l | tr -d ' ')"
N_GIF="$(git ls-files 'media/videos/*.gif' | wc -l | tr -d ' ')"
[ "$N_IMG" -gt 0 ] && [ "$N_GIF" -gt 0 ] || fail "no committed media in media/images + media/videos"
git diff --quiet HEAD -- media || fail "media/ differs from HEAD (commit or restore it first)"
[ -z "$(git ls-files --others --exclude-standard media)" ] || fail "untracked files in media/ (commit or remove them first)"
MEDIA_KB="$(du -sk media/images media/videos | awk '{s+=$1} END{print s}')"
echo "media: $N_IMG images + $N_GIF GIFs, $((MEDIA_KB / 1024)) MB (committed in azm)"
# Store APK ~63 MB + media (JPG/GIF don't compress further).
EST_MB=$((63 + MEDIA_KB / 1024))
if [ "$EST_MB" -gt "$MAX_MB" ]; then
  fail "estimated APK ~${EST_MB} MB > ${MAX_MB} MB: downscale the GIFs into .tooling/tmp first (not implemented: at ~200 MB it isn't needed)"
fi

FULL="$(awk '/^version:/{print $2; exit}' app/pubspec.yaml)"
NAME="${FULL%+*}-personal"
LAST="$(azm_gh gh release list --repo "$AZM_REPO" --limit 200 --json tagName -q '.[].tagName' \
  | sed -n 's/^personal-b\([0-9][0-9]*\)$/\1/p' | sort -n | tail -1)"
BUILD=$(( ${LAST:-0} + 1 ))
TAG="personal-b$BUILD"
APK="dist/azm-personal-${NAME%-personal}-$BUILD.apk"
COMMIT="$(git rev-parse --short HEAD)"
DIRTY=""; [ -z "$(git status --porcelain)" ] || DIRTY=" (+ uncommitted changes)"
echo "personal build $BUILD, version $NAME, azm $COMMIT$DIRTY → $APK ($MODE)"
if [ "$MODE" = publish ]; then
  [ -z "$DIRTY" ] || fail "working tree not clean (commit first; the tag must match the build)"
  azm_gh git fetch -q origin main
  git merge-base --is-ancestor HEAD origin/main || fail "HEAD $COMMIT is not on origin/main (push first)"
fi

# ---- Media into the flavor's asset folders (removed on exit) -----------------
cleanup() { find app/assets/media -type f ! -name .gitkeep -delete 2>/dev/null || true; }
trap cleanup EXIT
cleanup
git ls-files -z 'media/images/*.jpg' | xargs -0 -I{} cp {} app/assets/media/images/
git ls-files -z 'media/videos/*.gif' | xargs -0 -I{} cp {} app/assets/media/videos/

# ---- Build -------------------------------------------------------------------
step "Build personal APK"
[ -f "$AZM_TOOLING/secrets/azm-upload.jks" ] || fail "no upload keystore (tools/upload_key.sh create)"
EXPECTED_CERT="$(tools/upload_key.sh sha256)"
(cd app/android && ./gradlew --stop -q >/dev/null 2>&1) || true
(
  export AZM_UPLOAD_KEYSTORE="$AZM_TOOLING/secrets/azm-upload.jks"
  AZM_UPLOAD_STORE_PASSWORD="$(HOME="$AZM_REAL_HOME" /usr/bin/security find-generic-password -s azm.android.upload -a keystore -w)"
  export AZM_UPLOAD_STORE_PASSWORD
  cd app && flutter build apk --release --flavor personal --android-project-arg azmPersonal=true \
    --build-name "$NAME" --build-number "$BUILD"
) >"$LOG" 2>&1 &
pid=$!
for _ in $(seq 1 360); do kill -0 "$pid" 2>/dev/null || break; sleep 5; done
if kill -0 "$pid" 2>/dev/null; then kill "$pid"; echo "TIMEOUT (30 min)"; tail -50 "$LOG"; exit 1; fi
wait "$pid" || { tail -50 "$LOG"; fail "flutter build apk --flavor personal"; }
(cd app/android && ./gradlew --stop -q >/dev/null 2>&1) || true
cleanup
mkdir -p dist
cp app/build/app/outputs/flutter-apk/app-personal-release.apk "$APK"

# ---- Verify ------------------------------------------------------------------
step "Verify"
CERTS="$("$BUILD_TOOLS/apksigner" verify --print-certs "$APK" 2>/dev/null | awk -F': ' '/certificate SHA-256 digest/{print $NF}' | sort -u)"
[ "$CERTS" = "$EXPECTED_CERT" ] || fail "not signed with the upload key"
BADGING="$("$BUILD_TOOLS/aapt2" dump badging "$APK")"
echo "$BADGING" | head -1
echo "$BADGING" | head -1 | grep -q "name='app.azm.gym.personal'" || fail "package is not app.azm.gym.personal"
echo "$BADGING" | head -1 | grep -q "versionCode='$BUILD'" || fail "versionCode is not $BUILD"
echo "$BADGING" | grep -E "^application-label(-ar)?:" | head -2
echo "$BADGING" | grep -q "^application-label:'Azm Dev'" || fail "launcher label is not 'Azm Dev'"
echo "$BADGING" | grep -q "^application-label-ar:'عزم تجريبي'" || fail "Arabic launcher label is not 'عزم تجريبي'"
IN_IMG="$(unzip -Z1 "$APK" | grep -c '^assets/flutter_assets/assets/media/images/.*\.jpg$' || true)"
IN_GIF="$(unzip -Z1 "$APK" | grep -c '^assets/flutter_assets/assets/media/videos/.*\.gif$' || true)"
[ "$IN_IMG" = "$N_IMG" ] && [ "$IN_GIF" = "$N_GIF" ] || fail "APK has $IN_IMG images / $IN_GIF GIFs, expected $N_IMG / $N_GIF"
SIZE_MB="$(awk -v b="$(stat -f %z "$APK")" 'BEGIN{printf "%.1f", b/1048576}')"
MIN_SDK="$(echo "$BADGING" | awk -F"'" '/^minSdkVersion:|^sdkVersion:/{print $2; exit}')"
echo "bundled media: $IN_IMG images + $IN_GIF GIFs; size $SIZE_MB MB; minSdk $MIN_SDK"
awk -v s="$SIZE_MB" -v m="$MAX_MB" 'BEGIN{exit !(s <= m)}' || fail "APK is $SIZE_MB MB > $MAX_MB MB"

if [ "$MODE" = build ]; then
  echo; echo "BUILD ONLY: $APK ($SIZE_MB MB). Not published."
  exit 0
fi

# ---- Publish (azm, private) -----------------------------------------------------
step "Release $TAG in $AZM_REPO"
azm_require_private_repo
NOTES="$TMPDIR/personal-notes.md"
cat >"$NOTES" <<EOF
**عزم تجريبي (Azm Dev) — للمالك بس / owner only.** Bundled Gym visual media (NOT licensed): never share this APK or link.

- Version $NAME, build $BUILD, package \`app.azm.gym.personal\` (installs next to the tester app)
- azm $COMMIT (media committed in azm)
- $IN_IMG images + $IN_GIF GIFs, works offline; $SIZE_MB MB, minSdk $MIN_SDK
EOF
azm_gh gh release create "$TAG" "$APK" --repo "$AZM_REPO" --target "$(git rev-parse HEAD)" --prerelease \
  --title "Azm Dev (personal) build $BUILD" --notes-file "$NOTES" >/dev/null
URL="$(azm_gh gh release view "$TAG" --repo "$AZM_REPO" --json url -q .url)"
[ -n "$URL" ] || fail "release $TAG not found in $AZM_REPO"
azm_require_private_repo
echo "Released $TAG: $URL ($SIZE_MB MB)"
