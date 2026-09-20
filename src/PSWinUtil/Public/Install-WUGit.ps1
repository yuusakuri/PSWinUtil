function Install-WUGit {
    <#
    .SYNOPSIS
    Installs Git for Windows when the Git command is unavailable.

    .DESCRIPTION
    Checks whether Git is available on PATH. If it is missing, installs the Git.Git package with Windows Package Manager, refreshes the current process environment, and verifies that the Git command is then available.

    .EXAMPLE
    Install-WUGit

    Installs Git for Windows when it is missing and makes the command available in the current process.

    .INPUTS
    None

    .OUTPUTS
    None
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSShouldProcess',
        '',
        Justification = 'Install-WUWingetPackage evaluates ShouldProcess for the delegated installation.'
    )]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    $shouldProcessParameters = Select-WUBoundParameter -BoundParameters $PSBoundParameters -Name 'WhatIf', 'Confirm'

    if (Test-WUCommand -Name 'git.exe') {
        return
    }

    Install-WUWingetPackage -Id 'Git.Git' @shouldProcessParameters
    if ($WhatIfPreference) {
        return
    }

    Update-WUProcessEnvironment
    Assert-WUCommand -Name 'git.exe'
}
