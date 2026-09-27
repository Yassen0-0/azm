#!/bin/bash
# Claude Code PreToolUse hook (Bash), wired in .claude/settings.json.
# On the owner's Mac, blocks any command that runs `flutter` or `dart` unless
# the SAME command sources env.sh (or goes through ./ios_env / ./gh_env, which
# source it). That stops the ~/dev toolchain leak: a bare `flutter …` would
# resolve to ~/dev/flutter from the login shell's PATH.
#
# Cloud / Linux sessions are never blocked: the rule protects the Mac, and
# there env.sh is set up by tools/cloud_setup.sh.
#
# Input: the hook JSON on stdin (.tool_input.command). Output: a deny decision
# as JSON on stdout, or nothing (= allowed). Always exits 0.
[ "$(uname -s)" = Darwin ] || exit 0

cmd="$(/usr/bin/jq -r '.tool_input.command // empty' 2>/dev/null)"
[ -n "$cmd" ] || exit 0
# Heredoc bodies are data (scripts, docs, messages), not commands: drop them
# so e.g. a Markdown snippet mentioning `flutter test` isn't blocked.
cmd="$(printf '%s\n' "$cmd" | /usr/bin/awk '
  tag != "" { if ($0 ~ "^[[:space:]]*" tag "[[:space:]]*$") tag = ""; next }
  { print
    if (match($0, /<<-?[[:space:]]*["\047]?[A-Za-z_][A-Za-z0-9_]*["\047]?/)) {
      t = substr($0, RSTART, RLENGTH); sub(/<<-?[[:space:]]*/, "", t); gsub(/["\047]/, "", t); tag = t
    } }')"

# `flutter` / `dart` in command position: at the start, or after ; & | ( ` $(
# or an opening quote (bash -c '…'); a path prefix counts too
# (~/dev/flutter/bin/flutter, .tooling/flutter/bin/dart). Arguments such as
# `grep dart`, `foo.dart` or `app/lib/x.dart` don't match.
runs_sdk='(^|[;&|(`"'"'"']|\$\()[[:space:]]*([^[:space:];&|()`"'"'"']*/)?(flutter|dart)([[:space:];&|)`"'"'"']|$)'
if ! printf '%s' "$cmd" | grep -Eq "$runs_sdk"; then
  exit 0
fi

# Allowed when the same command sources env.sh or uses a wrapper that does.
sandboxed='(^|[;&|(`[:space:]])(source|\.)[[:space:]]+[^;&|]*env\.sh|(^|[;&|(`[:space:]])(\./|[^[:space:]]*/)?(ios_env|gh_env)([[:space:]]|$)'
if printf '%s' "$cmd" | grep -Eq "$sandboxed"; then
  exit 0
fi

/usr/bin/jq -n '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: "Azm sandbox (CLAUDE.md): flutter/dart must run with the ROOT toolchain. Start the command with `source ./env.sh && …` (run from the project root), or use ./ios_env / ./gh_env. A bare flutter/dart would use ~/dev/flutter. (False positive, e.g. the word in a message? Prefixing source ./env.sh && is harmless.)"
  }
}'
exit 0
