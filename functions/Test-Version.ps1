﻿function Test-WUVersion {
    <#
        .SYNOPSIS
        Test if a version is in the allowed range.

        .DESCRIPTION
        Specify the allowed version range with parameters `-MaximumVersion`, `-MinimumVersion` and `-RequiredVersion`.

        .EXAMPLE
        PS C:\>Test-WUVersion -Version '1.0' -RequiredVersion '1'

        Returns $true

        PS C:\>Test-WUVersion -Version '2.0' -MaximumVersion '5.0'

        Returns $true

        PS C:\>Test-WUVersion -Version '2.0' -MaximumVersion '5.0' -MinimumVersion '3.0'

        Returns $false

        PS C:\>Test-WUVersion 1.0 -ExclusiveMinimumVersion 1.0

        Returns $false

        PS C:\>Test-WUVersion 1.1 -VersionRangeNotation '[1.0,2.0)'

        Returns $true
    #>

    [CmdletBinding(DefaultParameterSetName = 'RequiredVersion')]
    param (
        # Specify the version you want to test.
        [Parameter(Mandatory,
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Version,

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
        $VersionRangeNotation
    )

    begin {
        Set-StrictMode -Version 'Latest'
    }

    process {
        [string[]]$PSBoundParameters.Keys |
        Where-Object { $_ -in 'Version', 'MaximumVersion', 'MinimumVersion', 'RequiredVersion', 'ExclusiveMaximumVersion', 'ExclusiveMinimumVersion' } |
        ForEach-Object {
            $aVariableName = $_
            $aVersionString = Get-Variable -Name $aVariableName -ValueOnly
            if (!$aVersionString) {
                return
            }

            if (!($aVersionString -match '^[\d][\d\.]*$')) {
                Write-Error "The version string '$aVersionString' specified in parameter '-$aVariableName' is invalid."
                return
            }

            if ($aVersionString -match '^\d+$') {
                # Ex. '1' to '1.0'
                $newVersionString = '{0}.0' -f $aVersionString

                Set-Variable -Name $aVariableName -Value $newVersionString
                $aVersionString = Get-Variable -Name $aVariableName -ValueOnly
            }

            if (!($aVariableName -eq 'Version')) {
                $dotCountDifference = ($Version -replace '[^\.]').Length - ($aVersionString -replace '[^\.]').Length

                if (!($dotCountDifference -eq 0)) {
                    # Ex. '1.0' and '1.0.1' to '1.0.0' and '1.0.1'
                    $isDotCountDifferenceNegative = $dotCountDifference -lt 0
                    $dotCountDifferenceAbsoluteValue = [Math]::Abs($dotCountDifference)
                    for ($i = 0; $i -lt $dotCountDifferenceAbsoluteValue; $i++) {
                        if ($isDotCountDifferenceNegative) {
                            Set-Variable -Name 'Version' -Value ('{0}.0' -f $Version)
                        }
                        else {
                            Set-Variable -Name $aVariableName -Value ('{0}.0' -f $aVersionString)
                        }
                    }
                }
            }
        }

        $allowedVersion = $Version |
        Where-Object {
            if (!$MaximumVersion) {
                return $true
            }
            [version]$_ -le [version]$MaximumVersion
        } |
        Where-Object {
            if (!$MinimumVersion) {
                return $true
            }
            [version]$_ -ge [version]$MinimumVersion
        } |
        Where-Object {
            if (!$ExclusiveMaximumVersion) {
                return $true
            }
            [version]$_ -lt [version]$ExclusiveMaximumVersion
        } |
        Where-Object {
            if (!$ExclusiveMinimumVersion) {
                return $true
            }
            [version]$_ -gt [version]$ExclusiveMinimumVersion
        } |
        Where-Object {
            if (!$RequiredVersion) {
                return $true
            }
            [version]$_ -eq [version]$RequiredVersion
        } |
        Where-Object {
            if (!$VersionRangeNotation) {
                return $true
            }
            # https://docs.microsoft.com/en-us/nuget/concepts/package-versioning#version-ranges
            $versionRangeNotationRegex = @(
                '^(?<InclusiveMinimumVersion>[\d.]+)$'
                '^\((?<ExclusiveMinimumVersion>[\d.]+),\)$'
                '^\[(?<ExactVersion>[\d.]+)]$'
                '^\(,(?<InclusiveMaximumVersion>[\d.]+)]$'
                '^\(,(?<ExclusiveMaximumVersion>[\d.]+)\)$'
                '^\[(?<InclusiveMinimumVersion>[\d.]+),(?<InclusiveMaximumVersion>[\d.]+)]$'
                '^\((?<ExclusiveMinimumVersion>[\d.]+),(?<ExclusiveMaximumVersion>[\d.]+)\)$'
                '^\[(?<InclusiveMinimumVersion>[\d.]+),(?<ExclusiveMaximumVersion>[\d.]+)\)$'
                '^\((?<ExclusiveMinimumVersion>[\d.]+),(?<InclusiveMaximumVersion>[\d.]+)]$'
            ) -join '|'

            if (!($VersionRangeNotation -match $versionRangeNotationRegex)) {
                Write-Error "The interval notation '$VersionRangeNotation' for specifying version ranges is invalid."
                return $false
            }

            $params = @{}
            if ($Matches['ExactVersion']) {
                $params += @{ ExactVersion = $Matches['ExactVersion'] }
            }
            else {
                $params += @{
                    InclusiveMaximumVersion = $Matches['InclusiveMaximumVersion']
                    InclusiveMinimumVersion = $Matches['InclusiveMinimumVersion']
                    ExclusiveMaximumVersion = $Matches['ExclusiveMaximumVersion']
                    ExclusiveMinimumVersion = $Matches['ExclusiveMinimumVersion']
                }
            }
            Test-WUVersion -Version $_ @params
        }

        return [bool]$allowedVersion
    }
}
