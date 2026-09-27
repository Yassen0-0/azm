#!/bin/bash
# Host side of the Android E2E run (app/integration_test/workout_flow_screens_test.dart).
# A Flutter test can't tap system dialogs or press Back on a system activity, so
# this script, started BEFORE `flutter drive`:
#   1. grants POST_NOTIFICATIONS as soon as the app is installed;
#   2. waits for the "Alarms & reminders" system screen (opened by the English
#      run when built with --dart-define=AZM_E2E_OPEN_ALARM_SETTINGS=true),
#      captures it to <out.png> and presses Back.
#
#   tools/e2e_android_helper.sh <serial> <out.png>     e.g. emulator-5556 docs/screenshots/workout_flow/android/en_02b_exact_alarm_system_screen.png
#
# Every wait is bounded (CLAUDE.md → Waiting and polling): AZM_HELPER_TIMEOUT
# seconds (default 600) for the install, and again for the system screen.
# Exits 1 on timeout or when the device goes away.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source "$ROOT/env.sh" || exit 1   # fails fast if flutter is not the sandbox one

S="${1:?usage: tools/e2e_android_helper.sh <serial> <out.png>}"
OUT="${2:?usage: tools/e2e_android_helper.sh <serial> <out.png>}"
PKG=app.azm.gym
LIMIT="${AZM_HELPER_TIMEOUT:-600}"
POLLS=$((LIMIT * 2)) # one poll every 0.5 s

installed=0
gone() { adb -s "$S" get-state >/dev/null 2>&1 || { echo "[helper] FAILED: device $S is gone"; exit 1; }; }

for _ in $(seq 1 "$POLLS"); do
  gone
  if adb -s "$S" shell pm list packages 2>/dev/null | grep -q "^package:$PKG\$"; then installed=1; break; fi
  sleep 0.5
done
[ "$installed" = 1 ] || { echo "[helper] TIMEOUT: $PKG not installed on $S after $LIMIT s"; exit 1; }

adb -s "$S" shell pm grant "$PKG" android.permission.POST_NOTIFICATIONS && echo "[helper] granted POST_NOTIFICATIONS"
adb -s "$S" shell appops get "$PKG" SCHEDULE_EXACT_ALARM | sed "s/^/[helper] /"

for _ in $(seq 1 "$POLLS"); do
  gone
  f="$(adb -s "$S" shell dumpsys window 2>/dev/null | grep -m1 mCurrentFocus)"
  if echo "$f" | grep -qiE 'settings'; then
    echo "[helper] system screen: $f"
    sleep 2
    adb -s "$S" exec-out screencap -p > "$OUT"
    adb -s "$S" shell input keyevent KEYCODE_BACK
    echo "[helper] captured + BACK"
    exit 0
  fi
  sleep 0.5
done
echo "[helper] TIMEOUT: no settings screen seen on $S after $LIMIT s"
exit 1
