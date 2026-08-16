function Get-WUKeyboardRemapping {
    <#
    .SYNOPSIS
    Gets Windows keyboard scan code mappings.

    .DESCRIPTION
    Reads and validates the machine Scancode Map registry value, then returns each mapping. Windows must be restarted before registry changes affect keyboard input.

    .EXAMPLE
    Get-WUKeyboardRemapping

    Gets all configured keyboard scan code mappings.

    .INPUTS
    None

    .OUTPUTS
    PSWinUtil.KeyboardRemapping
    #>
    [CmdletBinding()]
    [OutputType('PSWinUtil.KeyboardRemapping')]
    param()

    $registryPath = 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Keyboard Layout'
    $property = Get-WURegistryProperty -Path $registryPath -Name 'Scancode Map'
    if ($null -eq $property) {
        return
    }
    if ($property.Type -ne 'Binary') {
        throw 'The Scancode Map registry value must have the Binary type.'
    }

    foreach ($mapping in @(ConvertFrom-WUScancodeMap -Value ([byte[]]$property.Value))) {
        [pscustomobject]@{
            PSTypeName = 'PSWinUtil.KeyboardRemapping'
            SourceScanCode = $mapping.SourceScanCode
            DestinationScanCode = $mapping.DestinationScanCode
            RestartRequired = $true
        }
    }
}
