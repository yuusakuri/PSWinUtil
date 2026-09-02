# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- A ModuleBuilder-based build, PSScriptAnalyzer checks, and unit, integration, and contract test suites for Windows PowerShell 5.1.
- Commands for environment variables, registry settings, startup entries, automatic logon, keyboard remapping, Windows 11 settings, certificate trust, downloads, package installation, and Android and Flutter tooling.
- A compiled `PSWinUtil.Native` assembly for Windows native interoperability.

### Changed

- Rebuilt the module around one public or private function per source file and a generated distribution under `output/PSWinUtil`.
- Limited the supported runtime to Windows PowerShell 5.1 Desktop.
- Removed third-party module and executable installation from module import.
- Standardized public command help, error handling, pipeline behavior, and `ShouldProcess` support.

### Removed

- The legacy source layout and obsolete public commands from the 1.x module.

## [1.6.9] - 2021-07-30

### Added

- Commands to enable or disable News and Interests on the taskbar.

## [1.2.2]

### Fixed

- Fixed `Add-WUEnvPath` execution.

### Changed

- Added a module manifest description.

## [1.2.0] - 2020-09-22

### Added

- `Disable-WUWindowsSecurityNonCriticalNotifications` and `Enable-WUWindowsSecurityNonCriticalNotifications`.

## [1.1.0]

### Added

- `Set-WUWindowsAutoLogin` for Windows automatic logon.
- `Set-WUScalingBehavior` for per-application high-DPI scaling.

### Changed

- Updated the `Set-WUPS1Action` parameter sets.

## [1.0.0] - 2020-09-21

### Added

- Initial stable release.

Earlier 1.x releases are available in the [Git tags](https://github.com/yuusakuri/PSWinUtil/tags).

[Unreleased]: https://github.com/yuusakuri/PSWinUtil/compare/v1.6.9...HEAD
[1.6.9]: https://github.com/yuusakuri/PSWinUtil/releases/tag/v1.6.9
[1.2.0]: https://github.com/yuusakuri/PSWinUtil/releases/tag/v1.2.0
[1.0.0]: https://github.com/yuusakuri/PSWinUtil/releases/tag/v1.0.0
