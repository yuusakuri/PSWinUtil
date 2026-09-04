# PSWinUtil

PSWinUtil provides Windows PowerShell 5.1 commands for configuring Windows settings and development tools from scripts.

It provides commands to:

- Configure Windows interface, security, sign-in, and notification settings.
- Manage environment variables, `PATH` entries, registry properties, startup entries, keyboard remapping, and automatic sign-in.
- Work with UTF-8 text files, paths, URIs, SSH keys, downloads, winget packages, and Android and Flutter tools.

Importing the built module requires no third-party PowerShell modules. Some commands use Windows features or external applications; others download or install tools. Each command's help lists its prerequisites.

## Requirements

- Windows.
- Windows PowerShell 5.1 with the `Desktop` edition.

Check the current shell before importing the module:

```powershell
$PSVersionTable.PSVersion
$PSVersionTable.PSEdition
```

The version output must show major version `5` and minor version `1`; the edition must be `Desktop`.

## Installation

The examples on this page describe the current source build. Build from source to use these commands, or install a published release and use its included `Get-Help` documentation.

### Source build

Install Git and the .NET SDK 8.0 or later before building. Then clone the repository, install the pinned development modules, and build PSWinUtil:

```powershell
git clone https://github.com/yuusakuri/PSWinUtil.git
Set-Location -Path '.\PSWinUtil'
powershell.exe -ExecutionPolicy Bypass -File '.\install.ps1'
powershell.exe -ExecutionPolicy Bypass -File '.\dev.ps1' build
Import-Module -Name '.\output\PSWinUtil\PSWinUtil.psd1'
```

The generated module is under `output/PSWinUtil`. For a guided walkthrough with checks after each step, follow [Getting started from source](docs/tutorials/getting-started.md).

### PowerShell Gallery

Prepare the package manager in Windows PowerShell 5.1. The following commands allow scripts for the current session, enable TLS 1.2, and install the NuGet provider and PowerShellGet for the current user. Installing PowerShellGet also installs its PackageManagement dependency.

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
[Net.ServicePointManager]::SecurityProtocol =
    [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
Install-PackageProvider -Name 'NuGet' -MinimumVersion '2.8.5.201' -Scope CurrentUser -Force
Install-Module -Name 'PowerShellGet' -Scope CurrentUser -Repository PSGallery -Force -AllowClobber
```

Close that PowerShell window and open a new Windows PowerShell 5.1 window so that it can load the installed package-management modules. Set the session options again and install PSResourceGet:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
[Net.ServicePointManager]::SecurityProtocol =
    [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
Install-Module -Name 'Microsoft.PowerShell.PSResourceGet' -Scope CurrentUser -Repository PSGallery -Force -AllowClobber
Import-Module -Name 'Microsoft.PowerShell.PSResourceGet'
```

Install the latest published PSWinUtil release and check the imported version:

```powershell
Install-PSResource -Name 'PSWinUtil' -Scope CurrentUser -Repository PSGallery
Import-Module -Name 'PSWinUtil'
Get-Module -Name 'PSWinUtil' | Select-Object -Property Name, Version, Path
```

## Quick start

After importing the module, list its commands:

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

`-WhatIf` describes the operation without storing the variable.

Use `Get-Help` for a command's complete parameters, behavior, and examples:

```powershell
Get-Help -Name 'Set-WUEnvironmentVariable' -Full
```

Importing PSWinUtil also makes its versions of `Get-Content`, `Set-Content`, `Add-Content`, `Out-File`, and `Invoke-WebRequest` available under those names. They use the encoding and progress behavior described in the [command reference](docs/reference/commands.md).

## Documentation

- [Getting started](docs/tutorials/getting-started.md) walks through a source build and a configuration preview that leaves the setting unchanged.
- [Command reference](docs/reference/commands.md) groups every exported command by purpose.
- [Architecture](docs/explanation/architecture.md) explains the source, build, distribution, and test boundaries.
- [Contributing](CONTRIBUTING.md) describes the development workflow and required verification.
- [Changelog](CHANGELOG.md) records released and unreleased changes.

## License

PSWinUtil is licensed under the [Apache License 2.0](LICENSE).
