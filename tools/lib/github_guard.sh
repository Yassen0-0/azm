# Sourced by tools/*.sh that talk to GitHub (after env.sh). Needs $ROOT.
# azm contains the unlicensed Gym visual media (media/, docs/LICENSES.md), so
# azm_require_private_repo aborts unless azm reports PRIVATE, has no
# collaborator other than the owner and no pending collaborator invitation.
# Any failure to check counts as a failure (never "probably fine").
AZM_GH_OWNER="Yassen0-0"
AZM_REPO="$AZM_GH_OWNER/azm"

azm_gh() {  # gh/git with the Keychain token on the Mac; plain on Linux (cloud)
  if [ "$(uname -s)" = Darwin ]; then "$ROOT/gh_env" "$@"; else "$@"; fi
}

azm_require_private_repo() {
  local v others invites
  v="$(azm_gh gh repo view "$AZM_REPO" --json visibility -q .visibility 2>/dev/null || true)"
  if [ "$v" != PRIVATE ]; then
    echo "ABORT: $AZM_REPO reports visibility '${v:-unknown}', must be PRIVATE (it contains unlicensed media: docs/LICENSES.md)."; exit 1
  fi
  others="$(azm_gh gh api "repos/$AZM_REPO/collaborators?affiliation=all&per_page=100" --jq ".[].login | select(. != \"$AZM_GH_OWNER\")" 2>/dev/null || echo "?")"
  if [ -n "$others" ]; then
    echo "ABORT: $AZM_REPO has other collaborators (or couldn't be checked): $others. It is owner-only (docs/LICENSES.md)."; exit 1
  fi
  invites="$(azm_gh gh api "repos/$AZM_REPO/invitations?per_page=100" --jq '.[].invitee.login' 2>/dev/null || echo "?")"
  if [ -n "$invites" ]; then
    echo "ABORT: $AZM_REPO has pending collaborator invitations (or couldn't be checked): $invites. It is owner-only (docs/LICENSES.md)."; exit 1
  fi
  echo "GitHub: $AZM_REPO is PRIVATE and owner-only." >&2   # stderr: never mixed into captured gh output
}
