function Get-WULnkTarget {
    <#
        .SYNOPSIS
        Gets link targets of shortcut (.lnk) files.

        .DESCRIPTION
        Gets link targets of shortcut files. If a link target is not found, an error occurs, but processing continues and returns the link targets found.

        .OUTPUTS
        System.String

        .EXAMPLE
        PS C:\>Get-WULnkTarget -LiteralPath '~\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Windows PowerShell\Windows PowerShell.lnk'

        Returns 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
    #>

    [CmdletBinding(DefaultParameterSetName = 'Path')]
    param (
        # Specifies a path to one or more locations. Wildcards are permitted.
        [Parameter(Mandatory,
            Position = 0,
            ParameterSetName = 'Path',
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [string[]]
        $Path,

        # Specifies a path to one or more locations. Unlike the Path parameter, the value of the LiteralPath parameter is used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters, enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any characters as escape sequences.
        [Parameter(Mandatory,
            Position = 0,
            ParameterSetName = 'LiteralPath',
            ValueFromPipelineByPropertyName)]
        [Alias('PSPath')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $LiteralPath
    )

    begin {
        Set-StrictMode -Version 'Latest'

        $paths = @()
    }

    process {
        if ($psCmdlet.ParameterSetName -eq 'Path') {
            foreach ($aPath in $Path) {
                if (!(Test-Path -Path $aPath)) {
                    $ex = New-Object System.Management.Automation.ItemNotFoundException "Cannot find path '$aPath' because it does not exist."
                    $category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                    $errRecord = New-Object System.Management.Automation.ErrorRecord $ex, 'PathNotFound', $category, $aPath
                    $psCmdlet.WriteError($errRecord)
                    continue
                }

                # Resolve any wildcards that might be in the path
                $provider = $null
                $paths += $psCmdlet.SessionState.Path.GetResolvedProviderPathFromPSPath($aPath, [ref]$provider)
            }
        }
        else {
            foreach ($aPath in $LiteralPath) {
                if (!(Test-Path -LiteralPath $aPath)) {
                    $ex = New-Object System.Management.Automation.ItemNotFoundException "Cannot find path '$aPath' because it does not exist."
                    $category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                    $errRecord = New-Object System.Management.Automation.ErrorRecord $ex, 'PathNotFound', $category, $aPath
                    $psCmdlet.WriteError($errRecord)
                    continue
                }

                # Resolve any relative paths
                $paths += $psCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($aPath)
            }
        }
    }

    end {
        $lnkTargets = @()
        $sh = New-Object -ComObject WScript.Shell

        foreach ($aPath in $paths) {
            $lnkTarget = ''
            try {
                $lnkTarget = $sh.CreateShortcut($aPath).TargetPath
            }
            catch {
                Write-Error "Failed to get the link target of '$aPath'."
            }
            if (!$lnkTarget) {
                continue
            }

            $lnkTargets += $lnkTarget
        }

        return $lnkTargets
    }
}
