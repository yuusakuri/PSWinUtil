function Import-WUEnvironmentVariableSetting {
    <#
    .SYNOPSIS
    Imports environment variable settings.

    .DESCRIPTION
    Resolves PowerShell data files, imports their Hashtable values, validates them with Test-WUEnvironmentVariableSetting, and returns environment variable setting objects.

    .PARAMETER Path
    Specifies one or more PowerShell data files to import.

    .PARAMETER Scope
    Specifies Process, User, or Machine for every imported setting.

    .EXAMPLE
    Import-WUEnvironmentVariableSetting -Path '.\environment.psd1' -Scope User

    Imports and validates the environment variable settings for the User scope.

    .INPUTS
    None

    .OUTPUTS
    System.Management.Automation.PSCustomObject
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Path,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Process', 'User', 'Machine')]
        [string]$Scope
    )

    $resolvedFiles = @()
    foreach ($currentPath in $Path) {
        $resolvedPaths = @(Resolve-Path -Path $currentPath -ErrorAction Stop)
        foreach ($resolvedPath in $resolvedPaths) {
            if ($resolvedPath.Provider.Name -ne 'FileSystem') {
                throw "The environment file must use the FileSystem provider: $($resolvedPath.Path)"
            }
            if ([System.IO.Path]::GetExtension($resolvedPath.ProviderPath) -ine '.psd1') {
                throw "The environment file must use the .psd1 extension: $($resolvedPath.ProviderPath)"
            }
            if (-not (Test-Path -LiteralPath $resolvedPath.ProviderPath -PathType Leaf)) {
                throw "The environment file was not found: $($resolvedPath.ProviderPath)"
            }

            $resolvedFiles += $resolvedPath.ProviderPath
        }
    }

    $settings = @()
    foreach ($resolvedFile in @($resolvedFiles | Select-Object -Unique)) {
        $environmentVariables = Import-PowerShellDataFile -Path $resolvedFile -ErrorAction Stop
        if (-not (Test-WUEnvironmentVariableSetting -Setting $environmentVariables)) {
            throw "The environment data file must contain valid environment variable settings: $resolvedFile"
        }

        foreach ($environmentEntry in $environmentVariables.GetEnumerator()) {
            $settings += [pscustomobject]@{
                Name = [string]$environmentEntry.Key
                Value = [string]$environmentEntry.Value
                Scope = $Scope
            }
        }
    }

    $settings
}
