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
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source "$ROOT/env.sh"

FEATURE="${1:?usage: tools/screenshots.sh <feature> [android|ios|both]}"
WHICH="${2:-both}"
TARGET="integration_test/${FEATURE}_screens_test.dart"
[ -f "$ROOT/app/$TARGET" ] || { echo "missing app/$TARGET"; exit 1; }

case "${AZM_DEVICE_SET:-A}" in
  A) AVD=azm_api37;   PORT=5554; SIM="Azm iPhone A" ;;
  B) AVD=azm_api37_b; PORT=5556; SIM="Azm iPhone B" ;;
  *) echo "AZM_DEVICE_SET must be A or B"; exit 1 ;;
esac

drive() { # drive <device-id>
  (cd "$ROOT/app" && flutter drive --driver=test_driver/integration_test.dart --target="$TARGET" -d "$1") \
    2>&1 | grep -vE 'Picked up JAVA_TOOL_OPTIONS' | grep -E 'screenshot →|All tests passed|Some tests failed|Error|error:|FAIL|Exception' || true
}

if [ "$WHICH" = android ] || [ "$WHICH" = both ]; then
  SERIAL="emulator-$PORT"
  if ! adb devices | grep -q "^$SERIAL"; then
    echo "==> booting Android emulator $AVD ($SERIAL)"
    (emulator -avd "$AVD" -port "$PORT" -no-window -no-audio -no-snapshot-save -no-boot-anim >"$TMPDIR/emu-$AVD.log" 2>&1 &)
    adb -s "$SERIAL" wait-for-device
    until [ "$(adb -s "$SERIAL" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ]; do sleep 2; done
  fi
  echo "==> Android ($SERIAL)"
  drive "$SERIAL"
fi

if [ "$WHICH" = ios ] || [ "$WHICH" = both ]; then
  UDID="$(xcrun simctl list devices available | grep -F "$SIM (" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')"
  [ -n "$UDID" ] || { echo "simulator \"$SIM\" not found (see README → Devices)"; exit 1; }
  xcrun simctl list devices | grep -F "$UDID" | grep -q Booted || { echo "==> booting $SIM"; xcrun simctl boot "$UDID"; xcrun simctl bootstatus "$UDID" -b >/dev/null; }
  echo "==> iOS ($SIM)"
  drive "$UDID"
fi

echo "==> files: docs/screenshots/$FEATURE/"
ls -1 "$ROOT/docs/screenshots/$FEATURE"/*/ 2>/dev/null | sed 's/^/   /'
