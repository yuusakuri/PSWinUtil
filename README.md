# PSWinUtil

PSWinUtil is a Windows PowerShell 5.1 module for repeatable Windows configuration and administration.

It provides commands to:

- Configure Windows interface, security, sign-in, and notification settings.
- Manage environment variables, `PATH` entries, registry properties, startup entries, keyboard remapping, and automatic sign-in.
- Work with UTF-8 text files, paths, URIs, SSH keys, downloads, winget packages, and Android and Flutter tools.

The module can be imported without third-party runtime dependencies. Individual commands can require the Windows features or applications they operate, such as Windows Package Manager, OpenSSH, Java, Node.js, Flutter, or the Android SDK.

## Requirements

- Windows.
- Windows PowerShell 5.1 with the `Desktop` edition.

Check the current shell before importing the module:

```powershell
$PSVersionTable.PSVersion
$PSVersionTable.PSEdition
```

## Installation

### PowerShell Gallery

Install the latest published release for the current user with `Microsoft.PowerShell.PSResourceGet`:

```powershell
Install-Module -Name 'Microsoft.PowerShell.PSResourceGet' -Scope CurrentUser -Repository PSGallery
```

Then install and import PSWinUtil:

```powershell
Install-PSResource -Name 'PSWinUtil' -Scope CurrentUser -Repository PSGallery
Import-Module -Name 'PSWinUtil'
```

The source on `master` targets the version declared in [`src/PSWinUtil/PSWinUtil.psd1`](src/PSWinUtil/PSWinUtil.psd1). If the Gallery still provides an earlier major version, its commands can differ from this documentation. Use a source build when evaluating the current development version.

### Source build

Clone the repository, install the pinned development modules, and build the distribution:

```powershell
git clone https://github.com/yuusakuri/PSWinUtil.git
Set-Location -Path '.\PSWinUtil'
powershell.exe -ExecutionPolicy Bypass -File '.\install.ps1'
powershell.exe -ExecutionPolicy Bypass -File '.\dev.ps1' build
Import-Module -Name '.\output\PSWinUtil\PSWinUtil.psd1'
```

Development dependencies are required only to build and test the source. The generated module is under `output/PSWinUtil`.

## Quick start

List the installed commands:

```powershell
Get-Command -Module 'PSWinUtil'
```

Read an environment variable from the current user profile:

```powershell
Get-WUEnvironmentVariable -Name 'JAVA_HOME' -Scope User
```

Preview a persistent environment variable update without changing the system:

```powershell
Set-WUEnvironmentVariable -Name 'MY_TOOL_HOME' -Value 'C:\Tools' -Scope User -WhatIf
```

Apply persistent environment changes to the current PowerShell process:

```powershell
Update-WUProcessEnvironment
```

Use `Get-Help` for a command's complete parameters, behavior, and examples:

```powershell
Get-Help -Name 'Set-WUEnvironmentVariable' -Full
```

## Documentation

- [Getting started](docs/tutorials/getting-started.md) walks through a source build and a safe first configuration change.
- [Command reference](docs/reference/commands.md) groups every exported command by purpose.
- [Architecture](docs/explanation/architecture.md) explains the source, build, distribution, and test boundaries.
- [Contributing](CONTRIBUTING.md) describes the development workflow and required verification.
- [Changelog](CHANGELOG.md) records released and unreleased changes.

## License

PSWinUtil is licensed under the [Apache License 2.0](LICENSE).
