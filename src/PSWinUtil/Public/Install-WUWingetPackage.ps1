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

    Assert-WUCommand -Name 'winget.exe'
    $arguments = @(
        'install'
        '--id'
        $Id
        '--exact'
        '--accept-source-agreements'
        '--accept-package-agreements'
    )

    $result = Invoke-WUExternalCommand -Command 'winget.exe' -ArgumentList $arguments -CaptureOutput
    $textOutput = @(
        foreach ($stream in @($result.StandardOutput, $result.StandardError)) {
            $stream -split '\r?\n' | Where-Object { $_ -ne '' }
        }
    )
    if (-not $result.Succeeded) {
        $message = $textOutput -join [Environment]::NewLine
        throw "winget.exe failed with exit code $($result.ExitCode).$([Environment]::NewLine)$message"
    }

    $textOutput
}
