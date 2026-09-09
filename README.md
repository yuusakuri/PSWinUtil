# PSWinUtil

PSWinUtil provides Windows PowerShell 5.1 commands for configuring Windows settings and development tools from scripts.

It provides commands to:

- Configure Windows interface, security, sign-in, and notification settings.
- Manage environment variables, `PATH` entries, registry properties, startup entries, keyboard remapping, and automatic sign-in.
- Work with UTF-8 text files, paths, URIs, SSH keys, downloads, and development tools.

## Requirements

- Windows.
- Windows PowerShell 5.1 with the `Desktop` edition.

## Installation

### PowerShell Gallery

Install PSWinUtil for the current user:

```powershell
Install-Module -Name 'Microsoft.PowerShell.PSResourceGet' -Scope CurrentUser
Import-Module -Name 'Microsoft.PowerShell.PSResourceGet'
Set-PSResourceRepository -Name 'PSGallery' -Trusted
Install-PSResource -Name 'PSWinUtil' -Scope CurrentUser -Repository PSGallery
```

Install the latest preview release for the current user:

```powershell
Install-PSResource -Name 'PSWinUtil' -Scope CurrentUser -Repository PSGallery -Prerelease
```

### Release ZIP

Download a ZIP from [Releases](https://github.com/yuusakuri/PSWinUtil/releases), extract it, and import the included `PSWinUtil.psd1` by its full path.

## Quick start

Import the installed module and list its commands:

```powershell
Import-Module -Name 'PSWinUtil'
Get-Command -Module 'PSWinUtil'
```

Read an environment variable from the current user profile:

```powershell
Get-WUEnvironmentVariable -Name 'JAVA_HOME' -Scope User
```

Preview a persistent environment variable update:

```powershell
Set-WUEnvironmentVariable -Name 'MY_TOOL_HOME' -Value 'C:\Tools' -Scope User -WhatIf
```

Create an Android virtual device with the newest standard Pixel profile available in your installed SDK tools and the latest stable system image:

```powershell
New-WUAndroidEmulator
New-WUAndroidEmulator -Name 'App_API_35' -Device pixel_8 -PlatformVersion 35
New-WUAndroidEmulator -PlatformVersion 35 -SystemImageTag google_apis_playstore -Abi x86_64
```

Android CLI (`android.exe`) on PATH installs system images. Java and Android SDK Command-Line Tools provide the Pixel profiles and AVD creation options. `SdkPath` defaults to `ANDROID_HOME`, then `LOCALAPPDATA\Android\Sdk`. `CommandLineToolsVersion` selects an installed tools directory (default: `latest`); update the tools to obtain newer Pixel profiles.

Android CLI 1.0.16261425 offers generic creation profiles without Pixel or API selection, so AVD creation currently uses `avdmanager`. Creation installs the image but does not boot the emulator. Existing AVDs are preserved unless `-Force` is supplied; `-WhatIf` performs no SDK calls.

Use `Get-Help` for a command's complete parameters, behavior, and examples:

```powershell
Get-Help -Name 'Set-WUEnvironmentVariable' -Full
```

## Documentation

- [Command reference](docs/reference/commands.md) lists the exported commands and their summaries generated from PowerShell help.
- [Architecture](docs/explanation/architecture.md) explains the source, build, distribution, and test boundaries.
- [Contributing](CONTRIBUTING.md) describes the development workflow and repository-specific verification.
- [Releasing](RELEASING.md) describes version preparation and publication.
- [Changelog](CHANGELOG.md) records released and unreleased changes.

## License

PSWinUtil is licensed under the [Apache License 2.0](LICENSE).
