function Install-WUGit {
    <#
    .SYNOPSIS
    Installs Git for Windows and adds its command directory to PATH.

    .DESCRIPTION
    Installs the Git.Git package by delegating to Install-WUWingetPackage when Git for Windows is not installed yet, and adds the cmd directory of the installation to the requested PATH scopes. The installation directory is detected from the registry keys written by the Git for Windows installer and from the default installation directories, so the PATH item follows the actual installation instead of a fixed path. The cmd directory is added because it holds the git.exe entry point that Git for Windows publishes for other programs, while mingw64\bin also holds the runtime libraries of the Git distribution. An existing PATH item is kept as it is.

    .PARAMETER Scope
    Specifies one or more of Process, User, and Machine PATH values to update. The default value is Process.

    .EXAMPLE
    Install-WUGit

    Installs Git for Windows when it is missing and adds its command directory to the current process PATH.

    .EXAMPLE
    Install-WUGit -Scope Process, Machine

    Installs Git for Windows when it is missing and adds its command directory to the current process and machine PATH.

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
    param(
        [Parameter(Position = 0)]
        [ValidateSet('Process', 'User', 'Machine')]
        [string[]]$Scope = 'Process'
    )

    $shouldProcessParameters = Select-WUBoundParameter -BoundParameters $PSBoundParameters -Name 'WhatIf', 'Confirm'

    $installPath = Get-WUGitInstallPath
    if ([string]::IsNullOrEmpty($installPath)) {
        $installOutput = @(Install-WUWingetPackage -Id 'Git.Git' @shouldProcessParameters)
        $installMessage = $installOutput -join [Environment]::NewLine
        if (-not [string]::IsNullOrEmpty($installMessage)) {
            Write-Verbose -Message $installMessage
        }

        $installPath = Get-WUGitInstallPath
    }

    if ([string]::IsNullOrEmpty($installPath)) {
        if ($WhatIfPreference) {
            Write-Verbose -Message 'The PATH item is determined from the Git for Windows installation directory after the installation.'
            return
        }

        throw 'The Git for Windows installation directory was not found after the installation.'
    }

    $commandPath = Join-Path -Path $installPath -ChildPath 'cmd'
    Add-WUPathEnvironmentVariable -Path $commandPath -Scope $Scope @shouldProcessParameters
}
