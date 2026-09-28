#!/bin/bash
# History audit: run before anything is pushed (tools/release_*.sh and
# `./gh_env git push` run it). Scans EVERY commit reachable from any local ref
# (branches, tags, remote-tracking refs) and fails on:
#   1. forbidden paths ever committed: .tooling/, .worktrees/, inputs/, .env /
#      .env.* (except .env.example), secrets/, keystores and signing files
#      (*.jks, *.keystore, *.p12, *.pem, *.p8, *.cer, *.mobileprovision,
#      key.properties, upload-keystore*), *.secret, Firebase configs, r2*.json / .r2*;
#   2. the upload keystore itself (.tooling/secrets/azm-upload.jks), by content;
#   3. secret patterns in any text file version: GitHub/AWS/Google/Slack/
#      Anthropic/OpenAI keys, private keys, store/key passwords with a value.
# media/ (Gym visual images + GIFs) IS allowed in history since 2026-09-28
# (owner's decision, docs/LICENSES.md): the repo must stay PRIVATE instead
# (tools/lib/github_guard.sh).
#
#   tools/audit_history.sh              # self-test, then the audit: exit 0 = clean, 1 = findings (listed)
#   tools/audit_history.sh --self-test  # only the pattern self-test
#
# No skip list: every blob outside media/ is scanned, whatever its path.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/$(basename "${BASH_SOURCE[0]}")"
cd "$ROOT"

# Values read from the environment (System.getenv, $VAR, "$(…)") are fine;
# only literal values count. The pattern is written so that this file never
# matches itself ([=] instead of a literal "=" after the variable name).
SECRET_RE='gh[pousr]_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{35}|xox[abprs]-[A-Za-z0-9-]{10,}|sk-ant-[A-Za-z0-9_-]{20,}|sk-[A-Za-z0-9]{40,}|-----BEGIN ([A-Z]+ )?PRIVATE KEY-----|(store|key)Password[ \t]*[=:][ \t]*("[^"$]{4,}"|[^\s"$(]{6,}[ \t]*$)|AZM_UPLOAD_STORE_PASSWORD[=][^\s"$(]'

# The same engine as the scan below (perl, multi-line): exit 0 = match.
secret_match() { SECRET_RE="$SECRET_RE" perl -0777 -ne 'exit(/$ENV{SECRET_RE}/m ? 0 : 1)'; }

# Self-test: real-looking secrets must be caught, env reads must not, and this
# file must not match its own pattern. Samples are assembled at run time so no
# literal secret appears in this file.
self_test() {
  local v="AZM_UPLOAD_STORE_""PASSWORD" sp="store""Password" kp="key""Password" bad=0 s
  local tok; tok="ghp_$(printf 'a%.0s' $(seq 1 36))"
  local must_hit=(
    "$v=Hunter2-real-value"
    "export $v=s3cretValue42"
    "  $v='single-quoted-secret'"
    "$sp=hunter22pass"
    "$kp = \"s3cretpw\""
    "token: $tok"
    "-----BEGIN RSA ""PRIVATE KEY-----"
  )
  local must_pass=(
    "$v=\"\$(security find-generic-password -s azm.android.upload -a keystore -w)\""
    "$v=\$PASSWORD_FROM_ENV"
    "$sp = System.getenv(\"$v\")"
    "$kp = System.getenv(\"$v\") // PKCS12: same password"
  )
  for s in "${must_hit[@]}"; do
    printf '%s\n' "$s" | secret_match || { echo "SELF-TEST FAIL: not caught: ${s:0:40}…"; bad=1; }
  done
  for s in "${must_pass[@]}"; do
    if printf '%s\n' "$s" | secret_match; then echo "SELF-TEST FAIL: false positive: ${s:0:60}"; bad=1; fi
  done
  [ -r "$SELF" ] || { echo "SELF-TEST FAIL: can't read $SELF"; exit 1; }
  if secret_match < "$SELF"; then echo "SELF-TEST FAIL: tools/audit_history.sh matches its own pattern"; bad=1; fi
  [ "$bad" = 0 ] || { echo "History audit: pattern self-test FAILED (fix SECRET_RE before trusting the audit)."; exit 1; }
  echo "Pattern self-test: ${#must_hit[@]} secrets caught, ${#must_pass[@]} env reads + this file not flagged."
}
self_test
[ "${1:-}" = "--self-test" ] && exit 0

REVS="$(git rev-list --all)"
N_COMMITS="$(echo "$REVS" | grep -c .)"
FOUND=0
report() { echo "AUDIT FAIL: $1"; echo "$2" | head -20 | sed 's/^/  /'; FOUND=1; }

# ---- 1. Forbidden paths ------------------------------------------------------
PATHS="$(git rev-list --objects --all | awk 'NF > 1 { $1 = ""; sub(/^ /, ""); print }' | sort -u)"
BAD_PATH_RE='(^|/)\.tooling/|^\.tooling$|(^|/)\.worktrees/|^inputs/|(^|/)\.env$|(^|/)\.env\.|(^|/)secrets/|\.(jks|keystore|p12|pem|p8|cer|mobileprovision|secret)$|(^|/)key\.properties$|(^|/)upload-keystore|(^|/)GoogleService-Info\.plist$|(^|/)google-services\.json$|(^|/)firebase_options\.dart$|(^|/)r2[^/]*\.json$|(^|/)\.r2'
BAD_PATHS="$(echo "$PATHS" | grep -E "$BAD_PATH_RE" | grep -vE '(^|/)\.env\.example$' || true)"
[ -z "$BAD_PATHS" ] || report "forbidden paths in history" "$BAD_PATHS"

# ---- 2. The upload keystore, by content ----------------------------------------
KS="$ROOT/.tooling/secrets/azm-upload.jks"
if [ -f "$KS" ]; then
  KS_BLOB="$(git hash-object "$KS")"
  if git rev-list --objects --all | awk '{print $1}' | grep -qx "$KS_BLOB"; then
    report "the upload keystore is in history" "blob $KS_BLOB"
  fi
fi

# ---- 3. Secret patterns in text files ----------------------------------------------
# Every unique blob (outside media/) once, via one `git cat-file --batch`
# stream; binaries (a NUL byte) are skipped. Pattern: SECRET_RE above.
HITS="$(git rev-list --objects --all \
  | git cat-file --batch-check='%(objecttype) %(objectname) %(rest)' \
  | awk '$1 == "blob" && $3 !~ /^media\// { print $2, $3 }' \
  | SECRET_RE="$SECRET_RE" perl -e '
      my (%path, @order);
      while (<STDIN>) { chomp; my ($sha, $p) = split / /, $_, 2; push @order, $sha unless exists $path{$sha}; $path{$sha} //= $p; }
      open(my $cat, "-|", "sh", "-c", "printf \"%s\\n\" \"\$@\" | git cat-file --batch", "sh", @order) or die;
      my $re = qr/$ENV{SECRET_RE}/m;
      while (my $h = <$cat>) {
        my ($sha, $type, $size) = split / /, $h;
        read($cat, my $body, $size); read($cat, my $nl, 1);
        next if index($body, "\0") >= 0;
        print "$path{$sha}\n" if $body =~ $re;
      }' | sort -u)"
[ -z "$HITS" ] || report "secret-like strings in history (files)" "$HITS"

N_MEDIA="$(echo "$PATHS" | grep -cE '^media/(images|videos)/' || true)"
if [ "$FOUND" = 0 ]; then
  echo "History audit: clean ($N_COMMITS commits, all refs; media/ allowed: $N_MEDIA paths)."
else
  echo "History audit: FAILED. Nothing may be pushed until history is fixed."
  exit 1
fi
