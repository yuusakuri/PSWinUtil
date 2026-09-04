# Changelog

Release history for PSWinUtil, organized by version.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `Get-WUAndroidEmulator` lists all local Android virtual device names, including stopped devices.
- A ModuleBuilder-based build, PSScriptAnalyzer checks, and unit, integration, and contract test suites for Windows PowerShell 5.1.
- Commands for environment variables, registry settings, startup entries, automatic logon, keyboard remapping, Windows 11 settings, certificate trust, downloads, package installation, and Android and Flutter tooling.
- A compiled `PSWinUtil.Native` assembly for Windows native interoperability.

### Changed

- `Start-WUAndroidEmulator` starts all local Android virtual devices by default; `-Name` selects one device.
- Rebuilt the module around one public or private function per source file and a generated distribution under `output/PSWinUtil`.
- Limited the supported runtime to Windows PowerShell 5.1 Desktop.
- Removed third-party module and executable installation from module import.
- Standardized public command help, error handling, pipeline behavior, and `ShouldProcess` support.

### Removed

- The legacy source layout and obsolete public commands from the 1.x module.

## [1.6.9] - 2021-07-30

### Added

- Commands to enable or disable News and Interests on the taskbar.

## [1.6.8] - 2021-07-29

### Added

- `Set-WUMonitor -HighestQuality` selects the highest supported resolution and refresh rate.
- `Convert-WUString` supports lower camel case conversion.

### Changed

- `Get-WUMonitor` reports additional display properties and supported display modes.

### Fixed

- Monitor selection matches the requested index or device name, and monitor output properties report the corresponding display values.

## [1.6.4] - 2021-07-19

### Added

- `Install-WUApp` supports NuGet and npm packages.
- Commands to read NuGet package metadata, load package assemblies, and test version ranges.

### Changed

- NuGet assemblies load when needed instead of during module import.

### Fixed

- Version checks handle invalid version strings, different component counts, and empty allowed-version ranges.
- Dependency resolution handles missing assembly paths and package checksum failures.

## [1.5.8] - 2021-06-21

### Added

- Commands to test and assert path properties and PowerShell script syntax.
- `Add-WUEnvironmentVariableFromFile` reads environment variables from files or objects.

### Changed

- The PATH commands are named `Add-WUPathEnvironmentVariable` and `Remove-WUPathEnvironmentVariable`.

### Fixed

- Path conversion reports invalid characters or syntax without treating a nonexistent or inaccessible path as a syntax error.

## [1.5.7] - 2021-06-10

### Fixed

- `Install-WUApp` applies Chocolatey configuration only when `-Optimize` selects that provider.

## [1.5.6] - 2021-06-10

### Changed

- `Install-WUApp -Unsafe` skips checksum verification for Scoop and Chocolatey packages. `-Force` controls reinstallation separately.

## [1.5.5] - 2021-06-10

### Fixed

- `Install-WUApp` detects the Scoop installation directory and retries failed Git installations.
- Scoop package recovery retains the package bucket when reinstalling a failed package.

## [1.5.4] - 2021-06-09

### Added

- Commands to enable or disable Windows long paths.

### Changed

- `Install-WUApp` supports the Shovel fork through its Scoop provider.

### Fixed

- Registry command definitions use the exported function names.

## [1.5.1] - 2021-06-07

### Added

- Commands to control recommendations in Windows Search.
- `Join-WUUri` resolves relative URIs, and `Get-WUUriWithoutQuery` removes query strings.
- `Convert-WUString` supports character-width conversion, upper camel case, and escaping for PowerShell double-quoted strings.

### Changed

- Dependency installation uses `Install-WUApp`, including provider-specific optimization and recovery of failed Scoop installations.
- The Chocolatey package parameter of `Install-WUApp` is named `ChocolateyPackage`.

### Fixed

- URI joining handles the previously failing combinations of base and relative URIs.
- String conversion handles embedded line breaks.

### Removed

- `Optimize-WUPowerShellStartup`.

## [1.4.11] - 2021-01-31

### Added

- Commands to control Cortana, the Microsoft Edge first-run experience, Windows Media Player first-use dialogs, and the Windows Update status icon.

### Changed

- Windows Update notification settings cover additional notification registry values.

### Fixed

- Download output uses consistent line endings without extra trailing blank lines.

## [1.4.6] - 2021-01-20

### Added

- `Start-WUDevcontainer` opens a project with a `.devcontainer` configuration in Visual Studio Code.

## [1.4.5] - 2021-01-16

### Fixed

- SSH key creation and editing accept passphrases of exactly five characters.
- The module exports `Enable-WUAppSuggestions` and `Disable-WUAppSuggestions` under their correct names.

## [1.4.1] - 2020-12-14

### Added

- Commands to control dark mode, Start menu web search, and the taskbar search box.

### Changed

- Windows PowerShell 5.1 is the minimum supported version.
- Application suggestions and automatic application installation are configured through `Enable-WUAppSuggestions` and `Disable-WUAppSuggestions`.
- SmartScreen settings include Windows Defender SmartScreen.
- `Add-WUEnvPath` accepts a file path by using its parent directory; `Find-WUPath` uses regular expressions for excluded paths.

### Fixed

- Dependency installation checks administrator privileges correctly and can retry a failed installation.

## [1.2.33] - 2020-11-24

### Added

- Commands to enable or disable the sign-in requirement after wakeup.

### Fixed

- Automatic-logon settings use the intended registry scope.

## [1.2.31] - 2020-11-22

### Added

- `Optimize-WUPowerShellStartup` optimizes Windows PowerShell assemblies for startup.

## [1.2.30] - 2020-11-21

### Fixed

- Chocolatey installation avoids function-name collisions in the module session.

