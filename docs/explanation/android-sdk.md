# Android SDK tool compatibility

`Install-WUAndroidSdk` installs the official Android CLI through WinGet, then uses `android sdk` to install the SDK packages required by the module under the configured `ANDROID_HOME`. Command-Line Tools default to `cmdline-tools/latest`; `-CommandLineToolsVersion '22.0'` selects `cmdline-tools/22.0` instead. The function adds the selected version's `bin` directory to the user `PATH` and refreshes the process environment. This keeps `sdkmanager`, `avdmanager`, `lint`, and the other established tools available alongside `android.exe`.

Android CLI package names use slash-separated paths. To inspect or install the command-line tools directly, use:

```powershell
android sdk list 'cmdline-tools/*' --all
android sdk install 'cmdline-tools/latest'
android sdk install 'cmdline-tools/22.0'
```

The older `sdkmanager` command uses semicolon-separated package names, for example `cmdline-tools;latest`. Keep that syntax when invoking `sdkmanager.bat` directly.

Android CLI also documents an `android emulator` command, but its Windows implementation is currently disabled. `Install-WUAndroidSdk` therefore installs the `emulator` SDK package and leaves the module's existing PowerShell emulator functions in place; it does not depend on an Android CLI emulator subcommand.

Flutter issue #191558 reports a `flutter doctor --android-licenses` failure with Command-Line Tools 23.0 and describes version 22.0 as a workaround for affected Flutter installations. Select that version with:

```powershell
Install-WUAndroidSdk -CommandLineToolsVersion '22.0'
```

This installs versioned files under `cmdline-tools\22.0` and leaves other Command-Line Tools installations intact. If a consumer requires the conventional `cmdline-tools\latest\bin` location, configure that consumer to use the selected installation or place the selected version at `latest` after installation. Adding a version to PATH does not change a consumer that explicitly uses `latest`.

The API level and package revision are separate settings. `-PlatformVersion 36` selects `platforms/android-36`, whereas `-PlatformPackageVersion '2.0.0'` selects revision 2.0.0 of that package. `-BuildToolsVersion`, `-PlatformToolsVersion`, and `-EmulatorVersion` select their respective SDK component versions. Android CLI uses `package@version` for package revisions and `--force` to permit downgrades. Explicit revision parameters apply even when package files already exist; the shared SDK packages can therefore change for other projects and AVDs. Omitted versions preserve existing components and install the latest stable version when missing.

References: [Android CLI overview](https://developer.android.com/tools/agents/android-cli), [Android CLI SDK commands](https://developer.android.com/tools/agents/android-cli#sdk), [Android SDK Command-Line Tools](https://developer.android.com/tools/sdkmanager), and [Flutter issue #191558](https://github.com/flutter/flutter/issues/191558).
