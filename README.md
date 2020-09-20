# PSWinUtil

PSWinUtil is a PowerShell module for Windows users. Dependencies are automatically installed by Scoop.

## Requirements

PowerShell 5.0 (or later)

## Installing

### Option 1: Scoop

```powershell
scoop bucket add yuusakuri https://github.com/yuusakuri/scoop-bucket.git
scoop install yuusakuri/pswinutil
```

### Option 2: PowerShellGet

```powershell
Install-Module -Name PSWinUtil
```

### Option 3: ZIP File

Download the ZIP file of a release and unpack it to one of the following locations:

- Current user: `C:\Users\USERNAME\Documents\WindowsPowerShell\Modules`
- All users: `C:\Program Files\WindowsPowerShell\Modules`

## Check if the module is installed

```powershell
Get-Module PSWinUtil -ListAvailable
```
