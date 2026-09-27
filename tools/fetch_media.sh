#!/bin/bash
# Get the owner's PRIVATE media copy (Yassen0-0/azm-media) into media/.
#
#   tools/fetch_media.sh        # clone (first time) or fast-forward pull
#
# media/ is gitignored in azm and must never be committed there, uploaded
# anywhere else, shipped in a public build, or fed to AI generation
# (docs/LICENSES.md). Owner only. Mac: git talks to GitHub through ./gh_env
# (token in the Keychain). Cloud/Linux: plain git with whatever GitHub
# credentials the session has; the cloud normally doesn't need media at all
# (tools/cloud_setup.sh --with-media opts in).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$ROOT"
source "$ROOT/env.sh" || exit 1   # fails fast if flutter is not the sandbox one
source "$ROOT/tools/lib/github_guard.sh"

azm_require_private_repos
git check-ignore -q media/x || { echo "ABORT: media/ is not gitignored in azm."; exit 1; }

URL="https://github.com/$AZM_MEDIA_REPO.git"
if [ -d media/.git ]; then
  echo "==> Updating media/ from $AZM_MEDIA_REPO"
  azm_gh git -C media pull --ff-only -q origin main
elif [ -e media ] && [ -n "$(ls -A media 2>/dev/null)" ]; then
  echo "ABORT: media/ exists but isn't a clone of $AZM_MEDIA_REPO. Move it away, then re-run."; exit 1
else
  echo "==> Cloning $AZM_MEDIA_REPO into media/"
  rm -rf media
  azm_gh git clone -q "$URL" media
fi
n_img="$(find media/images -name '*.jpg' | wc -l | tr -d ' ')"
n_gif="$(find media/videos -name '*.gif' | wc -l | tr -d ' ')"
echo "media/: $n_img images, $n_gif GIFs ($(du -sh media | cut -f1)), at $(git -C media rev-parse --short HEAD)"
