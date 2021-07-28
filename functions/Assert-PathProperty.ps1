function Assert-WUPathProperty {
    <#
        .SYNOPSIS
        Determines if the path properties match. This function is useful for testing if the specified path is a file system and if the extensions match. Writes an error and returns `$false` if any of the properties do not match.

        .DESCRIPTION
        Writes an error and returns `$false` if any of the properties do not match.

        .OUTPUTS
        System.Boolean
        Returns a boolean value indicating whether the path properties match.

        .EXAMPLE
        PS C:\>Assert-WUPathProperty -LiteralPath $env:APPDATA -PSProvider FileSystem

        Returns `$true`.

        .EXAMPLE
        PS C:\>Assert-WUPathProperty -LiteralPath $env:APPDATA -PSProvider FileSystem -PathType Leaf

        Writes an error that PathType of path `$env:APPDATA` is not `Leaf` and Returns `$false`.

        .LINK
        Test-WUPathProperty
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
        $Extension
    )

    begin {
        Set-StrictMode -Version 'Latest'

        $isValidArray = @()

        $removeParamKeys = @(
            'Path'
            'LiteralPath'
        )
        $paramsOfTestWUPathProperty = @{ Assert = $true } + $PSBoundParameters
        @() + $paramsOfTestWUPathProperty.Keys | `
            Where-Object { $_ -in $removeParamKeys } | `
            ForEach-Object { $paramsOfTestWUPathProperty.Remove($_) }
    }
    process {
        if ($psCmdlet.ParameterSetName -eq 'Path') {
            foreach ($aPath in $Path) {
                $isValidArray += Test-WUPathProperty -Path $aPath @paramsOfTestWUPathProperty
            }
        }
        else {
            foreach ($aPath in $LiteralPath) {
                $isValidArray += Test-WUPathProperty -LiteralPath $aPath @paramsOfTestWUPathProperty
            }
        }
    }
    end {
        return $isValidArray
    }
}
