# Sourced by tools/*.sh that talk to GitHub (after env.sh). Needs $ROOT.
# azm_require_private_repos: aborts unless BOTH repos report PRIVATE and
# azm-media has no collaborator other than the owner (docs/LICENSES.md).
AZM_GH_OWNER="Yassen0-0"
AZM_REPO="$AZM_GH_OWNER/azm"
AZM_MEDIA_REPO="$AZM_GH_OWNER/azm-media"

azm_gh() {  # gh/git with the Keychain token on the Mac; plain on Linux (cloud)
  if [ "$(uname -s)" = Darwin ]; then "$ROOT/gh_env" "$@"; else "$@"; fi
}

azm_require_private_repos() {
  local r v
  for r in "$AZM_REPO" "$AZM_MEDIA_REPO"; do
    v="$(azm_gh gh repo view "$r" --json visibility -q .visibility 2>/dev/null || true)"
    if [ "$v" != PRIVATE ]; then
      echo "ABORT: $r reports visibility '${v:-unknown}', must be PRIVATE (docs/LICENSES.md)."; exit 1
    fi
  done
  local others
  others="$(azm_gh gh api "repos/$AZM_MEDIA_REPO/collaborators" --jq ".[].login | select(. != \"$AZM_GH_OWNER\")" 2>/dev/null || echo "?")"
  if [ -n "$others" ]; then
    echo "ABORT: $AZM_MEDIA_REPO has other collaborators (or couldn't be checked): $others. It is owner-only."; exit 1
  fi
  echo "GitHub: $AZM_REPO and $AZM_MEDIA_REPO are PRIVATE; azm-media is owner-only."
}
