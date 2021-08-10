function Get-WUInstalledDotnetVersion {
    <#
        .SYNOPSIS
        Get the highest version of each .NET installed.

        .DESCRIPTION
        Versions are grouped by framework type and compatibility.

        .OUTPUTS
        Object
        Returns information about installed .NET versions.

        .EXAMPLE
        PS C:\>Get-WUAvailableDotnet

        frameworkName versionRangeNotation version
        ------------- -------------------- -------
        .NETCoreApp   [1.0,2.0)
        .NETCoreApp   [2.0,3.0)            2.2.8
        .NETCoreApp   [3.0,4.0)            3.1.17
        .NETCoreApp   [5.0,6.0)            5.0.8
        .NETFramework [1.0,1.1)
        .NETFramework [1.1,1.2)
        .NETFramework [2.0,4.0)            3.5.30729.4926
        .NETFramework [4.0,5.0)            4.8.04084
        .NETStandard  [1.0,2.2)            2.1
    #>

    [CmdletBinding()]
    param (
    )

    function Get-WUInstalledDotnetVersionFromDotnetRuntimeInfo {
        param (
            $RuntimeInfo
        )

        $RuntimeInfo |
        ForEach-Object {
            $aFrameworkRuntimes = $_

            $aFrameworkRuntimes.versionRangeNotation |
            ForEach-Object {
                $aVersionRangeNotation = $_

                [PSCustomObject]@{
                    frameworkName        = $aFrameworkRuntimes.frameworkName
                    versionRangeNotation = $aVersionRangeNotation
                    version              = . {
                        if (!$aFrameworkRuntimes.installedVersion) {
                            return ''
                        }

                        $aFrameworkRuntimes.installedVersion |
                        Where-Object { Test-WUVersion -Version $_ -VersionRangeNotation $aVersionRangeNotation } |
                        Select-Object -Last 1
                    }
                }
            }
        }
    }

    $installedDotnetVersions = @()

    $runtimeInfos = @(
        @{
            frameworkName        = '.NETCoreApp'
            versionRangeNotation = @(
                # compatibility
                '[1.0,2.0)' # 1.x
                '[2.0,3.0)' # 2.x
                '[3.0,4.0)' # 3.x
                '[5.0,6.0)' # 5.x
            )
            installedVersion     = . {
                if ((Get-Command -Name 'dotnet' -ErrorAction Ignore)) {
                    dotnet --list-runtimes |
                    ForEach-Object {
                        if ($_ -match 'Microsoft.NETCore.App\s+(?<version>\d+[\d.]+)') {
                            $Matches['version']
                        }
                    }
                }
            }
        }
        @{
            frameworkName        = '.NETFramework'
            versionRangeNotation = @(
                # compatibility
                '[1.0,1.1)' # 1.0
                '[1.1,1.2)' # 1.1
                '[2.0,4.0)' # 2.x or 3.x
                '[4.0,5.0)' # 4.x
            )
            installedVersion     = . {
                if ((Get-Command -Name 'dotnetversions')) {
                    dotnetversions -b |
                    ForEach-Object {
                        if ($_ -match '(?<version>\d+[\d.]+)') {
                            $Matches['version']
                        }
                    }
                }
            }
        }
    )

    $installedDotnetVersions += Get-WUInstalledDotnetVersionFromDotnetRuntimeInfo -RuntimeInfo $runtimeInfos

    $runtimeInfos += @{
        frameworkName        = '.NETStandard'
        versionRangeNotation = @(
            # All versions are backward compatible.
            '[1.0,2.2)' # all
        )
        installedVersion     = . {
            $dotnetStandardSupportInfos = @(
                [PSCustomObject]@{
                    '.NETStandard'  = '1.0'
                    '.NETCoreApp'   = '1.0'
                    '.NETFramework' = '4.5'
                }
                [PSCustomObject]@{
                    '.NETStandard'  = '1.1'
                    '.NETCoreApp'   = '1.0'
                    '.NETFramework' = '4.5'
                }
                [PSCustomObject]@{
                    '.NETStandard'  = '1.2'
                    '.NETCoreApp'   = '1.0'
                    '.NETFramework' = '4.5.1'
                }
                [PSCustomObject]@{
                    '.NETStandard'  = '1.3'
                    '.NETCoreApp'   = '1.0'
                    '.NETFramework' = '4.6'
                }
                [PSCustomObject]@{
                    '.NETStandard'  = '1.4'
                    '.NETCoreApp'   = '1.0'
                    '.NETFramework' = '4.6.1'
                }
                [PSCustomObject]@{
                    '.NETStandard'  = '1.5'
                    '.NETCoreApp'   = '1.0'
                    '.NETFramework' = '4.6.11'
                }
                [PSCustomObject]@{
                    '.NETStandard'  = '1.6'
                    '.NETCoreApp'   = '1.0'
                    '.NETFramework' = '4.6.11'
                }
                [PSCustomObject]@{
                    '.NETStandard'  = '2.0'
                    '.NETCoreApp'   = '2.0'
                    '.NETFramework' = '4.6.11'
                }
                [PSCustomObject]@{
                    '.NETStandard'  = '2.1'
                    '.NETCoreApp'   = '3.0'
                    '.NETFramework' = $null
                }
            )

            $dotnetStandardSupportInfos |
            Where-Object {
                $aDotnetStandardSupportInfo = $_

                $frameworkNames = '.NETCoreApp', '.NETFramework'
                foreach ($aFrameworkName in $frameworkNames) {
                    $isSupported = !($null -eq $aDotnetStandardSupportInfo.$aFrameworkName)
                    if (!$isSupported) {
                        continue
                    }

                    $isAvailable = $installedDotnetVersions |
                    Where-Object { $_.frameworkName -eq $aFrameworkName } |
                    Where-Object { $_.version } |
                    Where-Object { Test-WUVersion -Version $aDotnetStandardSupportInfo.$aFrameworkName -VersionRangeNotation $_.versionRangeNotation } |
                    Where-Object { Test-WUVersion -Version $aDotnetStandardSupportInfo.$aFrameworkName -MaximumVersion $_.version }
                    if ($isAvailable) {
                        $true
                        break
                    }
                }
            } |
            Select-Object -ExpandProperty '.NETStandard'
        }
    }

    $installedDotnetVersions += Get-WUInstalledDotnetVersionFromDotnetRuntimeInfo -RuntimeInfo ($runtimeInfos | Select-Object -Last 1)

    return $installedDotnetVersions
}
