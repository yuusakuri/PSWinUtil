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
Install-Module -Name PSWinUtil -Scope CurrentUser
```

### Option 3: ZIP File

Download the ZIP file of a release and unpack it to one of the following locations:

- Current user: `C:\Users\USERNAME\Documents\WindowsPowerShell\Modules\PSWinUtil`
- All users: `C:\Program Files\WindowsPowerShell\Modules\PSWinUtil`

## Check if the module is installed

```powershell
# When installed using scoop
Get-Module PSWinUtil
# When installed from PowerShell Gallery
Get-Module PSWinUtil -ListAvailable
```
