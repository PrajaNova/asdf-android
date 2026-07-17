# asdf-android

An [avm](https://github.com/prajanova/avm) (asdf-compatible) plugin that installs
a self-contained Android SDK per API level, with `adb`, `sdkmanager`,
`avdmanager`, and `emulator` wired onto PATH when a version is selected.

## Install

```sh
avm plugin add https://github.com/prajanova/asdf-android
```

## Use

```sh
avm android versions            # installable API levels
AVM_ASDF_INSTALL_TIMEOUT=1800 \
  avm android install 34        # download SDK baseline for API 34 (several GB)
avm android use 34              # pin API 34 in this project (writes .avm.json)
avm android use 34 --global     # or pin globally

adb --version                   # resolves to API 34's platform-tools
sdkmanager --list               # manage extra components
avdmanager create avd -n test -k "system-images;android-34;google_apis;arm64-v8a"
emulator -avd test
```

## What `install <api>` lays down

```
~/.avm/tools/android/<api>/
  sdk/                  ANDROID_HOME: cmdline-tools, platform-tools,
                        platforms;android-<api>, build-tools;<api>.0.0,
                        emulator, system-images;android-<api>;google_apis;<abi>
  bin/                  adb sdkmanager avdmanager emulator android
                        (wrappers that export ANDROID_HOME and exec the real tool)
```

Selecting a version puts `bin/` on PATH, so the tools target that version's SDK.

## Requirements

- A JDK on PATH (`sdkmanager` needs Java). Install one, or `avm java use <v>`.
- `curl` and `unzip`.

## Overrides

| Env var | Default | Purpose |
|---|---|---|
| `ANDROID_BUILD_TOOLS_VERSION` | `<api>.0.0` | pin a specific build-tools |
| `ANDROID_CMDLINE_TOOLS_BUILD` | `11076708` | cmdline-tools build number if the URL 404s |
| `AVM_ASDF_INSTALL_TIMEOUT` | `120` (avm default) | seconds; raise for the large download |

## Test

```sh
./test/smoke.sh     # offline: checks list-all + wrapper generation
```

## License

MIT
