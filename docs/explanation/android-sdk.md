# Android SDK installation and tool compatibility

## SDK location

`Install-WUAndroidSdk` uses `ANDROID_HOME` when it is set and `%LOCALAPPDATA%\Android\Sdk` otherwise. See the [Android environment variable reference](https://developer.android.com/tools/variables) and [Windows SDK location](https://developer.android.com/studio/emulator_archive).

## Installed packages and versions

The function installs Android CLI through WinGet and uses `android sdk` to install SDK Platform, Build Tools, Platform Tools, Emulator, and Android SDK Command-Line Tools packages. When `-PlatformVersion` or `-BuildToolsVersion` is omitted, it selects the latest stable API level or Build Tools version listed by Android CLI. Other components remain at their installed version when their version parameter is omitted; missing components use the latest stable version. Existing files for the selected packages are reused.

An API level and a package revision are different. `-PlatformVersion 36` selects `platforms/android-36`; `-PlatformPackageVersion '2.0.0'` selects revision 2.0.0 of that package. `-BuildToolsVersion`, `-PlatformToolsVersion`, and `-EmulatorVersion` select their respective component versions. Android CLI uses `package@version` to select a revision and `--force` to permit downgrades. Explicit revision parameters apply even if package files already exist, so they can change the shared SDK used by other projects and AVDs. See the [Android CLI SDK command reference](https://developer.android.com/tools/agents/android-cli#sdk-install).

## Android CLI and Command-Line Tools

Android CLI and Android SDK Command-Line Tools are installed together. `-CommandLineToolsVersion` defaults to `latest`; a value such as `22.0` selects `cmdline-tools/22.0` without removing other installed versions. The selected version's `bin` directory is added to the user PATH and made available to the current process. This provides `sdkmanager`, `avdmanager`, and other Command-Line Tools alongside `android.exe`.

To see the available Command-Line Tools versions, run:

```powershell
android sdk list 'cmdline-tools/*' --all
```

The [Android CLI known issues](https://developer.android.com/tools/agents/android-cli#known-issues) state that its `android emulator` command is currently disabled on Windows. The installer still installs the separate `emulator` package, and `avdmanager` remains available for AVD creation. The module uses `emulator.exe` to list or start AVDs; neither operation depends on the Android CLI emulator subcommand. The [avdmanager documentation](https://developer.android.com/tools/avdmanager) and [emulator command documentation](https://developer.android.com/studio/run/emulator-commandline) describe these commands.

## Flutter compatibility

[Flutter issue #191558](https://github.com/flutter/flutter/issues/191558) reports that `flutter doctor --android-licenses` did not recognize Command-Line Tools 23.0 in an affected environment and that 22.0 worked there. To install Command-Line Tools 22.0, run:

```powershell
Install-WUAndroidSdk -CommandLineToolsVersion '22.0'
```
