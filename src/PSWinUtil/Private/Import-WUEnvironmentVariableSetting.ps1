function Import-WUEnvironmentVariableSetting {
    <#
    .SYNOPSIS
    Imports environment variable settings.

    .DESCRIPTION
    Resolves PowerShell data files, imports their Hashtable values, validates them with Test-WUEnvironmentVariableSetting, and returns environment variable setting objects for every selected scope.

    .PARAMETER Path
    Specifies one or more PowerShell data files to import. Wildcards are supported.

    .PARAMETER LiteralPath
    Specifies one or more PowerShell data files to import without wildcard interpretation.

    .PARAMETER Scope
    Specifies one or more of Process, User, and Machine for every imported setting.

    .EXAMPLE
    Import-WUEnvironmentVariableSetting -Path '.\environment.psd1' -Scope User

    Imports and validates the environment variable settings for the User scope.

    .EXAMPLE
    Import-WUEnvironmentVariableSetting -LiteralPath '.\environment[1].psd1' -Scope Process, User

    Imports the exact file and returns each setting for the Process and User scopes.

    .INPUTS
    None

    .OUTPUTS
    System.Management.Automation.PSCustomObject
    #>
    [CmdletBinding(DefaultParameterSetName = 'Path')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'Path')]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [string[]]$Path,

        [Parameter(Mandatory = $true, ParameterSetName = 'LiteralPath')]
        [Alias('PSPath', 'LP')]
        [ValidateNotNullOrEmpty()]
        [string[]]$LiteralPath,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Process', 'User', 'Machine')]
        [string[]]$Scope
    )

    $resolveParameters = @{
        ParameterSetName = $PSCmdlet.ParameterSetName
        Path = $Path
        LiteralPath = $LiteralPath
    }
    $resolvedFiles = @(
        Resolve-WUPathFromParameter @resolveParameters |
            ConvertTo-WUFullPath
    )
    Assert-WUPathProperty -LiteralPath $resolvedFiles -Leaf
    foreach ($resolvedFile in $resolvedFiles) {
        if ([System.IO.Path]::GetExtension($resolvedFile) -ine '.psd1') {
            throw "The environment file must use the .psd1 extension: $resolvedFile"
        }
    }

    $settings = @()
    foreach ($resolvedFile in @($resolvedFiles | Select-Object -Unique)) {
        $environmentVariables = Import-PowerShellDataFile `
            -LiteralPath $resolvedFile `
            -ErrorAction Stop
        if (-not (Test-WUEnvironmentVariableSetting -Setting $environmentVariables)) {
            throw "The environment data file must contain valid environment variable settings: $resolvedFile"
        }

        foreach ($environmentEntry in $environmentVariables.GetEnumerator()) {
            foreach ($currentScope in $Scope) {
                $settings += [pscustomobject]@{
                    Name = [string]$environmentEntry.Key
                    Value = [string]$environmentEntry.Value
                    Scope = $currentScope
                }
            }
        }
    }

    $settings
}
