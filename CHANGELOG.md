# Changelog

Release history for PSWinUtil, organized by version.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `Get-WUAndroidEmulator` lists local Android virtual device names.
- `Get-WUAndroidEmulatorPort` and `Test-WUAndroidEmulatorPort` find and test available emulator console ports.
- `Enable-WUCommandOverride` and `Disable-WUCommandOverride` control content command overrides.
- `Set-WUProgressPreference` controls progress display for the current session.
- `Install-WUGit` installs Git for Windows and configures its path.
- `dev.ps1 bump` and `dev.ps1 release` prepare and publish releases.
- A ModuleBuilder-based build, PSScriptAnalyzer checks, and unit, integration, and contract test suites for Windows PowerShell 5.1.
- Commands for environment variables, registry settings, startup entries, automatic logon, keyboard remapping, Windows 11 settings, certificate trust, downloads, package installation, and Android and Flutter tooling.
- A compiled `PSWinUtil.Native` assembly for Windows native interoperability.

### Changed

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

### Changed

- The module manifest includes a description.

### Fixed

- `Add-WUEnvPath` sets environment variables without the errors encountered in some environments.

## [1.2.0] - 2020-09-22

### Added

- `Disable-WUWindowsSecurityNonCriticalNotifications` and `Enable-WUWindowsSecurityNonCriticalNotifications`.

## [1.1.0]

### Added

- `Set-WUWindowsAutoLogin` configures Windows automatic logon.
- `Set-WUScalingBehavior` configures per-application high-DPI scaling.

### Changed

- `Set-WUPS1Action` provides revised parameter sets.

## [1.0.0] - 2020-09-21

### Added

- Initial stable release.

[Unreleased]: https://github.com/yuusakuri/PSWinUtil/compare/v1.6.9...HEAD
[1.2.2]: https://github.com/yuusakuri/PSWinUtil/commit/8e3bde8
[1.2.0]: https://github.com/yuusakuri/PSWinUtil/releases/tag/v1.2.0
[1.1.0]: https://github.com/yuusakuri/PSWinUtil/commit/d505e3e
[1.0.0]: https://github.com/yuusakuri/PSWinUtil/releases/tag/v1.0.0
