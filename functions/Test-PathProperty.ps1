function Test-WUPathProperty {
    <#
        .SYNOPSIS
        Determines if the path properties match. Returns `$false` if any of the properties do not match.

        .DESCRIPTION
        Returns `$false` if any of the properties do not match. However, it writes an error and returns `$false` for paths that are not allowed access.

        .OUTPUTS
        System.Boolean
        Returns a boolean value indicating whether the path properties match.

        .EXAMPLE
        PS C:\>Test-WUPathProperty -LiteralPath $env:APPDATA -PSProvider FileSystem

        In this example, `$true` is returned because the PSProvider of path `$env:APPDATA` is FileSystem.

        .EXAMPLE
        PS C:\>Test-WUPathProperty -LiteralPath $env:APPDATA -PSProvider FileSystem -PathType Leaf

        In this example, `$false` is returned because the PathType of path `$env:APPDATA` is Container.

        .LINK
        Assert-WUPathProperty
    #>

    [CmdletBinding(DefaultParameterSetName = 'Path')]
    param (
        # Specifies a path to one or more locations. Wildcards are permitted.
        [Parameter(Position = 0,
            ParameterSetName = 'Path',
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [string[]]
        $Path = $PWD,

        # Specifies a path to one or more locations. Unlike the Path parameter, the value of the LiteralPath parameter is used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters, enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any characters as escape sequences.
        [Parameter(Mandatory,
            Position = 0,
            ParameterSetName = 'LiteralPath',
            ValueFromPipelineByPropertyName)]
        [Alias('PSPath')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $LiteralPath,

        # Specifies the Windows PowerShell provider that is determined to match the path. Returns `$True` if the Windows PowerShell provider of the path matches any value of this parameter and $False if it is not.
        [ValidateSet('Any', 'FileSystem', 'Registry', 'Alias', 'Environment', 'Function', 'Variable', 'Certificate', 'WSMan')]
        [string[]]
        $PSProvider,

        # Specifies the type of the final element in the path. This cmdlet returns `$True` if the element is of the specified type and `$False` if it is not. The acceptable values for this parameter are:
        #
        # - Container. An element that contains other elements, such as a directory or registry key.
        # - Leaf. An element that does not contain other elements, such as a file.
        # - Any. Either a container or a leaf.
        #
        # Tells whether the final element in the path is of a particular type.
        [ValidateSet('Any', 'Container', 'Leaf')]
        [string]
        $PathType,

        # Specifies the allowed extensions. Must be specified including `.` (dot). Returns `$True` if the extension of the path matches any value of this parameter and $False if it is not.
        [string[]]
        $Extension,

        # Write errors if there are elements that do not match.
        [switch]
        $Assert
    )

    begin {
        function Test-WUPathPropertyFromLiteralPath {
            param (
                [Parameter(Mandatory,
                    Position = 0,
                    ValueFromPipelineByPropertyName)]
                [Alias('PSPath')]
                [ValidateNotNullOrEmpty()]
                [string]
                $LiteralPath,

                [ValidateSet('Any', 'FileSystem', 'Registry', 'Alias', 'Environment', 'Function', 'Variable', 'Certificate', 'WSMan')]
                [string[]]
                $PSProvider,

                [ValidateSet('Any', 'Container', 'Leaf')]
                [string]
                $PathType,

                [string[]]
                $Extension,

                [switch]
                $Assert
            )

            $aItem = $null
            $aItem = Get-Item -LiteralPath $LiteralPath -ErrorAction Continue
            if (!$aItem) {
                return $false
            }

            $psproviderMatches = !$PSProvider `
                -or 'Any' -in $PSProvider `
                -or $aItem.PSProvider.Name -in $PSProvider
            if (!$psproviderMatches) {
                if ($Assert) {
                    Write-Error ("The PSProvider of path '{0}' is '{1}'." -f $LiteralPath, $aItem.PSProvider.Name)
                }
                return $false
            }

            $pathTypeMatches = !$PathType -or (Test-Path -LiteralPath $LiteralPath -PathType $PathType)
            if (!$pathTypeMatches) {
                if ($Assert) {
                    Write-Error "The PathType of path '$LiteralPath' is not '$PathType'."
                }
                return $false
            }

            $extensionMatches = !$Extension `
                -or ($aItem.Extension -and $aItem.Extension -in $Extension)
            if (!$extensionMatches) {
                if ($Assert) {
                    Write-Error ("The Extension of path '$LiteralPath' is '{0}'." -f $aItem.Extension)
                }
                return $false
            }

            return $true
        }

        $isValidArray = @()

        $removeParamKeys = @(
            'Path'
            'LiteralPath'
        )
        $paramsOfTestWUPathElement = @{} + $PSBoundParameters
        @() + $paramsOfTestWUPathElement.Keys | `
            Where-Object { $_ -in $removeParamKeys } | `
            ForEach-Object { $paramsOfTestWUPathElement.Remove($_) }
    }
    process {
        if ($psCmdlet.ParameterSetName -eq 'Path') {
            foreach ($aPath in $Path) {
                $fullPaths = @()
                $fullPaths += Resolve-Path -Path $aPath -ErrorAction Continue | Select-Object -ExpandProperty Path
                if (!$fullPaths) {
                    $isValidArray += $false
                    continue
                }

                foreach ($aFullPath in $fullPaths) {
                    $isValidArray += Test-WUPathPropertyFromLiteralPath -LiteralPath $aFullPath @paramsOfTestWUPathElement
                }
            }
        }
        else {
            foreach ($aPath in $LiteralPath) {
                $fullPaths = @()
                $fullPaths += Resolve-Path -LiteralPath $aPath -ErrorAction Continue | Select-Object -ExpandProperty Path
                if (!$fullPaths) {
                    $isValidArray += $false
                    continue
                }

                foreach ($aFullPath in $fullPaths) {
                    $isValidArray += Test-WUPathPropertyFromLiteralPath -LiteralPath $aFullPath @paramsOfTestWUPathElement
                }
            }
        }
    }
    end {
        return $isValidArray
    }
}
