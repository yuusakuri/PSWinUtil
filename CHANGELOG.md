# Changelog

Release history for PSWinUtil, organized by version.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `Get-WUAndroidEmulator` lists local Android virtual device names.
- `Get-WUAndroidEmulatorPort` and `Test-WUAndroidEmulatorPort` find and test available emulator console ports.
- `Install-WUAndroidCli` installs Android CLI through WinGet.
- `Install-WUAndroidSdk` uses Android CLI to install missing stable Android SDK packages and configures the SDK environment.
- `Invoke-WUHttpFileDownload` downloads files directly and resumes interrupted transfers from saved content.
- `Enable-WUCommandOverride` and `Disable-WUCommandOverride` control content command overrides.
- `Set-WUProgressPreference` controls progress display for the current session.
- `Install-WUGit` installs Git for Windows and configures its path.
- `dev.ps1 bump` and `dev.ps1 release` prepare and publish releases.
- Preview versions publish to PowerShell Gallery and GitHub Releases without replacing the corresponding stable release.
- `dev.ps1 docs` generates the command reference from exported commands and their help; `docs check` verifies the committed reference.
- A ModuleBuilder-based build, PSScriptAnalyzer checks, and unit, integration, and contract test suites for Windows PowerShell 5.1.
- Commands for environment variables, registry settings, startup entries, automatic logon, keyboard remapping, Windows 11 settings, certificate trust, downloads, package installation, and Android and Flutter tooling.
- A compiled `PSWinUtil.Native` assembly for Windows native interoperability.

### Changed

- Direct HTTP SDK downloads use progress-based resume without retry-count or timeout parameters.
- `Start-WUAndroidEmulator` assigns ports, starts the selected virtual devices, and waits for ADB availability. `-Name` selects one device, `-Port` sets its console port, and `-NoWait` returns after launch.
- Rebuilt the module around one public or private function per source file and a generated distribution under `output/PSWinUtil`.
- Limited the supported runtime to Windows PowerShell 5.1 Desktop.
- Removed third-party module and executable installation from module import.
- Standardized public command help, error handling, pipeline behavior, and `ShouldProcess` support.

### Removed

- The legacy source layout and obsolete public commands from the 1.x module.

## 1.3.0 - 1.6.9

The 1.x releases between 1.2.2 and 1.6.9 are listed with their notes and tags in [Releases](https://github.com/yuusakuri/PSWinUtil/releases).

## [1.2.2]

- `Add-WUEnvPath`: Fixed this script not being able to run.
- Added description to manifest.

## [1.2.0]

- `Disable-WUWindowsSecurityNonCriticalNotifications`: Added to disable non-essential notifications for Windows Security.
- `Enable-WUWindowsSecurityNonCriticalNotifications`: Added to enable non-essential notifications for Windows Security

## [1.1.0]

- `Set-WUPS1Action`: Modify parameter set.
- `Set-WUWindowsAutoLogin`: Added to set automatic login for windows.
- `Set-WUScalingBehavior`: Added to set high DPI scaling per app.

## [1.0.0]

- Initial stable release

[Unreleased]: https://github.com/yuusakuri/PSWinUtil/compare/v1.6.9...HEAD
[1.2.2]: https://github.com/yuusakuri/PSWinUtil/commit/8e3bde8
[1.2.0]: https://github.com/yuusakuri/PSWinUtil/releases/tag/v1.2.0
[1.1.0]: https://github.com/yuusakuri/PSWinUtil/commit/d505e3e
[1.0.0]: https://github.com/yuusakuri/PSWinUtil/releases/tag/v1.0.0
