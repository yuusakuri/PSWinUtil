function Install-WUAndroidCli {
    <#
    .SYNOPSIS
    Installs Android CLI.

    .DESCRIPTION
    Installs the official Google.AndroidCLI package with Windows Package Manager. An existing installation is retained.

    .EXAMPLE
    Install-WUAndroidCli

    Installs Android CLI.

    .INPUTS
    None

    .OUTPUTS
    None
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    $shouldProcessParameters = Select-WUBoundParameter `
        -BoundParameters $PSBoundParameters `
        -Name 'WhatIf', 'Confirm'
    Install-WUWingetPackage `
        -Id 'Google.AndroidCLI' `
        @shouldProcessParameters
}
