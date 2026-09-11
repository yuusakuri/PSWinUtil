function Get-SystemArchitecture {
    <#
    .SYNOPSIS
    Gets the Windows system architecture.

    .DESCRIPTION
    Returns the system architecture detected from the Windows environment and operating system bitness.

    .EXAMPLE
    Get-SystemArchitecture

    Returns the current system architecture.

    .INPUTS
    None

    .OUTPUTS
    System.Runtime.InteropServices.Architecture
    #>
    [CmdletBinding()]
    [OutputType([System.Runtime.InteropServices.Architecture])]
    param()

    $arch = $env:PROCESSOR_ARCHITECTURE
    $archW6432 = $env:PROCESSOR_ARCHITEW6432

    if ($arch -eq 'ARM64' -or $archW6432 -eq 'ARM64') {
        return [System.Runtime.InteropServices.Architecture]::Arm64
    }

    if ([System.Environment]::Is64BitOperatingSystem) {
        return [System.Runtime.InteropServices.Architecture]::X64
    }

    return [System.Runtime.InteropServices.Architecture]::X86
}
