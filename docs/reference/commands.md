# Command reference

Import PSWinUtil and list the exported commands:

```powershell
Import-Module -Name 'PSWinUtil'
Get-Command -Module 'PSWinUtil'
```

Generate a command summary from the installed module's help:

```powershell
Get-Command -Module 'PSWinUtil' |
    Sort-Object -Property Name |
    ForEach-Object {
        $help = Get-Help -Name "PSWinUtil\$($_.Name)"
        [pscustomobject]@{
            Name = $_.Name
            Synopsis = $help.Synopsis
        }
    } |
    Format-Table -AutoSize -Wrap
```

Find commands by name, then read their parameters and examples:

```powershell
Get-Command -Module 'PSWinUtil' -Name '*Android*'
Get-Help -Name 'Start-WUAndroidEmulator' -Full
Get-Help -Name 'Start-WUAndroidEmulator' -Examples
```

For a command override, inspect the command active in the session and read its help by name:

```powershell
Get-Command -Name 'Get-Content'
Get-Help -Name 'Get-Content' -Full
```
