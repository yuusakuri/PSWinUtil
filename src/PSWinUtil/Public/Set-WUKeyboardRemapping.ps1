function Set-WUKeyboardRemapping {
    <#
    .SYNOPSIS
    Sets a Windows keyboard scan code mapping.

    .DESCRIPTION
    Adds or updates one source scan code mapping while preserving other valid mappings. A destination scan code of zero disables the source key. Windows must be restarted before the change affects keyboard input. The command does not start an elevated process.

    .PARAMETER SourceScanCode
    Specifies the nonzero source scan code.

    .PARAMETER DestinationScanCode
    Specifies the destination scan code. Zero disables the source key.

    .PARAMETER PassThru
    Returns the stored mapping.

    .EXAMPLE
    Set-WUKeyboardRemapping -SourceScanCode 58 -DestinationScanCode 29

    Maps Caps Lock to Control and reports that a restart is required.

    .INPUTS
    None

    .OUTPUTS
    PSWinUtil.KeyboardRemapping
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSShouldProcess',
        '',
        Justification = 'Set-WURegistryProperty evaluates ShouldProcess for the delegated change.'
    )]
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType('PSWinUtil.KeyboardRemapping')]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 65535)]
        [uint16]$SourceScanCode,

        [Parameter(Mandatory = $true)]
        [uint16]$DestinationScanCode,

        [Parameter()]
        [switch]$PassThru
    )

    $registryPath = 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Keyboard Layout'
    $property = Get-WURegistryProperty -Path $registryPath -Name 'Scancode Map'
    $mappings = @()
    if ($null -ne $property) {
        if ($property.Type -ne 'Binary') {
            throw 'The Scancode Map registry value must have the Binary type.'
        }
        $mappings = @(ConvertFrom-WUScancodeMap -Value ([byte[]]$property.Value))
    }

    $existingMapping = @($mappings | Where-Object { $_.SourceScanCode -eq $SourceScanCode })
    if ($existingMapping.Count -eq 0) {
        $mappings += [pscustomobject]@{
            SourceScanCode = $SourceScanCode
            DestinationScanCode = $DestinationScanCode
        }
    } else {
        $existingMapping[0].DestinationScanCode = $DestinationScanCode
    }

    $value = ConvertTo-WUScancodeMap -Mapping $mappings
    $shouldProcessParameters = Select-WUBoundParameter -BoundParameters $PSBoundParameters -Name 'WhatIf', 'Confirm'
    $setParameters = @{
        Path = $registryPath
        Name = 'Scancode Map'
        Value = $value
        Type = 'Binary'
    }
    Set-WURegistryProperty @setParameters @shouldProcessParameters

    if ($PassThru) {
        Get-WUKeyboardRemapping | Where-Object { $_.SourceScanCode -eq $SourceScanCode }
    }
}
