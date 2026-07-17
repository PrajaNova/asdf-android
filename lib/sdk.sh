#!/usr/bin/env bash
# Shared helpers for the asdf-android plugin. Sourced by bin/install and tests so
# host detection and wrapper generation can be exercised without downloading the
# multi-GB SDK.

# URL for Google's command-line tools zip. The build number is pinned; Google
# publishes new ones periodically.
# ponytail: pinned build number, override with ANDROID_CMDLINE_TOOLS_BUILD when it 404s.
android_cmdline_tools_url() {
  build="${ANDROID_CMDLINE_TOOLS_BUILD:-11076708}"
  case "$(uname -s)" in
    Darwin) host=mac ;;
    Linux)  host=linux ;;
    *) echo "unsupported OS for Android cmdline-tools: $(uname -s)" >&2; return 1 ;;
  esac
  echo "https://dl.google.com/android/repository/commandlinetools-${host}-${build}_latest.zip"
}

# System-image ABI for the host architecture.
android_sysimg_abi() {
  case "$(uname -m)" in
    arm64|aarch64) echo "arm64-v8a" ;;
    *)             echo "x86_64" ;;
  esac
}

# sdkmanager needs a real JDK. On macOS /usr/bin/java is a stub even with no JDK,
# so actually run it rather than trusting `command -v`.
android_require_jdk() {
  if ! java -version >/dev/null 2>&1; then
    echo "error: a JDK is required (Android sdkmanager needs Java)." >&2
    echo "  Install a JDK, or run: avm java use <version>" >&2
    return 1
  fi
}

# Write a wrapper that pins ANDROID_HOME to this version's SDK and execs the real
# tool, so a selected version puts SDK-aware adb/sdkmanager/etc. on PATH.
_android_wrapper() {
  dest="$1"; sdk="$2"; target="$3"
  cat > "$dest" <<EOF
#!/usr/bin/env sh
export ANDROID_HOME="$sdk"
export ANDROID_SDK_ROOT="$sdk"
exec "$target" "\$@"
EOF
  chmod +x "$dest"
}

# Generate the bin/ dir avm reads. The `android` marker satisfies avm's
# is_installed check (~/.avm/tools/android/<v>/bin/android) and delegates to
# sdkmanager.
android_write_wrappers() {
  bindir="$1"; sdk="$2"
  mkdir -p "$bindir"
  _android_wrapper "$bindir/adb"        "$sdk" "$sdk/platform-tools/adb"
  _android_wrapper "$bindir/sdkmanager" "$sdk" "$sdk/cmdline-tools/latest/bin/sdkmanager"
  _android_wrapper "$bindir/avdmanager" "$sdk" "$sdk/cmdline-tools/latest/bin/avdmanager"
  _android_wrapper "$bindir/emulator"   "$sdk" "$sdk/emulator/emulator"
  _android_wrapper "$bindir/android"    "$sdk" "$sdk/cmdline-tools/latest/bin/sdkmanager"
}
