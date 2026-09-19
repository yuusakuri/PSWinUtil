# Android SDK tool compatibility

`Install-WUAndroidSdk` uses `ANDROID_HOME` when it is set and `%LOCALAPPDATA%\Android\Sdk` otherwise. See the [Android environment variable reference](https://developer.android.com/tools/variables) and [Windows SDK location](https://developer.android.com/studio/emulator_archive).

`Install-WUAndroidSdk` installs the official Android CLI through WinGet, then uses `android sdk` to install the SDK packages required by the module. It also installs the Android SDK Command-Line Tools package at `cmdline-tools/latest` and adds `cmdline-tools\latest\bin` to both user and process `PATH` values. This keeps `sdkmanager`, `avdmanager`, `lint`, and the other established tools available alongside `android.exe`.

To inspect or install Command-Line Tools directly, use:

```powershell
android sdk list 'cmdline-tools/*' --all
android sdk install 'cmdline-tools/latest'
```

Android CLI also documents an `android emulator` command, but its Windows implementation is currently disabled. `Install-WUAndroidSdk` therefore installs the `emulator` SDK package and leaves the module's existing PowerShell emulator functions in place; it does not depend on an Android CLI emulator subcommand.

References: [Android CLI overview](https://developer.android.com/tools/agents/android-cli), [Android CLI SDK commands](https://developer.android.com/tools/agents/android-cli#sdk), and [Android SDK Command-Line Tools](https://developer.android.com/tools/sdkmanager).
