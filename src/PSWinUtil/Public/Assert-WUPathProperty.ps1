function Assert-WUPathProperty {
    <#
    .SYNOPSIS
    Requires file system paths to match selected properties.

    .DESCRIPTION
    Uses Test-WUPathProperty and reports an error when a path is missing or does not match every selected property. Successful checks produce no output.

    .PARAMETER Path
    Specifies one or more file system paths to check.

    .PARAMETER Exists
    Requires the path to exist.

    .PARAMETER Leaf
    Requires the path to be a file.

    .PARAMETER Container
    Requires the path to be a directory.

    .PARAMETER Readable
    Requires the path to be readable by the current process.

    .PARAMETER Writable
    Requires the path to be writable by the current process.

    .EXAMPLE
    Assert-WUPathProperty -Path '.\settings.json' -Leaf -Readable

    Completes without output when settings.json is a readable file.

    .EXAMPLE
    Assert-WUPathProperty -Path '.\missing' -Exists

    Reports an error because the path does not exist.

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
        [switch]$Exists,

        [Parameter()]
        [switch]$Leaf,

        [Parameter()]
        [switch]$Container,

        [Parameter()]
        [switch]$Readable,

        [Parameter()]
        [switch]$Writable
    )

    process {
        foreach ($currentPath in $Path) {
            $testParameters = @{
                Path = $currentPath
            }
            foreach ($conditionName in @('Exists', 'Leaf', 'Container', 'Readable', 'Writable')) {
                if ($PSBoundParameters.ContainsKey($conditionName) -and $PSBoundParameters[$conditionName]) {
                    $testParameters[$conditionName] = $true
                }
            }

            if (-not (Test-WUPathProperty @testParameters)) {
                throw "The path does not match the required properties: $currentPath"
            }
        }
    }
}
