function Test-WUPathProperty {
    <#
        .SYNOPSIS
        Determines if the path properties match. This function is useful for testing if the specified path is a file system and if the extensions match.

        .DESCRIPTION
        Returns `$false` if any of the properties do not match.

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
        Set-StrictMode -Version 'Latest'

        function Test-WUPathPropertyFromPathInfo {
            param (
                [Parameter(Mandatory,
                    Position = 0,
                    ValueFromPipelineByPropertyName)]
                [ValidateNotNullOrEmpty()]
                [System.Management.Automation.PathInfo]
                $PathInfo,

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

            $psproviderMatches = !$PSProvider `
                -or 'Any' -in $PSProvider `
                -or $PathInfo.Provider.Name -in $PSProvider
            if (!$psproviderMatches) {
                if ($Assert) {
                    Write-Error ("The PSProvider of path '{0}' is '{1}'." -f $PathInfo.Path, $PathInfo.Provider.Name)
                }
                return $false
            }

            $pathTypeMatches = !$PathType -or (Test-Path -LiteralPath $PathInfo.Path -PathType $PathType)
            if (!$pathTypeMatches) {
                if ($Assert) {
                    Write-Error ("The PathType of path '{0}' is not '$PathType'." -f $PathInfo.Path)
                }
                return $false
            }

            $extensionMatches = !$Extension `
                -or (($pathExtension = [IO.Path]::GetExtension($PathInfo.Path)) -in $Extension)
            if (!$extensionMatches) {
                if ($Assert) {
                    Write-Error ("The Extension of path '{0}' is '{1}'." -f $PathInfo.Path, $pathExtension)
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
        $paramsOfTestWUPathPropertyFromPathInfo = @{} + $PSBoundParameters
        @() + $paramsOfTestWUPathPropertyFromPathInfo.Keys | `
            Where-Object { $_ -in $removeParamKeys } | `
            ForEach-Object { $paramsOfTestWUPathPropertyFromPathInfo.Remove($_) }
    }
    process {
        if ($psCmdlet.ParameterSetName -eq 'Path') {
            foreach ($aPath in $Path) {
                if (!$Assert -and !(Test-Path -Path $aPath)) {
                    $isValidArray += $false
                    continue
                }

                $pathInfos = @()
                $pathInfos += Resolve-Path -Path $aPath -ErrorAction Continue
                if (!$pathInfos) {
                    $isValidArray += $false
                    continue
                }

                foreach ($aPathInfo in $pathInfos) {
                    $isValidArray += Test-WUPathPropertyFromPathInfo -PathInfo $aPathInfo @paramsOfTestWUPathPropertyFromPathInfo
                }
            }
        }
        else {
            foreach ($aPath in $LiteralPath) {
                if (!$Assert -and !(Test-Path -LiteralPath $aPath)) {
                    $isValidArray += $false
                    continue
                }

                $pathInfos = @()
                $pathInfos += Resolve-Path -LiteralPath $aPath -ErrorAction Continue
                if (!$pathInfos) {
                    $isValidArray += $false
                    continue
                }

                foreach ($aPathInfo in $pathInfos) {
                    $isValidArray += Test-WUPathPropertyFromPathInfo -PathInfo $aPathInfo @paramsOfTestWUPathPropertyFromPathInfo
                }
            }
        }
    }
    end {
        return $isValidArray
    }
}
