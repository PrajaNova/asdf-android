#!/usr/bin/env bash
# Offline smoke test: exercises the two non-trivial bits (list-all + wrapper
# generation) without downloading the SDK.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=../lib/sdk.sh
. "$root/lib/sdk.sh"

# list-all prints ascending integer API levels including 34.
out="$("$root/bin/list-all")"
[[ " $out " == *" 34 "* ]] || { echo "FAIL: list-all missing 34: '$out'"; exit 1; }

# Wrapper generation: a generated adb execs the real adb with ANDROID_HOME set.
tmp="$(mktemp -d)"
sdk="$tmp/sdk"
mkdir -p "$sdk/platform-tools"
printf '#!/bin/sh\necho "real-adb ANDROID_HOME=$ANDROID_HOME"\n' > "$sdk/platform-tools/adb"
chmod +x "$sdk/platform-tools/adb"

android_write_wrappers "$tmp/bin" "$sdk"

[ -x "$tmp/bin/adb" ]     || { echo "FAIL: adb wrapper not executable"; exit 1; }
[ -x "$tmp/bin/android" ] || { echo "FAIL: android marker missing"; exit 1; }
got="$("$tmp/bin/adb")"
[ "$got" = "real-adb ANDROID_HOME=$sdk" ] || { echo "FAIL: wrapper env/exec wrong: '$got'"; exit 1; }

rm -rf "$tmp"
echo "OK"
