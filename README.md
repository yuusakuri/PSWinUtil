# PSWinUtil

PSWinUtil is a Windows PowerShell 5.1 module for repeatable Windows configuration and administration.

It provides commands that:

- Configure Windows interface, security, sign-in, and notification settings.
- Manage environment variables, `PATH` entries, registry properties, startup entries, keyboard remapping, and automatic sign-in.
- Work with UTF-8 text files, paths, URIs, SSH keys, downloads, and Android command-line tools.

Commands that change system state support PowerShell's `-WhatIf` and `-Confirm` parameters where applicable.

## Requirements

- Windows.
- Windows PowerShell 5.1 with the `Desktop` edition.

The .NET SDK is not required to use the released module.

## Installation

Install PSWinUtil from PowerShell Gallery for the current user:

```powershell
Install-PSResource -Name 'PSWinUtil' -Scope CurrentUser -Repository PSGallery
```

## Usage

Import the module and list its commands:

```powershell
Import-Module -Name 'PSWinUtil'
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

Preview enabling Win32 long path support:

```powershell
Enable-WULongPaths -WhatIf
```

Use `Get-Help` to view the parameters and examples for any command:

```powershell
Get-Help -Name 'Set-WUEnvironmentVariable' -Full
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, verification commands, coding conventions, and pull request requirements.
