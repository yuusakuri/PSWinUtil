function Find-WUPath {
    <#
        .SYNOPSIS
        Search for file or folder paths in rapidly by using Everything. Useful for finding executable files.

        .DESCRIPTION
        Search the path everywhere using command path or es.exe.

        .OUTPUTS
        System.String.

        Returns the path found by searching.

        .EXAMPLE
        PS C:\> Find-WUPath 'powershell.exe'

        In this example, Finds and returns the path where the leaf contains powershell.exe.

        .EXAMPLE
        PS C:\> Find-WUPath 'powershell.exe' -Strict

        In this example, Finds and returns the path where the leaf exactly matches powershell.exe.

        .EXAMPLE
        PS C:\> Find-WUPath 'PowerShell\v1.0\powershell.exe' -Strict

        In this example, Searches for and returns a path whose leaf exactly matches powershell.exe and whose parent path contains PowerShell\v1.0.

        .EXAMPLE
        PS C:\> Find-WUPath 'powershell.exe' -Strict -Exclude 'Windows'

        This example searches for a path whose path does not match'Windows' and whose filename is powershell.exe.

        .EXAMPLE
        PS C:\> Find-WUPath 'powershell.exe' -Program

        In this example, powershell.exe is searched for in the order of command, start menu shortcut file link destination, es.exe, and the path containing powershell.exe in the leaf is returned.
    #>

    [CmdletBinding()]
    param (
        # Specify the character string contained in the leaf of the path to be searched. In addition, the strings contained in its parent directory can be specified before the leaf, separated by / or \. However, if -Strict is specified, the path with exact leaf matches will be searched. Also, wildcards are not supported.
        [Parameter(Mandatory,
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Name,

        # Specifies the regular expression for the path to exclude. It is case sensitive. Paths that match the following strings are excluded, regardless of the value specified for this parameter.
        # 'C:\\Windows\\SysWOW64'
        # 'SxS\\'
        # 'AppData\\Local\\Microsoft\\Windows\\FileHistory'
        # 'C:\\Windows\\Prefetch'
        # 'AppData\\Roaming\\Microsoft\\Windows\\Recent'
        # 'scoop\\apps\\.+\\_.+\.old\\'
        [string[]]
        $Exclude,

        # Search for a path that has an exact leaf match.
        [switch]
        $Strict,

        # Searches the command from the leaf of the path specified by -Name and returns the path if found. If not found, searches all locations by using es.exe.
        [switch]
        $Program
    )

    begin {
        Set-StrictMode -Version 'Latest'

        $isCompleated = {
            param (
                [string[]]
                $AddPath
            )

            if (!$AddPath) {
                return $false
            }

            $resultPaths.AddRange($AddPath)
            $resultItems = Get-Item -LiteralPath $resultPaths -ErrorAction Ignore

            if ($Exclude) {
                foreach ($aExclude in $Exclude) {
                    $resultItems = $resultItems |
                    Where-Object { !($_.FullName -cmatch $aExclude) }
                }
            }

            $resultItems = $patterns | ForEach-Object {
                $pattern = $_

                $completedItem = $resultItems |
                Where-Object {
                    if (!$pattern.Parent) {
                        return $true
                    }
                    return Select-String -InputObject (Split-Path $_ -Parent) -SimpleMatch $pattern.Parent
                } |
                Where-Object {
                    if ($Strict) {
                        return $_.Name -eq $pattern.Leaf
                    }
                    return Select-String -InputObject $_.Name -SimpleMatch $pattern.Leaf
                }

                if ($completedItem) {
                    $completedItem
                    $completedLeaves.add($pattern.Leaf) | Out-Null
                }
            }

            $resultPaths.Clear()
            if (!$resultItems) {
                return $false
            }
            $resultPaths.AddRange(@(Convert-Path -LiteralPath $resultItems.FullName | Select-Object -Unique))

            # Narrow down $leaves to incomplete ones
            $leaves = $leaves |
            Where-Object { $completedLeaves -notcontains $_ }

            $completedLeaves.Clear()

            return !$leaves
        }

        $names = @()
    }

    process {
        foreach ($aName in $Name) {
            # Unified path separator to backslash (\)
            $names += $aName -replace '/', '\'
        }
    }

    end {
        $patterns = $names | ForEach-Object {
            @{
                Leaf   = Split-Path $_ -Leaf
                Parent = Split-Path $_ -Parent
            }
        }

        $leaves = $patterns.Leaf
        $resultPaths = New-Object System.Collections.ArrayList
        $completedLeaves = New-Object System.Collections.ArrayList

        $Exclude += @(
            [regex]::Escape("C:\Windows\SysWOW64")
            [regex]::Escape("SxS\")
            [regex]::Escape("AppData\Local\Microsoft\Windows\FileHistory")
            [regex]::Escape("C:\Windows\Prefetch")
            [regex]::Escape("AppData\Roaming\Microsoft\Windows\Recent")
            "scoop\\apps\\.+\\_.+\.old\\"
        )
        if ($env:ChocolateyInstall) {
            $Exclude += [regex]::Escape("$env:ChocolateyInstall\bin")
        }

        if ($Program) {
            # Search by command
            $cmdPaths = Get-Command $leaves -ErrorAction Ignore | Select-Object -ExpandProperty Path

            if ($cmdPaths) {
                $cmdResultPaths = @()
                [string[]]$scoopShimPaths = $cmdPaths |
                Where-Object {
                    (Split-Path $_ -Parent) -like '*scoop\shims' -and
                    (Split-Path $_ -Leaf) -match '\.exe$'
                }
                $GeneralCmdPaths = $cmdPaths | Where-Object { $scoopShimPaths -notcontains $_ }

                $cmdResultPaths += $GeneralCmdPaths

                if ($scoopShimPaths) {
                    if ((Get-Command -Name scoop -ErrorAction Ignore)) {
                        $scoopCmdPaths = Split-Path $scoopShimPaths -Leaf | ForEach-Object {
                            scoop which ($_ -replace '\.exe$', '')
                        }
                        $cmdResultPaths += $scoopCmdPaths
                    }
                    else {
                        $cmdResultPaths += $scoopShimPaths
                    }
                }

                if ((& $isCompleated -AddPath $cmdResultPaths)) {
                    return $resultPaths
                }
            }

            # Search by shortcut
            $lnkDirs = @(
                "$env:APPDATA\Microsoft\Windows\Start Menu"
                "C:\ProgramData\Microsoft\Windows\Start Menu"
            )

            $lnkResultPaths = Get-WULnkTarget -LiteralPath (Get-ChildItem -LiteralPath $lnkDirs -Recurse | Where-Object { $_.Extension -eq '.lnk' } | Select-Object -ExpandProperty FullName) -WarningAction Ignore

            if ((& $isCompleated -AddPath $lnkResultPaths)) {
                return $resultPaths
            }
        }

        # Search by es.exe
        if ((Get-Command -Name 'es.exe' -ErrorAction Ignore)) {
            $esResultPaths = $leaves | ForEach-Object {
                es.exe $_
            }

            if ((& $isCompleated -AddPath $esResultPaths)) {
                return $resultPaths
            }
        }
        else {
            Write-Warning "Cannot find command 'es.exe'."
        }

        return $resultPaths
    }
}
