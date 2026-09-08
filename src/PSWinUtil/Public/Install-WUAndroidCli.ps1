function Install-WUAndroidCli {
    <#
    .SYNOPSIS
    Installs Android CLI and adds its directory to PATH.

    .DESCRIPTION
    Installs the official Google.AndroidCLI package with Windows Package Manager when android.exe is missing. The directory containing android.exe is added to the current process and user PATH values. An existing installation is retained.

    .EXAMPLE
    Install-WUAndroidCli

    Installs Android CLI when missing and adds its directory to the current process and user PATH values.

    .INPUTS
    None

    .OUTPUTS
    None
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSShouldProcess',
        '',
        Justification = 'Install-WUWingetPackage and Add-WUPathEnvironmentVariable evaluate ShouldProcess for the delegated changes.'
    )]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    $shouldProcessParameters = Select-WUBoundParameter `
        -BoundParameters $PSBoundParameters `
        -Name 'WhatIf', 'Confirm'
    $androidCliPath = Get-WUAndroidCliPath
    if ([string]::IsNullOrWhiteSpace($androidCliPath)) {
        $installOutput = @(
            Install-WUWingetPackage `
                -Id 'Google.AndroidCLI' `
                @shouldProcessParameters
        )
        $installMessage = $installOutput -join [Environment]::NewLine
        if (-not [string]::IsNullOrWhiteSpace($installMessage)) {
            Write-Verbose -Message $installMessage
        }
        $androidCliPath = Get-WUAndroidCliPath
    }

    if ([string]::IsNullOrWhiteSpace($androidCliPath)) {
        if ($WhatIfPreference) {
            Write-Verbose -Message 'The PATH item is determined from the Android CLI installation after the installation.'
            return
        }
        throw 'The Android CLI executable was not found after the installation.'
    }

    $commandDirectory = Split-Path -Path $androidCliPath -Parent
    Add-WUPathEnvironmentVariable `
        -Path $commandDirectory `
        -Scope 'User', 'Process' `
        @shouldProcessParameters
}
