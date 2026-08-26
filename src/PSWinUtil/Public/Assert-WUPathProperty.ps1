function Assert-WUPathProperty {
    <#
    .SYNOPSIS
    Requires file system paths to match selected properties.

    .DESCRIPTION
    Uses Test-WUPathProperty and reports an error when a path is missing or does not match every selected property. AllowNonExisting permits a missing path while still validating an existing path. Successful checks produce no output.

    .PARAMETER Path
    Specifies one or more file system paths to check.

    .PARAMETER Leaf
    Requires the path to be a file.

    .PARAMETER Container
    Requires the path to be a directory.

    .PARAMETER Readable
    Requires the path to be readable by the current process.

    .PARAMETER Writable
    Requires the path to be writable by the current process.

    .PARAMETER AllowNonExisting
    Permits a missing path. An existing path must still match every selected property.

    .EXAMPLE
    Assert-WUPathProperty -Path '.\settings.json' -Leaf -Readable

    Completes without output when settings.json is a readable file.

    .EXAMPLE
    Assert-WUPathProperty -Path '.\missing'

    Reports an error because the path does not exist.

    .EXAMPLE
    Assert-WUPathProperty -Path '.\output' -Container -AllowNonExisting

    Completes without output when output is missing or is an existing directory.

    .INPUTS
    System.String

    .OUTPUTS
    None
    #>
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('FullName')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Path,

        [Parameter()]
        [switch]$Leaf,

        [Parameter()]
        [switch]$Container,

        [Parameter()]
        [switch]$Readable,

        [Parameter()]
        [switch]$Writable,

        [Parameter()]
        [switch]$AllowNonExisting
    )

    process {
        foreach ($currentPath in $Path) {
            $fullPath = ConvertTo-WUFullPath -Path $currentPath
            if (
                $AllowNonExisting -and
                -not (Test-Path -LiteralPath $fullPath -ErrorAction Stop)
            ) {
                continue
            }

            $testParameters = Select-WUBoundParameter `
                -BoundParameters $PSBoundParameters `
                -Name 'Leaf', 'Container', 'Readable', 'Writable'
            $testParameters['Path'] = $fullPath

            if (-not (Test-WUPathProperty @testParameters)) {
                throw "The path does not match the required properties: $currentPath"
            }
        }
    }
}