## [1.2.29] - 2020-11-21

### Fixed

- Dependency resolution invokes the intended Scoop or Chocolatey provider and identifies the failed dependency in warnings.

## [1.2.28] - 2020-11-18

### Added

- Commands to enable or disable workstation locking.

### Changed

- Registry and PATH commands use consistent `CurrentUser` and `LocalMachine` scope names.
- Windows Hello settings cover additional sign-in configuration.
- Desktop icon settings restart Explorer to apply the selected size.

### Fixed

- PATH helpers read and update the selected environment scope.

### Removed

- `Set-WUEnvPath`, which duplicated existing PATH functionality, and the nonfunctional `Set-WUPointerScheme` command.

## [1.2.19] - 2020-11-16

### Fixed

- `Find-WUPath` matches names without distinguishing uppercase and lowercase letters and checks the search module before use.

## [1.2.18] - 2020-11-14

### Fixed

- System-sound commands update the active application event sounds when enabling or disabling the sound scheme.

## [1.2.17] - 2020-11-14

### Added

- `Start-WUScriptAsAdmin` runs a PowerShell script with administrator privileges.
- Commands to enable or disable system sounds.

### Changed

- Release archives contain the module files without development files.

### Fixed

- Monitor enumeration creates its temporary directory and files correctly.

## [1.2.14] - 2020-11-11

### Fixed

- Pointer-scheme registry data includes the value name.

### Removed

- The module-import adjustment to the process TEMP path.

## [1.2.12] - 2020-11-10

### Fixed

- Module import adjusts a nonexistent TEMP path encountered on Windows 10 version 2004.

## [1.2.11] - 2020-11-10

### Added

- `Set-WUCapsLockToControl` maps Caps Lock to Control.

### Fixed

- Automatic-logon configuration supports Windows 10 version 20H2.

## [1.2.9] - 2020-11-10

### Fixed

- The module exports `Enable-WUContentDelivery` and `Disable-WUContentDelivery` under their correct names.

## [1.2.8] - 2020-11-10

### Added

- Commands to enable or disable Windows content delivery.

### Changed

- Dependency installation reports its progress and warns when Chocolatey requires administrator privileges or an installation fails.

## [1.2.6] - 2020-11-09

### Added

- Commands to enable or disable SmartScreen.

### Changed

- Dependency resolution supports Chocolatey alongside Scoop.

### Fixed

- Generated registry scripts place settings in the intended scope.

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
[1.6.9]: https://github.com/yuusakuri/PSWinUtil/releases/tag/v1.6.9
[1.6.8]: https://github.com/yuusakuri/PSWinUtil/releases/tag/v1.6.8
[1.6.4]: https://github.com/yuusakuri/PSWinUtil/releases/tag/v1.6.4
[1.5.8]: https://github.com/yuusakuri/PSWinUtil/releases/tag/v1.5.8
[1.5.7]: https://github.com/yuusakuri/PSWinUtil/releases/tag/v1.5.7
[1.5.6]: https://github.com/yuusakuri/PSWinUtil/releases/tag/v1.5.6
[1.5.5]: https://github.com/yuusakuri/PSWinUtil/releases/tag/v1.5.5
[1.5.4]: https://github.com/yuusakuri/PSWinUtil/releases/tag/v1.5.4
[1.5.1]: https://github.com/yuusakuri/PSWinUtil/releases/tag/v1.5.1
[1.4.11]: https://github.com/yuusakuri/PSWinUtil/releases/tag/v1.4.11
[1.4.6]: https://github.com/yuusakuri/PSWinUtil/releases/tag/v1.4.6
[1.4.5]: https://github.com/yuusakuri/PSWinUtil/releases/tag/v1.4.5
[1.4.1]: https://github.com/yuusakuri/PSWinUtil/releases/tag/v1.4.1
[1.2.33]: https://github.com/yuusakuri/PSWinUtil/releases/tag/v1.2.33
[1.2.31]: https://github.com/yuusakuri/PSWinUtil/releases/tag/v1.2.31
[1.2.30]: https://github.com/yuusakuri/PSWinUtil/releases/tag/v1.2.30
[1.2.29]: https://github.com/yuusakuri/PSWinUtil/releases/tag/v1.2.29
[1.2.28]: https://github.com/yuusakuri/PSWinUtil/releases/tag/v1.2.28
[1.2.19]: https://github.com/yuusakuri/PSWinUtil/releases/tag/v1.2.19
[1.2.18]: https://github.com/yuusakuri/PSWinUtil/releases/tag/v1.2.18
[1.2.17]: https://github.com/yuusakuri/PSWinUtil/releases/tag/v1.2.17
[1.2.14]: https://github.com/yuusakuri/PSWinUtil/releases/tag/v1.2.14
[1.2.12]: https://github.com/yuusakuri/PSWinUtil/releases/tag/v1.2.12
[1.2.11]: https://github.com/yuusakuri/PSWinUtil/releases/tag/v1.2.11
[1.2.9]: https://github.com/yuusakuri/PSWinUtil/releases/tag/v1.2.9
[1.2.8]: https://github.com/yuusakuri/PSWinUtil/releases/tag/v1.2.8
[1.2.6]: https://github.com/yuusakuri/PSWinUtil/releases/tag/v1.2.6
[1.2.0]: https://github.com/yuusakuri/PSWinUtil/releases/tag/v1.2.0
[1.0.0]: https://github.com/yuusakuri/PSWinUtil/releases/tag/v1.0.0
[1.2.2]: https://github.com/yuusakuri/PSWinUtil/commit/8e3bde8
[1.1.0]: https://github.com/yuusakuri/PSWinUtil/commit/d505e3e
