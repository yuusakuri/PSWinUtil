function Install-WUWingetPackage {
    <#
    .SYNOPSIS
    Installs an exact package with Windows Package Manager.

    .DESCRIPTION
    Runs winget install for the specified package ID. The command always requires an exact package ID match and accepts the source and package agreements. Windows Package Manager is not installed automatically.

    .PARAMETER Id
    Specifies the exact Windows Package Manager package ID to install.

    .EXAMPLE
    Install-WUWingetPackage -Id 'Microsoft.PowerShell'

    Installs the package whose exact ID is Microsoft.PowerShell and accepts the required agreements.

    .INPUTS
    None

    .OUTPUTS
    System.String
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Id
    )

    if (-not $PSCmdlet.ShouldProcess($Id, 'Install exact package with Windows Package Manager')) {
        return
    }

    $winget = Get-Command -Name 'winget.exe' -CommandType Application -ErrorAction Stop |
        Select-Object -First 1
    $arguments = @(
        'install'
        '--id'
        $Id
        '--exact'
        '--accept-source-agreements'
        '--accept-package-agreements'
    )

    $commandOutput = @(& $winget.Source @arguments 2>&1)
    $exitCode = $LASTEXITCODE
    $textOutput = @($commandOutput | ForEach-Object { $_.ToString() })
    if ($exitCode -ne 0) {
        $message = $textOutput -join [Environment]::NewLine
        throw "winget.exe failed with exit code $exitCode.$([Environment]::NewLine)$message"
    }

    $textOutput
}
