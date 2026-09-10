# Android SDK tool compatibility

`Install-WUAndroidSdk` installs the official Android CLI through WinGet, then uses `android sdk` to install the SDK packages required by the module. It also installs the Android SDK Command-Line Tools package at `cmdline-tools/latest` and adds `cmdline-tools\latest\bin` to both user and process `PATH` values. This keeps `sdkmanager`, `avdmanager`, `lint`, and the other established tools available alongside `android.exe`.

Android CLI package names use slash-separated paths. To inspect or install the command-line tools directly, use:

```powershell
android sdk list 'cmdline-tools/*' --all
android sdk install 'cmdline-tools/latest'
```

The older `sdkmanager` command uses semicolon-separated package names, for example `cmdline-tools;latest`. Keep that syntax when invoking `sdkmanager.bat` directly.

Flutter compatibility currently requires special care. Flutter's `flutter doctor --android-licenses` does not recognize the license output from Command-Line Tools 23.0 and later. Flutter's documented workaround is to use Command-Line Tools 22.0 until Flutter's Android tool support is updated. The legacy tool can install that version with:

```powershell
sdkmanager.bat --uninstall 'cmdline-tools;*'
sdkmanager.bat --install 'cmdline-tools;22.0'
```

After changing the version, keep the selected tools under `cmdline-tools\latest\bin` so Flutter and other tools discover them through the standard SDK layout. Android CLI continues to manage the other SDK packages; the version pin is only for Flutter's current license detection compatibility.

References: [Android CLI overview](https://developer.android.com/tools/agents/android-cli), [Android CLI SDK commands](https://developer.android.com/tools/agents/android-cli#sdk), [Android SDK Command-Line Tools](https://developer.android.com/tools/sdkmanager), and [Flutter issue #191558](https://github.com/flutter/flutter/issues/191558).
