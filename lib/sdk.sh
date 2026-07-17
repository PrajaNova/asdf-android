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

# Ensure a runnable JDK is on PATH for sdkmanager. The asdf sandbox clears env,
# so a plain `java` is often absent (and macOS /usr/bin/java is a stub even with
# no JDK). Prefer a working system java; otherwise wire up an avm-managed JDK
# found under $HOME/.avm/tools/java (matching the global pin when possible).
# Exports JAVA_HOME + PATH so the rest of install can call sdkmanager.
android_ensure_jdk() {
  if java -version >/dev/null 2>&1; then
    return 0
  fi

  candidate=""
  pin="$(sed -n 's/.*"java"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$HOME/.avm.json" 2>/dev/null | head -1)"
  if [ -n "$pin" ] && [ -x "$HOME/.avm/tools/java/$pin/bin/java" ]; then
    candidate="$HOME/.avm/tools/java/$pin"
  else
    for d in "$HOME"/.avm/tools/java/*/; do
      if [ -x "${d}bin/java" ]; then candidate="${d%/}"; break; fi
    done
  fi

  if [ -n "$candidate" ] && [ -x "$candidate/bin/java" ]; then
    export JAVA_HOME="$candidate"
    export PATH="$candidate/bin:$PATH"
    return 0
  fi

  echo "error: a JDK is required (Android sdkmanager needs Java)." >&2
  echo "  Install a JDK, or run: avm java use <version>" >&2
  return 1
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
