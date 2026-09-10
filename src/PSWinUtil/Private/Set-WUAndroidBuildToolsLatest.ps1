function Set-WUAndroidBuildToolsLatest {
    <#
    .SYNOPSIS
    Points build-tools latest to an installed version.

    .DESCRIPTION
    Creates or replaces the build-tools latest directory junction. An ordinary file or directory at the latest path is preserved and reported as an error.

    .PARAMETER BuildToolsPath
    Specifies the build-tools directory.

    .PARAMETER Version
    Specifies the installed Build Tools version directory.

    .EXAMPLE
    Set-WUAndroidBuildToolsLatest -BuildToolsPath 'C:\Android\Sdk\build-tools' -Version '36.0.0'

    Points build-tools\latest to build-tools\36.0.0.

    .INPUTS
    None

    .OUTPUTS
    None
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$BuildToolsPath,

        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[0-9]+\.[0-9]+\.[0-9]+$')]
        [string]$Version
    )

    $versionPath = Join-Path -Path $BuildToolsPath -ChildPath $Version
    $latestPath = Join-Path -Path $BuildToolsPath -ChildPath 'latest'

    if (Test-Path -LiteralPath $latestPath) {
        $latestItem = Get-Item -LiteralPath $latestPath -Force -ErrorAction Stop
        if (-not ($latestItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
            throw "The Build Tools latest path is not a directory junction: $latestPath"
        }
        $targetProperty = $latestItem.PSObject.Properties['Target']
        if ($null -ne $targetProperty -and @($targetProperty.Value).Count -gt 0) {
            $currentTarget = [string]@($targetProperty.Value)[0]
            if (-not [System.IO.Path]::IsPathRooted($currentTarget)) {
                $currentTarget = Join-Path -Path $BuildToolsPath -ChildPath $currentTarget
            }
            if (Compare-WUPath -ReferencePath $versionPath -DifferencePath $currentTarget) {
                return
            }
        }
    }

    if (-not $PSCmdlet.ShouldProcess($latestPath, "Point to Build Tools $Version")) {
        return
    }

    $stagingPath = Join-Path `
        -Path $BuildToolsPath `
        -ChildPath ".latest-$([guid]::NewGuid().ToString('N'))"
    try {
        New-Item `
            -Path $stagingPath `
            -ItemType Junction `
            -Target $versionPath `
            -ErrorAction Stop | Out-Null
        if (Test-Path -LiteralPath $latestPath) {
            Remove-Item -LiteralPath $latestPath -Force -ErrorAction Stop
        }
        Move-Item -LiteralPath $stagingPath -Destination $latestPath -ErrorAction Stop
    } finally {
        if (Test-Path -LiteralPath $stagingPath) {
            Remove-Item -LiteralPath $stagingPath -Force -ErrorAction SilentlyContinue
        }
    }
}
