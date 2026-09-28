function Get-WUContentFilePath {
    <#
    .SYNOPSIS
    Gets file paths selected by content command parameters.

    .DESCRIPTION
    Resolves Path or LiteralPath with the same filter, include, exclude, and force values used by a content command and returns file system leaf paths.

    .PARAMETER BoundParameter
    Specifies the bound content command parameters.

    .PARAMETER AllowNonExisting
    Includes fully qualified file system paths for targets that may be created by the content command.

    .EXAMPLE
    Get-WUContentFilePath -BoundParameter $PSBoundParameters

    Returns the selected file paths.

    .INPUTS
    None

    .OUTPUTS
    System.String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$BoundParameter,

        [Parameter()]
        [switch]$AllowNonExisting
    )

    $itemParameters = @{
        ErrorAction = 'Stop'
    }
    $itemParameters += Select-WUBoundParameter -BoundParameters $BoundParameter -Name 'Filter', 'Include', 'Exclude', 'Force'
    if ($BoundParameter.ContainsKey('LiteralPath')) {
        $pathParameterName = 'LiteralPath'
    } else {
        $pathParameterName = 'Path'
    }

    foreach ($pathValue in $BoundParameter[$pathParameterName]) {
        $singlePathParameters = @{} + $itemParameters
        $singlePathParameters[$pathParameterName] = $pathValue
        try {
            $items = @(Microsoft.PowerShell.Management\Get-Item @singlePathParameters)
        } catch [System.Management.Automation.ItemNotFoundException] {
            if (-not $AllowNonExisting) {
                continue
            }
            $provider = $null
            $drive = $null
            $fullPath = $PSCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath(
                $pathValue,
                [ref]$provider,
                [ref]$drive
            )
            if ($pathParameterName -eq 'Path') {
                $fullPath = [System.Management.Automation.WildcardPattern]::Unescape($fullPath)
            }
            if ($provider.Name -eq 'FileSystem') {
                $fullPath
            }
            continue
        }

        $items |
            Where-Object {
                -not $_.PSIsContainer -and
                $_.PSProvider.Name -eq 'FileSystem'
            } |
            Select-Object -ExpandProperty FullName
    }
}
