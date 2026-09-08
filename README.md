# PSWinUtil

PSWinUtil is a Windows PowerShell 5.1 module for repeatable Windows configuration and administration.

It provides commands that:

- Configure Windows interface, security, sign-in, and notification settings.
- Manage environment variables, `PATH` entries, registry properties, startup entries, keyboard remapping, and automatic sign-in.
- Work with UTF-8 text files, paths, URIs, SSH keys, downloads, winget packages, and Android command-line tools.

## Requirements

- Windows.
- Windows PowerShell 5.1 with the `Desktop` edition.

## Installation

### PowerShell Gallery

Install PSWinUtil from PowerShell Gallery for the current user:

```powershell
Install-PSResource -Name 'PSWinUtil' -Scope CurrentUser -Repository PSGallery
```

### Release ZIP

To use PSWinUtil without installing it from PowerShell Gallery, download the ZIP file for the required version from [Releases](https://github.com/yuusakuri/PSWinUtil/releases). Extract the archive to any directory, find the included `PSWinUtil.psd1` module manifest, and import it by its full path.

The following example uses a ZIP file saved as `Downloads\PSWinUtil.zip`:

```powershell
$archivePath = Join-Path -Path $env:USERPROFILE -ChildPath 'Downloads\PSWinUtil.zip'
$destinationPath = Join-Path -Path $env:USERPROFILE -ChildPath 'Downloads\PSWinUtil-release'

Expand-Archive -LiteralPath $archivePath -DestinationPath $destinationPath
$manifestPath = Get-ChildItem -LiteralPath $destinationPath -Filter 'PSWinUtil.psd1' -File -Recurse |
    Select-Object -First 1 -ExpandProperty FullName

if ($null -eq $manifestPath) {
    throw 'PSWinUtil.psd1 was not found in the extracted release.'
}

Import-Module -Name $manifestPath
Get-Command -Module 'PSWinUtil'
```

The imported commands are available in the current Windows PowerShell session. In a new session, run `Import-Module` with the extracted manifest path again.

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

Install a package by its exact winget ID and automatically accept the source and package agreements:

```powershell
Install-WUWingetPackage -Id 'Microsoft.PowerShell'
```

Stop the progress bar, which removes the rendering cost that Windows PowerShell 5.1 adds to commands such as `Invoke-WebRequest`:

```powershell
$ProgressPreference = 'SilentlyContinue'
```

### Command overrides

PSWinUtil replaces `Get-Content`, `Set-Content`, `Add-Content`, and `Out-File` with proxy functions that change their Windows PowerShell 5.1 defaults to UTF-8 without a byte order mark and LF. Importing the module places all four proxy functions into the session.

`Disable-WUCommandOverride` removes the proxy function of the commands you name, so PowerShell resolves them with their original cmdlets, and `Enable-WUCommandOverride` puts the proxy functions back. The proxy function is the override itself, so `Get-Command` always shows which one is in effect.

```powershell
Disable-WUCommandOverride -Name Get-Content
Get-Content -LiteralPath 'C:\Data\legacy.txt' -Raw
Enable-WUCommandOverride -Name Get-Content
```

Name several commands at once to switch them together:

```powershell
Disable-WUCommandOverride -Name Get-Content, Set-Content, Add-Content, Out-File
```

Use `Get-Help` to view the parameters and examples for any command:

```powershell
Get-Help -Name 'Set-WUEnvironmentVariable' -Full
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, verification commands, coding conventions, and pull request requirements.
