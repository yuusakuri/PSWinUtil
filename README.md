# PSWinUtil

PSWinUtil is a PowerShell module for Windows users. It contains the following functions.

- Set Windows by rewriting the registry
- Add environment variables from PowerShell script file or object.
- Add the specified paths to the path environment variable.
- Determines if the path properties match. This function is useful for testing if the specified path is a file system and if the extensions match.
- Get whether the computer is Desktop, Tablet, or Server from ChassisTypes.
- Get information about installed NuGet packages in the NuGet packages installation directory.
- Get link targets of shortcut (.lnk) files.
- Load assemblies from NuGet packages, including its dependencies. It is possible to automatically install the required packages.
- Create SSH key using ssh-keygen.
- Test if a version is in the allowed range.

## Requirements

Windows PowerShell 5.1 (or later)
Carbon 2.15.1 (or later)

## Installing

### Option 1: Scoop

```powershell
scoop bucket add yuusakuri https://github.com/yuusakuri/scoop-bucket.git
scoop install yuusakuri/pswinutil
```

### Option 2: PowerShellGet

```powershell
Install-Module -Name Carbon -Scope CurrentUser
Install-Module -Name PSWinUtil -Scope CurrentUser
```

### Option 3: ZIP File

Download the ZIP file of a release and unpack it to one of the following locations:

- Current user: `C:\Users\USERNAME\Documents\WindowsPowerShell\Modules\PSWinUtil`
- All users: `C:\Program Files\WindowsPowerShell\Modules\PSWinUtil`

## Check if the module is installed

```powershell
. { Get-Module; Get-Module -ListAvailable } | Where-Object { $_.Name -eq 'PSWinUtil' }
```
