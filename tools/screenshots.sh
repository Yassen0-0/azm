#!/bin/bash
# PLATFORM PARITY RULE: capture every screen of a feature on BOTH platforms,
# in Arabic (RTL) and English (LTR), into docs/screenshots/<feature>/<platform>/.
#
#   tools/screenshots.sh <feature> [android|ios|both]      (default: both)
#
# <feature> = name of app/integration_test/<feature>_screens_test.dart.
# Devices (one pair per parallel window, see docs/PLAN.md):
#   AZM_DEVICE_SET=A (default) → AVD azm_api37   on port 5554 + simulator "Azm iPhone A"
#   AZM_DEVICE_SET=B           → AVD azm_api37_b on port 5556 + simulator "Azm iPhone B"
# Boots whatever is not running yet (emulator headless). Leaves them running.
#
# Every wait is capped (CLAUDE.md → Waiting and polling). On a timeout or a
# failure it prints the last 50 lines of the log, stops what it started, exits 1:
#   AZM_BOOT_TIMEOUT   seconds per device boot    (default 600)
#   AZM_DRIVE_TIMEOUT  seconds per flutter drive  (default 1800)
# Logs: .tooling/tmp/emu-<avd>.log, sim-boot-<set>.log, drive-<feature>-<platform>.log
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source "$ROOT/env.sh"

FEATURE="${1:?usage: tools/screenshots.sh <feature> [android|ios|both]}"
WHICH="${2:-both}"
TARGET="integration_test/${FEATURE}_screens_test.dart"
[ -f "$ROOT/app/$TARGET" ] || { echo "missing app/$TARGET"; exit 1; }
BOOT_TIMEOUT="${AZM_BOOT_TIMEOUT:-600}"
DRIVE_TIMEOUT="${AZM_DRIVE_TIMEOUT:-1800}"

case "${AZM_DEVICE_SET:-A}" in
  A) AVD=azm_api37;   PORT=5554; SIM="Azm iPhone A" ;;
  B) AVD=azm_api37_b; PORT=5556; SIM="Azm iPhone B" ;;
  *) echo "AZM_DEVICE_SET must be A or B"; exit 1 ;;
esac

kill_tree() { # kill_tree <pid>: the process and all its descendants
  local c
  for c in $(pgrep -P "$1" 2>/dev/null); do kill_tree "$c"; done
  kill "$1" 2>/dev/null || true
}

fail() { # fail <message> <log>
  echo "FAILED: $1"
  echo "--- last 50 lines of ${2#"$ROOT/"}:"
  tail -50 "$2" 2>/dev/null || true
  exit 1
}

run_capped() { # run_capped <label> <seconds> <log> <command...>: fails on timeout or non-zero exit
  local label="$1" secs="$2" log="$3" pid rc=0 t=0
  shift 3
  "$@" >"$log" 2>&1 &
  pid=$!
  while kill -0 "$pid" 2>/dev/null; do
    if [ "$t" -ge "$secs" ]; then kill_tree "$pid"; wait "$pid" 2>/dev/null || true; fail "TIMEOUT ($secs s): $label" "$log"; fi
    sleep 1
    t=$((t + 1))
  done
  wait "$pid" || rc=$?
  [ "$rc" = 0 ] || fail "$label (exit $rc)" "$log"
}

drive() { # drive <device-id> <platform>
  local log="$TMPDIR/drive-$FEATURE-$2.log"
  run_capped "flutter drive $FEATURE on $2" "$DRIVE_TIMEOUT" "$log" \
    bash -c 'cd "$1/app" && flutter drive --driver=test_driver/integration_test.dart --target="$2" -d "$3"' _ "$ROOT" "$TARGET" "$1"
  grep -vE 'Picked up JAVA_TOOL_OPTIONS' "$log" | grep -E 'screenshot →|All tests passed' || true
  # flutter drive can exit 0 without running the tests; require the pass line.
  grep -q 'All tests passed' "$log" || fail "flutter drive $FEATURE on $2: no 'All tests passed'" "$log"
}

if [ "$WHICH" = android ] || [ "$WHICH" = both ]; then
  SERIAL="emulator-$PORT"
  if ! adb devices | grep -q "^$SERIAL"; then
    echo "==> booting Android emulator $AVD ($SERIAL), max $BOOT_TIMEOUT s"
    EMU_LOG="$TMPDIR/emu-$AVD.log"
    emulator -avd "$AVD" -port "$PORT" -no-window -no-audio -no-snapshot-save -no-boot-anim >"$EMU_LOG" 2>&1 &
    EMU_PID=$!
    t=0
    until [ "$(adb -s "$SERIAL" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ]; do
      kill -0 "$EMU_PID" 2>/dev/null || fail "emulator $AVD exited during boot" "$EMU_LOG"
      if [ "$t" -ge "$BOOT_TIMEOUT" ]; then kill_tree "$EMU_PID"; wait "$EMU_PID" 2>/dev/null || true; fail "TIMEOUT ($BOOT_TIMEOUT s): emulator $AVD boot" "$EMU_LOG"; fi
      sleep 2
      t=$((t + 2))
    done
  fi
  echo "==> Android ($SERIAL)"
  drive "$SERIAL" android
fi

if [ "$WHICH" = ios ] || [ "$WHICH" = both ]; then
  UDID="$(xcrun simctl list devices available | grep -F "$SIM (" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')"
  [ -n "$UDID" ] || { echo "simulator \"$SIM\" not found (see README → Devices)"; exit 1; }
  if ! xcrun simctl list devices | grep -F "$UDID" | grep -q Booted; then
    echo "==> booting $SIM, max $BOOT_TIMEOUT s"
    SIM_LOG="$TMPDIR/sim-boot-${AZM_DEVICE_SET:-A}.log"
    # bootstatus -b boots the device and blocks until it is ready.
    ( run_capped "simulator $SIM boot" "$BOOT_TIMEOUT" "$SIM_LOG" xcrun simctl bootstatus "$UDID" -b ) || {
      xcrun simctl shutdown "$UDID" 2>/dev/null || true
      exit 1
    }
  fi
  echo "==> iOS ($SIM)"
  drive "$UDID" ios
fi

echo "==> files: docs/screenshots/$FEATURE/"
ls -1 "$ROOT/docs/screenshots/$FEATURE"/*/ 2>/dev/null | sed 's/^/   /'
