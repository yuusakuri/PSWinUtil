<#
    .SYNOPSIS
    Deletes the specified path from the path environment variable.

    .DESCRIPTION
    Removes the specified path from the path environment variable of the specified scope. Wildcards are not supported.

    .EXAMPLE
    PS C:\>Remove-WUEnvPath -Path $env:USERPROFILE

    In this example, Remove $env:USERPROFILE from the process scope path environment variable.

    .LINK
    Add-WUEnvPath
#>

[CmdletBinding(SupportsShouldProcess,
    DefaultParameterSetName = 'Path')]
param (
    # Specifies a path to one or more locations. Wildcards are permitted. The path does not have to exist.
    [Parameter(Mandatory,
        Position = 0,
        ParameterSetName = 'Path',
        ValueFromPipeline,
        ValueFromPipelineByPropertyName)]
    [ValidateNotNullOrEmpty()]
    [SupportsWildcards()]
    [string[]]
    $Path,

    # Specifies a path to one or more locations. Unlike the Path parameter, the value of the LiteralPath parameter is used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters, enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any characters as escape sequences. The path does not have to exist.
    [Parameter(Mandatory,
        Position = 0,
        ParameterSetName = 'LiteralPath',
        ValueFromPipelineByPropertyName)]
    [Alias('PSPath')]
    [ValidateNotNullOrEmpty()]
    [string[]]
    $LiteralPath,

    # Delete the last path in the path environment variable.
    [Parameter(ParameterSetName = 'Lastest',
        Position = 0)]
    [switch]
    $Lastest,

    # Specifies the location where an environment variable. The default Scope is Process.
    [ValidateSet('Process', 'CurrentUser', 'LocalMachine')]
    [string[]]
    $Scope = 'Process'
)

Set-StrictMode -Version 'Latest'

$Scope = $Scope + 'Process' | Select-Object -Unique

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

foreach ($aScope in $Scope) {
    [System.Collections.ArrayList]$envPaths = [array][System.Environment]::GetEnvironmentVariable('Path', $scopeTargets.$aScope) -split ';'

    if ($Lastest) {
        $envPaths.RemoveAt(($envPaths.Count - 1))
    }
    else {
        if ($psCmdlet.ParameterSetName -eq 'Path') {
            $removePaths = Resolve-WUFullPath -Path $Path
        }
        else {
            $removePaths = Resolve-WUFullPath -LiteralPath $LiteralPath
        }

        $envPaths = $envPaths | Where-Object { $removePaths -notcontains $_ }
    }

    $newEnvPath = $envPaths -join ';'

    if ($pscmdlet.ShouldProcess($newEnvPath, "Set to the Path environment variable for $aScope")) {
        $setEnvArgs = @{
            Name                 = 'Path'
            Value                = $newEnvPath
            $scopeParams.$aScope = $true
        }
        Set-CEnvironmentVariable @setEnvArgs
    }
}
