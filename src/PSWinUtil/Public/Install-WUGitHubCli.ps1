function Install-WUGitHubCli {
    <#
    .SYNOPSIS
    Installs GitHub CLI with Windows Package Manager.

    .DESCRIPTION
    Installs the GitHub.cli package by delegating to Install-WUWingetPackage. The delegated command requires an exact package ID match and accepts the source and package agreements.

    .EXAMPLE
    Install-WUGitHubCli

    Installs GitHub CLI with Windows Package Manager.

    .INPUTS
    None

    .OUTPUTS
    System.String
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSShouldProcess',
        '',
        Justification = 'Install-WUWingetPackage evaluates ShouldProcess for the delegated installation.'
    )]
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([string])]
    param()

    $shouldProcessParameters = Select-WUBoundParameter `
        -BoundParameters $PSBoundParameters `
        -Name 'WhatIf', 'Confirm'

    Install-WUWingetPackage `
        -Id 'GitHub.cli' `
        @shouldProcessParameters
}
