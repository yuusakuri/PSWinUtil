# Android SDK tool compatibility

`Install-WUAndroidSdk` uses `ANDROID_HOME` when it is set. Otherwise it uses `%LOCALAPPDATA%\Android\Sdk`, the usual Windows SDK location. After a successful installation it saves the selected location as the user `ANDROID_HOME`. Set `ANDROID_HOME` before running the function only when the SDK should be installed elsewhere. `ANDROID_USER_HOME` and `ANDROID_SDK_HOME` control user preferences rather than the SDK installation location, so the function leaves them unchanged. See the [Android environment variable reference](https://developer.android.com/tools/variables) and [Windows SDK location](https://developer.android.com/studio/emulator_archive).

`Install-WUAndroidSdk` installs the official Android CLI through WinGet, then uses `android sdk` to install the SDK packages required by the module. It also installs the Android SDK Command-Line Tools package at `cmdline-tools/latest` and adds `cmdline-tools\latest\bin` to both user and process `PATH` values. This keeps `sdkmanager`, `avdmanager`, `lint`, and the other established tools available alongside `android.exe`.

Android CLI package names use slash-separated paths. To inspect or install the command-line tools directly, use:

```powershell
android sdk list 'cmdline-tools/*' --all
android sdk install 'cmdline-tools/latest'
```

The Android SDK Command-Line Tools provide `sdkmanager`, which uses semicolon-separated package names such as `cmdline-tools;latest`. Android CLI uses slash-separated names, so use the syntax appropriate to the command you run.

Android CLI also documents an `android emulator` command, but its Windows implementation is currently disabled. `Install-WUAndroidSdk` therefore installs the `emulator` SDK package and leaves the module's existing PowerShell emulator functions in place; it does not depend on an Android CLI emulator subcommand.

Flutter issue #191558 reports that `flutter doctor --android-licenses` did not recognize Command-Line Tools 23.0 in an affected environment and that version 22.0 worked there. This is a reported compatibility workaround, not a general claim that every version from 23.0 onward fails. To install 22.0 with `sdkmanager`, run:

```powershell
sdkmanager.bat --install 'cmdline-tools;22.0'
```

The package is installed under `cmdline-tools\22.0`; installing it does not automatically change a tool that reads `cmdline-tools\latest\bin`. Check which path the affected Flutter installation uses before changing an existing SDK installation.

References: [Android CLI overview](https://developer.android.com/tools/agents/android-cli), [Android CLI SDK commands](https://developer.android.com/tools/agents/android-cli#sdk), [Android SDK Command-Line Tools](https://developer.android.com/tools/sdkmanager), and [Flutter issue #191558](https://github.com/flutter/flutter/issues/191558).
