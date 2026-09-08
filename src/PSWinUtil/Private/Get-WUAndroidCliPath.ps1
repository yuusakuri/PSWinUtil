function Get-WUAndroidCliPath {
    <#
    .SYNOPSIS
    Gets the Android CLI executable path.

    .DESCRIPTION
    Finds android.exe through command discovery and the installation directories used by the official user, administrator, and Windows Package Manager installations. Only an existing file is returned.

    .EXAMPLE
    Get-WUAndroidCliPath

    Returns the path to android.exe when Android CLI is installed.

    .INPUTS
    None

    .OUTPUTS
    System.String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $command = Get-Command `
        -Name 'android.exe' `
        -CommandType Application `
        -ErrorAction Ignore |
        Select-Object -First 1
    if ($null -ne $command) {
        return $command.Source
    }

    $candidatePaths = @()
    if (-not [string]::IsNullOrWhiteSpace($env:USERPROFILE)) {
        $candidatePaths += Join-Path `
            -Path $env:USERPROFILE `
            -ChildPath 'AppData\AndroidCLI\android.exe'
    }
    if (-not [string]::IsNullOrWhiteSpace($env:ProgramData)) {
        $candidatePaths += Join-Path `
            -Path $env:ProgramData `
            -ChildPath 'AndroidCLI\android.exe'
    }
    if (-not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
        $candidatePaths += Join-Path `
            -Path $env:LOCALAPPDATA `
            -ChildPath 'Microsoft\WinGet\Links\android.exe'
    }

    foreach ($candidatePath in $candidatePaths) {
        if (Test-Path -LiteralPath $candidatePath -PathType Leaf) {
            return $candidatePath
        }
    }
}
