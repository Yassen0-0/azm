#!/bin/bash
# Android UPLOAD key for Azm release/tester builds.
#
#   tools/upload_key.sh create   # once: keystore + random password (Keychain)
#   tools/upload_key.sh backup   # run YOURSELF in Terminal: encrypted zip you
#                                # copy to Google Drive + the SSD
#   tools/upload_key.sh info     # certificate fingerprints (no secrets)
#
# Keystore : .tooling/secrets/azm-upload.jks (gitignored, never pushed), PKCS12,
#            RSA 4096, alias "azm-upload", valid 10,000 days.
# Password : ONLY in the macOS login Keychain (generic password, service
#            "azm.android.upload", account "keystore"). Credentials are the
#            sandbox exception (CLAUDE.md): the Keychain needs the real HOME,
#            so `security` runs with HOME=$AZM_REAL_HOME, like ./gh_env.
#            PKCS12 uses one password for the store and the key.
#
# LOSING THE KEYSTORE OR ITS PASSWORD = installed copies can never be updated
# (Android refuses an update signed with a different key). Keep the backup.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source "$ROOT/env.sh" || exit 1   # fails fast if flutter is not the sandbox one

SECRETS="$AZM_TOOLING/secrets"
KEYSTORE="$SECRETS/azm-upload.jks"
ALIAS="azm-upload"
KC_SERVICE="azm.android.upload"
KC_ACCOUNT="keystore"

keychain() { HOME="$AZM_REAL_HOME" /usr/bin/security "$@"; }
password() { keychain find-generic-password -s "$KC_SERVICE" -a "$KC_ACCOUNT" -w; }

case "${1:-}" in
  create)
    [ -e "$KEYSTORE" ] && { echo "Refusing: $KEYSTORE already exists (never replace an upload key)."; exit 1; }
    if keychain find-generic-password -s "$KC_SERVICE" -a "$KC_ACCOUNT" >/dev/null 2>&1; then
      echo "Refusing: a Keychain item $KC_SERVICE/$KC_ACCOUNT already exists."; exit 1
    fi
    mkdir -p "$SECRETS" && chmod 700 "$SECRETS"
    AZM_KS_PASS="$(/usr/bin/openssl rand -hex 24)"   # 192 random bits; never printed
    export AZM_KS_PASS
    keychain add-generic-password -s "$KC_SERVICE" -a "$KC_ACCOUNT" \
      -l "Azm Android upload keystore" -j "tools/upload_key.sh (.tooling/secrets/azm-upload.jks)" -w "$AZM_KS_PASS"
    keytool -genkeypair -keystore "$KEYSTORE" -storetype PKCS12 -alias "$ALIAS" \
      -keyalg RSA -keysize 4096 -validity 10000 \
      -dname "CN=Yassen, O=Azm, C=EG" -storepass:env AZM_KS_PASS -keypass:env AZM_KS_PASS 2>&1 | grep -v JAVA_TOOL_OPTIONS || true
    unset AZM_KS_PASS
    chmod 600 "$KEYSTORE"
    [ "$(password)" != "" ] && echo "Keystore: $KEYSTORE; password: in the Keychain ($KC_SERVICE)."
    "$0" info
    ;;
  backup)
    [ -f "$KEYSTORE" ] || { echo "No keystore at $KEYSTORE"; exit 1; }
    [ -t 0 ] || { echo "Run this yourself in Terminal: zip asks YOU for the backup password."; exit 1; }
    OUT="$SECRETS/azm-upload-key-backup-$(date +%Y%m%d).zip"
    TMP="$(mktemp -d "$SECRETS/backup.XXXXXX")"
    trap 'rm -rf "$TMP"' EXIT
    cp "$KEYSTORE" "$TMP/azm-upload.jks"
    # The password must travel with the key, or the backup is useless. This
    # plaintext file lives only in this temp dir (inside gitignored .tooling)
    # for the seconds zip needs, then it is deleted.
    { echo "Azm Android upload key"
      echo "keystore: azm-upload.jks (PKCS12)"
      echo "alias:    $ALIAS"
      echo "password (store + key): $(password)"
      echo "created by tools/upload_key.sh; restore: copy the .jks to .tooling/secrets/ and"
      echo "  security add-generic-password -s $KC_SERVICE -a $KC_ACCOUNT -w '<password>'"
      echo; AZM_KS_PASS="$(password)" keytool -list -v -keystore "$KEYSTORE" -storepass:env AZM_KS_PASS -alias "$ALIAS" 2>/dev/null | grep -E 'SHA256:|Valid'
    } > "$TMP/README-PASSWORD.txt"
    chmod 600 "$TMP"/*
    echo "Choose a LONG backup password (zip encryption is only as strong as it). You type it twice:"
    (cd "$TMP" && zip -e -q "$OUT" azm-upload.jks README-PASSWORD.txt)
    rm -rf "$TMP"; trap - EXIT
    echo "Backup: $OUT"
    echo "Now copy it to Google Drive AND the SSD, and keep the backup password somewhere safe (not with the zip)."
    ;;
  info)
    [ -f "$KEYSTORE" ] || { echo "No keystore at $KEYSTORE"; exit 1; }
    AZM_KS_PASS="$(password)" keytool -list -v -keystore "$KEYSTORE" -storepass:env AZM_KS_PASS -alias "$ALIAS" 2>/dev/null \
      | grep -E 'Alias name|Owner|Valid from|SHA256:'
    ;;
  sha256)  # certificate SHA-256 as bare hex (used by tools/release_apk.sh)
    AZM_KS_PASS="$(password)" keytool -list -v -keystore "$KEYSTORE" -storepass:env AZM_KS_PASS -alias "$ALIAS" 2>/dev/null \
      | awk '/SHA256:/{print $2; exit}' | tr -d ':' | tr 'A-F' 'a-f'
    ;;
  *) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 64 ;;
esac
