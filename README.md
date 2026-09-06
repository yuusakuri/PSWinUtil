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
Install-Module -Name 'PSWinUtil' -Scope CurrentUser -Repository PSGallery
```

On a Windows PowerShell 5.1 installation that has never used PowerShell Gallery, enable TLS 1.2 and install the NuGet provider for the current user first:

```powershell
[Net.ServicePointManager]::SecurityProtocol =
    [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
Install-PackageProvider -Name 'NuGet' -MinimumVersion '2.8.5.201' -Scope CurrentUser -Force
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

Use `Get-Help` for a command's complete parameters, behavior, and examples:

```powershell
Get-Help -Name 'Set-WUEnvironmentVariable' -Full
```

## Documentation

- [Command reference](docs/reference/commands.md) shows how to find commands and read their help.
- [Architecture](docs/explanation/architecture.md) explains the source, build, distribution, and test boundaries.
- [Contributing](CONTRIBUTING.md) describes the development workflow and required verification.
- [Releasing](RELEASING.md) describes version preparation and publication.
- [Changelog](CHANGELOG.md) records released and unreleased changes.

## License

PSWinUtil is licensed under the [Apache License 2.0](LICENSE).
