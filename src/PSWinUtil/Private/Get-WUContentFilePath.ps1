function Get-WUContentFilePath {
    <#
    .SYNOPSIS
    Gets file paths selected by content command parameters.

    .DESCRIPTION
    Resolves Path or LiteralPath with the same filter, include, exclude, and force values used by a content command and returns file system leaf paths.

    .PARAMETER BoundParameter
    Specifies the bound content command parameters.

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
        [System.Collections.IDictionary]$BoundParameter
    )

    $parameters = @{
        ErrorAction = 'Stop'
    }
    $parameters += Select-WUBoundParameter `
        -BoundParameters $BoundParameter `
        -Name 'Filter', 'Include', 'Exclude', 'Force'
    if ($BoundParameter.ContainsKey('LiteralPath')) {
        $parameters.LiteralPath = $BoundParameter.LiteralPath
    } else {
        $parameters.Path = $BoundParameter.Path
    }

    Microsoft.PowerShell.Management\Get-Item @parameters |
        Where-Object {
            -not $_.PSIsContainer -and
            $_.PSProvider.Name -eq 'FileSystem'
        } |
        Select-Object -ExpandProperty FullName
}
