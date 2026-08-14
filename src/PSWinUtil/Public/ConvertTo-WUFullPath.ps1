function ConvertTo-WUFullPath {
    <#
    .SYNOPSIS
    Converts file system paths to fully qualified paths.

    .DESCRIPTION
    Converts relative or fully qualified file system paths without checking whether they exist. Paths from other PowerShell providers are rejected.

    .PARAMETER Path
    Specifies one or more file system paths to convert.

    .EXAMPLE
    ConvertTo-WUFullPath -Path '.\logs\app.log'

    Returns the fully qualified file system path without requiring the file to exist.

    .EXAMPLE
    ConvertTo-WUFullPath -Path 'Env:\Path'

    Reports an error because the Environment provider is not a file system provider.

    .INPUTS
    System.String

    .OUTPUTS
    System.String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('FullName')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Path
    )

    process {
        foreach ($currentPath in $Path) {
            $provider = $null
            $drive = $null
            $fullPath = $PSCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath(
                $currentPath,
                [ref]$provider,
                [ref]$drive
            )
            if ($provider.Name -ne 'FileSystem') {
                throw "The path must use the FileSystem provider: $currentPath"
            }

            $fullPath
        }
    }
}
