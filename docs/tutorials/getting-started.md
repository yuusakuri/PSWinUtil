# Getting started from source

This tutorial builds the current PSWinUtil source, imports the generated module, and previews a safe configuration change. It does not require changing machine-level state.

## 1. Check the environment

Open Windows PowerShell and confirm that it is version 5.1 with the `Desktop` edition:

```powershell
$PSVersionTable.PSVersion
$PSVersionTable.PSEdition
```

The edition must be `Desktop`. PowerShell 7 uses the `Core` edition and is not a supported runtime for this module.

The source build also requires Git and the .NET SDK 8.0 or later:

```powershell
git --version
dotnet --version
```

## 2. Clone the repository

```powershell
git clone https://github.com/yuusakuri/PSWinUtil.git
Set-Location -Path '.\PSWinUtil'
```

## 3. Install development modules

Install the pinned versions of ModuleBuilder, Pester, PSScriptAnalyzer, and `Microsoft.PowerShell.PSResourceGet`:

```powershell
powershell.exe -ExecutionPolicy Bypass -File '.\install.ps1'
```

These modules are development dependencies. They are not required to import the generated PSWinUtil distribution.

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

The path must point into this repository's `output\PSWinUtil` directory.

## 5. Inspect commands and help

```powershell
Get-Command -Module 'PSWinUtil'
Get-Help -Name 'Set-WUEnvironmentVariable' -Full
```

The [command reference](../reference/commands.md) provides a grouped index. Comment-based help is the detailed reference for parameters, input, output, and examples.

## 6. Preview a change

State-changing PSWinUtil commands support PowerShell's `-WhatIf` parameter. Preview adding a user environment variable:

```powershell
Set-WUEnvironmentVariable `
    -Name 'PSWINUTIL_TUTORIAL' `
    -Value 'ready' `
    -Scope User `
    -WhatIf
```

PowerShell describes the proposed operation, but the variable is not created. Verify that there is no user-level value:

```powershell
Get-WUEnvironmentVariable -Name 'PSWINUTIL_TUTORIAL' -Scope User
```

A missing environment variable produces no output.

## 7. Continue safely

Before running a command without `-WhatIf`, read its complete help and note whether it requires elevation, restarts, sign-out, or an external application:

```powershell
Get-Help -Name 'Enable-WULongPaths' -Full
```

Return to the [README](../../README.md) for installation options or read the [Architecture](../explanation/architecture.md) before contributing.
