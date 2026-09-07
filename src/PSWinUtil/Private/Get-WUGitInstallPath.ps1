function Get-WUGitInstallPath {
    <#
    .SYNOPSIS
    Gets the Git for Windows installation directory.

    .DESCRIPTION
    Reads the installation directory from the machine and user registry keys written by the Git for Windows installer, and then from the default machine and user installation directories. A machine installation is preferred over a user installation because Windows resolves the Machine PATH before the User PATH, and because a machine directory is valid for every PATH scope. Only a directory that contains cmd\git.exe is returned, so a leftover registry value does not produce a path. No output is produced when Git for Windows is not installed.

    .EXAMPLE
    Get-WUGitInstallPath

    Returns C:\Program Files\Git on a computer with the default Git for Windows installation.

    .INPUTS
    None

    .OUTPUTS
    System.String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $registryPaths = @(
        'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\GitForWindows'
        'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\GitForWindows'
        'Registry::HKEY_CURRENT_USER\SOFTWARE\GitForWindows'
    )
    $candidatePaths = @()
    foreach ($registryPath in $registryPaths) {
        $installProperty = Get-WURegistryProperty -Path $registryPath -Name 'InstallPath'
        if ($null -eq $installProperty) {
            continue
        }

        $candidatePaths += [string]$installProperty.Value
    }

    if (-not [string]::IsNullOrWhiteSpace($env:ProgramFiles)) {
        $candidatePaths += Join-Path -Path $env:ProgramFiles -ChildPath 'Git'
    }
    if (-not [string]::IsNullOrWhiteSpace(${env:ProgramFiles(x86)})) {
        $candidatePaths += Join-Path -Path ${env:ProgramFiles(x86)} -ChildPath 'Git'
    }
    if (-not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
        $candidatePaths += Join-Path -Path $env:LOCALAPPDATA -ChildPath 'Programs\Git'
    }

    foreach ($candidatePath in $candidatePaths) {
        if ([string]::IsNullOrWhiteSpace($candidatePath)) {
            continue
        }

        $commandPath = Join-Path -Path $candidatePath -ChildPath 'cmd\git.exe'
        if (Test-Path -LiteralPath $commandPath -PathType Leaf) {
            return $candidatePath
        }
    }
}
