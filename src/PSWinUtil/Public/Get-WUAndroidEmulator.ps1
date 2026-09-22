function Get-WUAndroidEmulator {
    <#
    .SYNOPSIS
    Lists Android virtual device names that the emulator can start.

    .DESCRIPTION
    The Get-WUAndroidEmulator cmdlet gets the names of AVDs configured in the current Android environment. The list includes running and stopped devices.

    .EXAMPLE
    Get-WUAndroidEmulator

    Lists the names of created Android virtual devices.

    .INPUTS
    None

    .OUTPUTS
    System.String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    Assert-WUCommand -Name 'emulator.exe'

    $result = Invoke-WUNativeCommand `
        -Command 'emulator.exe' `
        -ArgumentList @('-list-avds') `
        -CaptureOutput `
        -WhatIf:$false `
        -ErrorAction Stop

    $avdNames = @(
        $result.StandardOutput | Split-WUNewLine |
            ForEach-Object { $_.Trim() } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )
    $avdNames
}
