function Remove-WUKeyboardRemapping {
    <#
    .SYNOPSIS
    Removes Windows keyboard scan code mappings.

    .DESCRIPTION
    Removes one source scan code mapping or the complete Scancode Map registry value. Other valid mappings are preserved. Windows must be restarted before the change affects keyboard input. The command does not start an elevated process.

    .PARAMETER SourceScanCode
    Specifies the source scan code mapping to remove.

    .PARAMETER All
    Removes the complete Scancode Map registry value.

    .EXAMPLE
    Remove-WUKeyboardRemapping -SourceScanCode 58

    Removes the mapping for the Caps Lock scan code.

    .EXAMPLE
    Remove-WUKeyboardRemapping -All

    Removes all keyboard scan code mappings.

    .INPUTS
    None

    .OUTPUTS
    None
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSShouldProcess',
        '',
        Justification = 'Registry property commands evaluate ShouldProcess for delegated changes.'
    )]
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'BySource')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'BySource')]
        [ValidateRange(1, 65535)]
        [uint16]$SourceScanCode,

        [Parameter(Mandatory = $true, ParameterSetName = 'All')]
        [switch]$All
    )

    $registryPath = 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Keyboard Layout'
    $property = Get-WURegistryProperty -Path $registryPath -Name 'Scancode Map'
    if ($null -eq $property) {
        return
    }

    $shouldProcessParameters = Select-WUBoundParameter -BoundParameters $PSBoundParameters -Name 'WhatIf', 'Confirm'

    if ($All) {
        Remove-WURegistryProperty -Path $registryPath -Name 'Scancode Map' @shouldProcessParameters
        return
    }

    if ($property.Type -ne 'Binary') {
        throw 'The Scancode Map registry value must have the Binary type.'
    }
    $mappings = @(ConvertFrom-WUScancodeMap -Value ([byte[]]$property.Value))

    $remainingMappings = @($mappings | Where-Object { $_.SourceScanCode -ne $SourceScanCode })
    if ($remainingMappings.Count -eq $mappings.Count) {
        return
    }
    if ($remainingMappings.Count -eq 0) {
        Remove-WURegistryProperty -Path $registryPath -Name 'Scancode Map' @shouldProcessParameters
        return
    }

    $value = ConvertTo-WUScancodeMap -Mapping $remainingMappings
    $setParameters = @{
        Path = $registryPath
        Name = 'Scancode Map'
        Value = $value
        Type = 'Binary'
    }
    Set-WURegistryProperty @setParameters @shouldProcessParameters
}
