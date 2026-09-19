# Android SDK installation and tool compatibility

## SDK location

`Install-WUAndroidSdk` uses `ANDROID_HOME` when it is set. Otherwise it uses `%LOCALAPPDATA%\Android\Sdk`, the usual Windows SDK location. After a successful installation it saves the selected location as the user `ANDROID_HOME`. Set `ANDROID_HOME` before running the function only when the SDK should be installed elsewhere. Android defines `ANDROID_USER_HOME` as the directory for current tools' user preferences and `ANDROID_SDK_HOME` as the parent of `.android` for older tools; neither changes the SDK installation location, and this function leaves both unchanged. See the [Android environment variable reference](https://developer.android.com/tools/variables) and [Windows SDK location](https://developer.android.com/studio/emulator_archive).

## Installed packages and versions

The function installs Android CLI through WinGet and uses `android sdk` to install SDK Platform, Build Tools, Platform Tools, Emulator, and Android SDK Command-Line Tools packages. When `-PlatformVersion` or `-BuildToolsVersion` is omitted, it selects the latest stable API level or Build Tools version listed by Android CLI. Other components remain at their installed version when their version parameter is omitted; missing components use the latest stable version. Existing files for the selected packages are reused.

An API level and a package revision are different. `-PlatformVersion 36` selects `platforms/android-36`; `-PlatformPackageVersion '2.0.0'` selects revision 2.0.0 of that package. `-BuildToolsVersion`, `-PlatformToolsVersion`, and `-EmulatorVersion` select their respective component versions. Android CLI uses `package@version` to select a revision and `--force` to permit downgrades. Explicit revision parameters apply even if package files already exist, so they can change the shared SDK used by other projects and AVDs. See the [Android CLI SDK command reference](https://developer.android.com/tools/agents/android-cli#sdk-install).

## Android CLI and Command-Line Tools

The Android SDK Command-Line Tools are installed alongside Android CLI, not replaced by it. `-CommandLineToolsVersion` defaults to `latest`; a value such as `22.0` selects `cmdline-tools/22.0` without removing other installed versions. The selected version's `bin` directory is added to the user PATH and made available to the current process. This provides `sdkmanager`, `avdmanager`, and other Command-Line Tools alongside `android.exe`.

Android CLI package names use slash-separated paths, while `sdkmanager` package names use semicolons. For example:

```powershell
android sdk list 'cmdline-tools/*' --all
android sdk install 'cmdline-tools/22.0'
sdkmanager.bat --install 'cmdline-tools;22.0'
```

The [Android CLI known issues](https://developer.android.com/tools/agents/android-cli#known-issues) state that its `android emulator` command is currently disabled on Windows. The installer still installs the separate `emulator` package. `New-WUAndroidEmulator` uses `avdmanager` to create AVDs, while `Get-WUAndroidEmulator` and `Start-WUAndroidEmulator` use `emulator.exe` to list or start them. These operations do not depend on the Android CLI emulator subcommand. The [avdmanager documentation](https://developer.android.com/tools/avdmanager) and [emulator command documentation](https://developer.android.com/studio/run/emulator-commandline) describe these commands.

## Flutter compatibility

[Flutter issue #191558](https://github.com/flutter/flutter/issues/191558) reports that `flutter doctor --android-licenses` did not recognize Command-Line Tools 23.0 in an affected environment and that 22.0 worked there. This is a reported workaround rather than a rule for every Flutter installation or later version. To install that version without deleting other Command-Line Tools, run `Install-WUAndroidSdk -CommandLineToolsVersion '22.0'`. It creates `cmdline-tools\22.0`; a consumer that explicitly uses `cmdline-tools\latest\bin` will not switch merely because 22.0 is on PATH, so check which path the affected Flutter installation uses.
