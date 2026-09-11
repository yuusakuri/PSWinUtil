function Format-FlutterSystemArchitectureString {
    <#
    .SYNOPSIS
    Converts a system architecture to a Flutter SDK architecture string.

    .PARAMETER Architecture
    Specifies the system architecture.

    .OUTPUTS
    System.String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Runtime.InteropServices.Architecture]$Architecture
    )

    switch ($Architecture) {
        ([System.Runtime.InteropServices.Architecture]::X64) {
            return 'x64'
        }
        ([System.Runtime.InteropServices.Architecture]::Arm64) {
            return 'arm64'
        }
        default {
            throw "Flutter SDK does not support the system architecture '$Architecture'."
        }
    }
}
