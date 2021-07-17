function Get-WUInstalledNuGetPackage {
    <#
        .SYNOPSIS
        Get information about installed NuGet packages in the NuGet packages installation directory.

        .DESCRIPTION
        Get information about installed NuGet packages in the NuGet packages installation directory.
        By default, the installation directory for NuGet packages is the directory set in the NUGET_PACKAGE_DIR environment variable. The value of the NUGET_PACKAGE_DIR environment variable is set to `$env:USERPROFILE\NuGet\packages` if it is empty. If the NUGET_PACKAGE_DIR environment variable directory does not exist, the current directory will be NuGet package installation directory.

        .INPUTS
        None

        .OUTPUTS
        Object
        Returns information about installed NuGet packages.

        .EXAMPLE
        PS C:\>Get-WUInstalledNuGetPackage
        id                                     version    assemblies
        --                                     -------    ----------
        AngleSharp                             0.16.0     {@{targetFramework=; path=C:\Users\USER\NuGet\packages\A…
        FlaUI.Core                             3.2.0      {@{targetFramework=; path=C:\Users\USER\NuGet\packages\F…
        FlaUI.UIA3                             3.2.0      {@{targetFramework=; path=C:\Users\USER\NuGet\packages\F…

        Returns information about NuGet packages installed in NuGet package installation directory.

        .EXAMPLE
        PS C:\>Get-WUInstalledNuGetPackage -PackageDirectoryPath 'C:\TEST'

        Returns information about NuGet packages installed in specified directory.
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param (
        # Specify parent directory of NuGet packages. By default, the installation directory for NuGet packages is the directory set in the NUGET_PACKAGE_DIR environment variable. The value of the NUGET_PACKAGE_DIR environment variable is set to `$env:USERPROFILE\NuGet\packages` if it is empty. If the NUGET_PACKAGE_DIR environment variable directory does not exist, the current directory will be NuGet package installation directory.
        [ValidateNotNullOrEmpty()]
        [string]
        $PackageDirectoryPath = (
            $env:NUGET_PACKAGE_DIR, $PWD |
            Where-Object { $_ } |
            Where-Object { Test-Path -LiteralPath $_ -PathType Container } |
            Select-Object -First 1
        )
    )

    # [Support multiple .NET versions](https://docs.microsoft.com/en-us/nuget/create-packages/supporting-multiple-target-frameworks)
    # [Target frameworks in SDK-style projects](https://docs.microsoft.com/en-us/dotnet/standard/frameworks)

    function Convert-WUTargetFramework {
        [CmdletBinding(DefaultParameterSetName = 'Path')]
        param (
            [Parameter(Mandatory,
                ParameterSetName = 'FromTargetFramework')]
            [ValidateNotNullOrEmpty()]
            [string]
            $TargetFramework,

            [Parameter(Mandatory,
                ParameterSetName = 'FromTargetFrameworkMoniker')]
            [ValidateNotNullOrEmpty()]
            [string]
            $TargetFrameworkMoniker
        )

        if ($psCmdlet.ParameterSetName -eq 'FromTargetFramework') {
            $TargetFrameworkFullName = $TargetFramework
            $TargetFrameworkName = $TargetFrameworkFullName -replace '[\d][\d.]+.*$'
            $targetFrameworkVersion = [regex]::Matches($TargetFrameworkFullName, '[\d][\d.]+.*$') |
            Where-Object { $_ } |
            Select-Object -ExpandProperty Value

            switch ($TargetFrameworkName) {
                'net' {
                    $TargetFrameworkMonikerName = 'net'
                    $TargetFrameworkMonikerVersion = $TargetFrameworkVersion
                    break
                }
                '.NETCoreApp' {
                    $TargetFrameworkMonikerName = 'netcoreapp'
                    $TargetFrameworkMonikerVersion = $TargetFrameworkVersion
                    break
                }
                '.NETStandard' {
                    $TargetFrameworkMonikerName = 'netstandard'
                    $TargetFrameworkMonikerVersion = $TargetFrameworkVersion
                    break
                }
                '.NETFramework' {
                    $TargetFrameworkMonikerName = 'net'
                    $TargetFrameworkMonikerVersion = ($TargetFrameworkVersion -replace '\.')
                    break
                }
            }

            $TargetFrameworkMonikerFullName = '{0}{1}' -f $TargetFrameworkMonikerName, $TargetFrameworkMonikerVersion
        }
        elseif ($psCmdlet.ParameterSetName -eq 'FromTargetFrameworkMoniker') {
            $TargetFrameworkMonikerFullName = $TargetFrameworkMoniker

            if (!($TargetFrameworkMonikerFullName -match '^(?<tfmName>(net|netcoreapp|netstandard))(?<tfmVersion>[\d.]+)')) {
                Write-Verbose "The specified tfm '$TargetFrameworkMonikerFullName' is not supported."
                return
            }

            [string]$tfmName = $Matches['tfmName']
            [string]$tfmVersion = $Matches['tfmVersion']

            switch ($tfmName) {
                'net' {
                    if ($tfmVersion -match '\.') {
                        $TargetFrameworkName = 'net'
                        $TargetFrameworkVersion = $tfmVersion
                    }
                    else {
                        $TargetFrameworkVersion = $tfmVersion
                        $insertIndex = 1
                        1..($TargetFrameworkVersion.Length - 1) |
                        ForEach-Object {
                            $TargetFrameworkVersion = $TargetFrameworkVersion.Insert($insertIndex, '.')
                            $insertIndex += 2
                        }

                        $TargetFrameworkName = '.NETFramework'
                    }
                    break
                }
                'netcoreapp' {
                    $TargetFrameworkName = '.NETCoreApp'
                    $TargetFrameworkVersion = $tfmVersion
                    break
                }
                'netstandard' {
                    $TargetFrameworkName = '.NETStandard'
                    $TargetFrameworkVersion = $tfmVersion
                    break
                }
            }

            $TargetFrameworkFullName = '{0}{1}' -f $TargetFrameworkName, $TargetFrameworkVersion
        }

        [PSCustomObject]@{
            fullName = $TargetFrameworkFullName
            name     = $TargetFrameworkName
            version  = $TargetFrameworkVersion
            moniker  = $TargetFrameworkMonikerFullName
        }
    }

    if (!(Assert-WUPathProperty -LiteralPath $PackageDirectoryPath -PSProvider FileSystem -PathType Container)) {
        return
    }

    Write-Verbose "NuGet package directory path is '$PackageDirectoryPath'."

    Get-ChildItem -LiteralPath $PackageDirectoryPath -Directory |
    Get-ChildItem -LiteralPath { $_.FullName } -File |
    Where-Object { $_.Extension -eq '.nupkg' } |
    ForEach-Object {
        $aNupkgFile = $_
        $nuspecXml = $null
        $nuspecXml = ConvertTo-WUNuspec -NupkgPath $aNupkgFile.FullName
        if (!$nuspecXml) {
            continue
        }
        $packageRootPath = Split-Path $aNupkgFile.FullName -Parent

        $dependencies = $nuspecXml.package.metadata.dependencies |
        Where-Object { $_ } |
        Select-Object -ExpandProperty group
        if ($dependencies) {
            $assemblies = $dependencies |
            ForEach-Object {
                $aFrameworkDependencies = $_

                $targetFramework = Convert-WUTargetFramework -TargetFramework $aFrameworkDependencies.targetFramework

                [PSCustomObject]@{
                    targetFramework = [PSCustomObject]@{
                        name    = $targetFramework.name

                        version = $targetFramework.version

                        moniker = $targetFramework.moniker
                    }

                    path            = $packageRootPath |
                    Join-Path -ChildPath 'lib' |
                    Join-Path -ChildPath $targetFramework.moniker |
                    Where-Object { Test-Path -LiteralPath $_ -PathType Container } |
                    Get-ChildItem -LiteralPath { $_ } -File |
                    Where-Object { $_.Extension -eq '.dll' } |
                    Select-Object -ExpandProperty FullName

                    dependencies    = $aFrameworkDependencies.dependency |
                    Where-Object { $_ } |
                    ForEach-Object {
                        [PSCustomObject]@{
                            id      = $_.id
                            version = $_.version
                        }
                    }
                }
            }
        }
        else {
            $assemblies = $packageRootPath |
            Join-Path -ChildPath 'lib' |
            Get-ChildItem -LiteralPath { $_ } -Directory |
            Select-Object -ExpandProperty Name |
            ForEach-Object {
                $targetFramework = Convert-WUTargetFramework -TargetFrameworkMoniker $_

                [PSCustomObject]@{
                    targetFramework = [PSCustomObject]@{
                        name    = $targetFramework.name

                        version = $targetFramework.version

                        moniker = $targetFramework.moniker
                    }

                    path            = $packageRootPath |
                    Join-Path -ChildPath 'lib' |
                    Join-Path -ChildPath $targetFramework.moniker |
                    Where-Object { Test-Path -LiteralPath $_ -PathType Container } |
                    Get-ChildItem -LiteralPath { $_ } -File |
                    Where-Object { $_.Extension -eq '.dll' } |
                    Select-Object -ExpandProperty FullName

                    dependencies    = $null
                }
            }
        }

        [PSCustomObject]@{
            id         = $nuspecXml.package.metadata.id

            version    = $nuspecXml.package.metadata.version

            assemblies = $assemblies

            root       = $packageRootPath
        }
    }
}
