function Import-WUNuGetPackageAssembly {
    <#
        .SYNOPSIS
        Load assemblies from NuGet packages, including its dependencies. It is possible to automatically install the required packages.

        .DESCRIPTION
        Specifies the directory where the NuGet package is installed and the name of the NuGet package, and loads the assembly for that NuGet package with its dependencies. Specifying parameter `-Install` installs the required packages if they do not exist.

        By default, the installation directory for NuGet packages is the directory set in the NUGET_PACKAGE_DIR environment variable. The value of the NUGET_PACKAGE_DIR environment variable is set to `$env:USERPROFILE\NuGet\packages` if it is empty. If the NUGET_PACKAGE_DIR environment variable directory does not exist, the current directory will be NuGet package installation directory.

        The assembly loaded may vary depending on the PowerShell edition.

        .INPUTS
        None

        .OUTPUTS
        None

         .EXAMPLE
        PS C:\>Import-WUNuGetPackageAssembly -PackageID FlaUI.UIA3 -Install

        This example load the assemblies of NuGet package `FlaUI.UIA3` and its dependencies in `$env:NUGET_PACKAGE_DIR`. If the package does not exist, it will be installed.
    #>

    [CmdletBinding(SupportsShouldProcess,
        DefaultParameterSetName = 'Default')]
    param (
        # Specify the name of the folder that contains one or more NuGet packages.
        [Parameter(Mandatory,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $PackageID,

        # Specify parent directory of NuGet packages. By default, the installation directory for NuGet packages is the directory set in the NUGET_PACKAGE_DIR environment variable. The value of the NUGET_PACKAGE_DIR environment variable is set to `$env:USERPROFILE\NuGet\packages` if it is empty. If the NUGET_PACKAGE_DIR environment variable directory does not exist, the current directory will be NuGet package installation directory.
        [ValidateNotNullOrEmpty()]
        [string]
        $PackageDirectoryPath = (
            $env:NUGET_PACKAGE_DIR, $PWD |
            Where-Object { $_ } |
            Where-Object { Test-Path -LiteralPath $_ -PathType Container } |
            Select-Object -First 1
        ),

        # Specifies the maximum allowed version, inclusive.
        [Parameter(ParameterSetName = 'RangedVersion')]
        [Alias('InclusiveMaximumVersion')]
        [string]
        $MaximumVersion,

        # Specifies the minimum allowed version, inclusive.
        [Parameter(ParameterSetName = 'RangedVersion')]
        [Alias('InclusiveMinimumVersion')]
        [string]
        $MinimumVersion,

        # Specifies the minimum allowed version, exclusive.
        [Parameter(ParameterSetName = 'RangedVersion')]
        [string]
        $ExclusiveMaximumVersion,

        # Specifies the minimum allowed version, exclusive.
        [Parameter(ParameterSetName = 'RangedVersion')]
        [string]
        $ExclusiveMinimumVersion,

        # Specifies the exact allowed version.
        [Parameter(ParameterSetName = 'RequiredVersion')]
        [Alias('ExactVersion')]
        [string]
        $RequiredVersion,

        # Specifies interval notation for specifying version ranges.
        [Parameter(ParameterSetName = 'VersionRangeNotation')]
        [string]
        $VersionRangeNotation,

        # Specifies in order which Target Framework assembly to load first. If `$PSVersionTable.PSEdition` is `Core`, the priority is in ascending order of 'net', '.NETCoreApp', '.NETFramework', '.NETStandard', otherwise the priority is in ascending order of '.NETFramework', '.NETStandard', 'net', '.NETCoreApp'.
        [ValidateSet('.NETFramework',
            '.NETStandard',
            'net',
            '.NETCoreApp')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $TargetFrameworkName = $(
            if ($PSVersionTable.PSEdition -eq 'Core') {
                @(
                    'net'
                    '.NETCoreApp'
                    '.NETFramework'
                    '.NETStandard'
                )
            }
            else {
                @(
                    '.NETFramework'
                    '.NETStandard'
                    'net'
                    '.NETCoreApp'
                )
            }
        ),

        # Install the specified packages and their dependencies if they do not exist
        [switch]
        $Install,

        # If the package does not exist, install it even if the type already exists.
        [switch]
        $Force
    )

    function Rename-TargetFramework {
        param (
            [string]
            $Name
        )

        if ($Name -eq 'net') {
            '.NETCoreApp'
        }
        else {
            $Name
        }
    }

    if (!(Assert-WUPathProperty -LiteralPath $PackageDirectoryPath -PSProvider FileSystem -PathType Container)) {
        return
    }

    if ($null -eq $Script:AvailableDotnets) {
        $Script:AvailableDotnets = @()
        $Script:AvailableDotnets += Get-WUAvailableDotnet
    }
    if ($null -eq $Script:DefinedTypes) {
        $Script:DefinedTypes = @()
        $Script:DefinedTypes += [AppDomain]::CurrentDomain.GetAssemblies() | Select-Object -ExpandProperty DefinedTypes | Select-Object -ExpandProperty FullName | Where-Object { $_ -match '^[\w.]+$' }
    }
    if ($null -eq $Script:InstalledNuGetPackages) {
        $Script:InstalledNuGetPackages = @()
        $Script:InstalledNuGetPackages += Get-WUInstalledNuGetPackage -PackageDirectoryPath $PackageDirectoryPath
    }

    $testWUVersionKeyNames = @(
        'MaximumVersion'
        'MinimumVersion'
        'ExclusiveMaximumVersion'
        'ExclusiveMinimumVersion'
        'RequiredVersion'
        'VersionRangeNotation'
    )
    $testWUVersionArgs = @{} + $PSBoundParameters
    [string[]]$testWUVersionArgs.Keys |
    Where-Object { !($_ -in $testWUVersionKeyNames) } |
    ForEach-Object { $testWUVersionArgs.Remove($_) }

    $importWUNuGetPackageAssemblyKeyNames = @(
        'PackageDirectoryPath'
        'MaximumVersion'
        'MinimumVersion'
        'ExclusiveMaximumVersion'
        'ExclusiveMinimumVersion'
        'RequiredVersion'
        'VersionRangeNotation'
    )
    $importWUNuGetPackageAssemblyArgs = @{} + $PSBoundParameters
    [string[]]$importWUNuGetPackageAssemblyArgs.Keys | `
        Where-Object { !($_ -in $importWUNuGetPackageAssemblyKeyNames) } | `
        ForEach-Object { $importWUNuGetPackageAssemblyArgs.Remove($_) }

    foreach ($aPackageID in $PackageID) {
        if (!$Force -and ($Script:DefinedTypes | Where-Object { $_ -like ('{0}*' -f $aPackageID) })) {
            Write-Verbose "Type '$aPackageID' already exists."
            continue
        }

        $aInstalledPackage = $Script:InstalledNuGetPackages |
        Where-Object { $_.id -eq $aPackageID } |
        Where-Object { Test-WUVersion -Version $_.version @testWUVersionArgs }

        if (!$aInstalledPackage) {
            if ($Install) {
                Install-WUApp -Optimize 'NuGet'

                $aRequiredVersion = Find-Package -Name $aPackageID -ProviderName NuGet -AllVersions | `
                    Where-Object { $_.Name -eq $aPackageID } | `
                    Where-Object { Test-WUVersion -Version $_.Version @testWUVersionArgs } | `
                    Select-Object -ExpandProperty Version -First 1

                Write-Verbose "Install the NuGet package. PackageID: '$aPackageID', RequiredVersion: '$aRequiredVersion'"
                Install-WUApp -NuGetPackage $aPackageID -Destination $PackageDirectoryPath -RequiredVersion $aRequiredVersion

                # Update $InstalledNuGetPackages
                $Script:InstalledNuGetPackages = @()
                $Script:InstalledNuGetPackages += Get-WUInstalledNuGetPackage -PackageDirectoryPath $PackageDirectoryPath

                Import-WUNuGetPackageAssembly -PackageID $aPackageID @importWUNuGetPackageAssemblyArgs -TargetFrameworkName $TargetFrameworkName
            }
            else {
                Write-Error "NuGet package '$aPackageID' that meets the version requirements was not found."
            }
            continue
        }

        $availableAssemblies = $aInstalledPackage.assemblies | Where-Object {
            # Returns True if the target framework type and version are available
            $aAssembly = $_
            $aTargetFrameworkType = Rename-TargetFramework -Name $aAssembly.targetFramework.name

            $Script:AvailableDotnets |
            Where-Object { $_.name -eq $aTargetFrameworkType } |
            Where-Object { [System.Version]$aAssembly.targetFramework.version -le [System.Version]$_.version }
        }

        if (!$availableAssemblies) {
            Write-Verbose "There are no assemblies available in NuGet package '$aPackageID'."
            continue
        }

        $aTargetFrameworkType = $TargetFrameworkName |
        Where-Object { $_ -in $availableAssemblies.targetFramework.name } |
        Select-Object -First 1

        $availableAssemblies |
        Where-Object { $_.targetFramework.name -eq $aTargetFrameworkType } |
        Sort-Object { [System.Version]$_.targetFramework.version } |
        Select-Object -Last 1 |
        ForEach-Object {
            $aAssembly = $_

            $aAssemblyPaths = @()
            $aAssemblyPaths += $aAssembly.path | Where-Object { $_ } | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf }

            $aAssembly.dependencies |
            Where-Object { $_ } |
            Where-Object { $_.id -ne $aPackageID } |
            ForEach-Object {
                Write-Verbose ("Resolve the dependency for NuGet package '$aPackageID'. PackageID: '{0}', VersionRangeNotation: '{1}'" -f $_.id, $_.version)
                Import-WUNuGetPackageAssembly -PackageID $_.id -PackageDirectoryPath $PackageDirectoryPath -VersionRangeNotation $_.version  -TargetFrameworkName $TargetFrameworkName -Install:$Install
            }

            if (!$aAssemblyPaths) {
                Write-Verbose "Assembly path for NuGet package '$aPackageID' not found."
                continue
            }

            foreach ($aAssemblyPath in $aAssemblyPaths) {
                $isSucceeded = $false
                for ($i = 0; $i -lt 2; $i++) {
                    try {
                        Write-Verbose "Load assembly '$aAssemblyPath'."
                        Add-Type -LiteralPath $aAssemblyPath
                        $Script:DefinedTypes += $aPackageID
                        $isSucceeded = $true
                    }
                    catch [System.Reflection.ReflectionTypeLoadException] {
                        Write-Verbose "Failed to load the assembly."

                        $_.Exception.LoaderExceptions |
                        Select-Object -ExpandProperty FileName -Unique |
                        ForEach-Object {
                            $null = $_ -match '^(?<id>[\w.]+), Version=(?<version>[\d.]+),'
                            $aDepend = @{
                                id      = $Matches['id']
                                version = $Matches['version']
                            }

                            if ($i -eq 0) {
                                Write-Verbose ("Resolve the dependency indicated by LoaderExceptions for NuGet package '$aPackageID'. PackageID: '{0}', MinimumVersion: '{1}'" -f $aDepend.id, $aDepend.version)
                                Import-WUNuGetPackageAssembly -PackageID $aDepend.id -PackageDirectoryPath $PackageDirectoryPath -MinimumVersion $aDepend.version  -TargetFrameworkName $TargetFrameworkName -Install:$Install -Force
                            }
                            else {
                                Write-Error ("Failed to resolve the Dependency indicated by LoaderExceptions for NuGet package '$aPackageID'. PackageID: '{0}', MinimumVersion: '{1}'" -f $aDepend.id, $aDepend.version)
                            }
                        }
                    }

                    if ($isSucceeded) {
                        break
                    }
                }
            }
        }
    }
}
