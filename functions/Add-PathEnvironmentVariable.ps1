function Add-WUPathEnvironmentVariable {
    <#
        .SYNOPSIS
        Add the specified paths to the path environment variable.

        .DESCRIPTION
        Add the specified paths to the path environment variable of the specified scope. The path must exist. Also, if the paths overlap, they will not be added.

        .EXAMPLE
        PS C:\>Add-WUPathEnvironmentVariable -Path $env:USERPROFILE

        In this example, add $env:USERPROFILE to the process scope path environment variable.

        .LINK
        Remove-WUPathEnvironmentVariable
    #>

    [CmdletBinding(SupportsShouldProcess,
        DefaultParameterSetName = 'Path')]
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
        $LiteralPath,

        # Specifies the location where an environment variable. The default Scope is Process.
        [ValidateSet('LocalMachine', 'CurrentUser', 'Process')]
        [string[]]
        $Scope = 'Process'
    )

    begin {
        Set-StrictMode -Version 'Latest'

        $scopeParams = @{
            LocalMachine = 'ForComputer'
            CurrentUser  = 'ForUser'
            Process      = 'ForProcess'
        }
        $scopeTargets = @{
            LocalMachine = 'Machine'
            CurrentUser  = 'User'
            Process      = 'Process'
        }

        $paths = @()
    }

    process {
        if ($psCmdlet.ParameterSetName -eq 'Path') {
            foreach ($aPath in $Path) {
                if (!(Assert-WUPathProperty -Path $aPath -PSProvider FileSystem -PathType Any)) {
                    continue
                }

                $provider = $null
                $paths += $psCmdlet.SessionState.Path.GetResolvedProviderPathFromPSPath($aPath, [ref]$provider)
            }
        }
        else {
            foreach ($aPath in $LiteralPath) {
                if (!(Assert-WUPathProperty -LiteralPath $aPath -PSProvider FileSystem -PathType Any)) {
                    continue
                }

                $paths += $psCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($aPath)
            }
        }
    }

    end {
        if (!$paths) {
            return
        }

        $dirPaths = @()
        $dirPaths += $paths |
        ForEach-Object {
            if ((Test-Path -LiteralPath $_ -PathType Leaf)) {
                $aDirPath = Split-Path $_ -Parent
            }
            else {
                $aDirPath = $_
            }

            if ($aDirPath -match ';') {
                $aDirPath = '"{0}"' -f $aDirPath
            }

            $aDirPath
        }
        if (!$dirPaths) {
            return
        }

        $Scope = $Scope + 'Process' | Select-Object -Unique

        foreach ($aScope in $Scope) {
            [string[]]$currentEnvPaths = [System.Environment]::GetEnvironmentVariable('Path', $scopeTargets.$aScope) -split ';'
            $newEnvPath = ($currentEnvPaths + $dirPaths | Where-Object { $_ } | Select-Object -Unique) -join ';'

            if ($pscmdlet.ShouldProcess($newEnvPath, "Set to the Path environment variable for $aScope")) {
                $setEnvArgs = @{
                    Name                 = 'Path'
                    Value                = $newEnvPath
                    $scopeParams.$aScope = $true
                    Force                = $true
                }
                Set-CEnvironmentVariable @setEnvArgs
            }
        }
    }
}
