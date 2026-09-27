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
# Every wait is bounded (CLAUDE.md → Waiting and polling): 10 min for the
# install, 10 min for the system screen. Exits 1 on timeout.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source "$ROOT/env.sh"

S="${1:?usage: tools/e2e_android_helper.sh <serial> <out.png>}"
OUT="${2:?usage: tools/e2e_android_helper.sh <serial> <out.png>}"
PKG=app.azm.gym

installed=0
for _ in $(seq 1 2000); do # 2000 × 0.3 s ≈ 10 min
  if adb -s "$S" shell pm list packages 2>/dev/null | grep -q "^package:$PKG\$"; then installed=1; break; fi
  sleep 0.3
done
[ "$installed" = 1 ] || { echo "[helper] TIMEOUT: $PKG not installed on $S after 10 min"; exit 1; }

adb -s "$S" shell pm grant "$PKG" android.permission.POST_NOTIFICATIONS && echo "[helper] granted POST_NOTIFICATIONS"
adb -s "$S" shell appops get "$PKG" SCHEDULE_EXACT_ALARM | sed "s/^/[helper] /"

for _ in $(seq 1 1500); do # 1500 × 0.4 s ≈ 10 min
  f="$(adb -s "$S" shell dumpsys window 2>/dev/null | grep -m1 mCurrentFocus)"
  if echo "$f" | grep -qiE 'settings'; then
    echo "[helper] system screen: $f"
    sleep 2
    adb -s "$S" exec-out screencap -p > "$OUT"
    adb -s "$S" shell input keyevent KEYCODE_BACK
    echo "[helper] captured + BACK"
    exit 0
  fi
  sleep 0.4
done
echo "[helper] TIMEOUT: no settings screen seen on $S after 10 min"
exit 1
