# Getting started from source

Build PSWinUtil from source, import it, and preview setting a user environment variable. At the end, the module is available in the current PowerShell session and the environment variable retains its original value.

## 1. Check the environment

Open Windows PowerShell and confirm that it is version 5.1 with the `Desktop` edition:

```powershell
$PSVersionTable.PSVersion
$PSVersionTable.PSEdition
```

The version output must show major version `5` and minor version `1`; the edition must be `Desktop`. PowerShell 7 uses the `Core` edition and is not a supported runtime for this module.

The source build requires Git and the .NET SDK 8.0 or later. Confirm that both commands are available:

```powershell
git --version
dotnet --version
```

Both commands must print a version, and the .NET SDK major version must be at least `8`.

## 2. Clone the repository

```powershell
git clone https://github.com/yuusakuri/PSWinUtil.git
Set-Location -Path '.\PSWinUtil'
```

Run the remaining commands from the cloned `PSWinUtil` directory.

## 3. Install development modules

Install the pinned versions of ModuleBuilder, Pester, PSScriptAnalyzer, and `Microsoft.PowerShell.PSResourceGet`:

```powershell
powershell.exe -ExecutionPolicy Bypass -File '.\install.ps1'
```

The script installs the versions in `build.requirements.psd1` for the current user. These modules are used to build and test PSWinUtil; the built module can be imported without them.

## 4. Build and import PSWinUtil

```powershell
powershell.exe -ExecutionPolicy Bypass -File '.\dev.ps1' build
Import-Module -Name '.\output\PSWinUtil\PSWinUtil.psd1' -Force
```

Confirm the imported module and its version:

```powershell
Get-Module -Name 'PSWinUtil' |
    Select-Object -Property Name, Version, Path
```

The output must show `PSWinUtil`, the version declared in `src/PSWinUtil/PSWinUtil.psd1`, and a path inside this repository's `output\PSWinUtil` directory.

## 5. Inspect commands and help

```powershell
Get-Command -Module 'PSWinUtil'
Get-Help -Name 'Set-WUEnvironmentVariable' -Full
```

The [command reference](../reference/commands.md) provides a grouped index. Comment-based help is the detailed reference for parameters, input, output, and examples.

## 6. Preview a change

First, read the current value of the user environment variable:

```powershell
Get-WUEnvironmentVariable -Name 'PSWINUTIL_TUTORIAL' -Scope User
```

A missing variable produces no output. If a value appears, note it for the comparison after the preview.

`Set-WUEnvironmentVariable` supports PowerShell's `-WhatIf` parameter. Preview setting the variable:

```powershell
Set-WUEnvironmentVariable `
    -Name 'PSWINUTIL_TUTORIAL' `
    -Value 'ready' `
    -Scope User `
    -WhatIf
```

PowerShell displays the target variable and operation without writing the value. Read the variable again:

```powershell
Get-WUEnvironmentVariable -Name 'PSWINUTIL_TUTORIAL' -Scope User
```

The result must match the first read. If the variable was absent, there is still no output; if it existed, its value is unchanged.

## 7. Choose the next command

Before running a command without `-WhatIf`, read its complete help and note whether it requires elevation, restarts, sign-out, or an external application:

```powershell
Get-Help -Name 'Enable-WULongPaths' -Full
```

Use the [command reference](../reference/commands.md) to find another command, or follow [Contributing](../../CONTRIBUTING.md) to develop and test the module.
