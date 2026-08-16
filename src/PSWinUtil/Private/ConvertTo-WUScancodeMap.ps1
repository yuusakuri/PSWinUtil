function ConvertTo-WUScancodeMap {
    <#
    .SYNOPSIS
    Creates a Windows Scancode Map value.

    .DESCRIPTION
    Validates source and destination scan codes and creates the little-endian binary Scancode Map format. Source scan codes must be unique and nonzero.

    .PARAMETER Mapping
    Specifies objects with SourceScanCode and DestinationScanCode properties.

    .EXAMPLE
    ConvertTo-WUScancodeMap -Mapping ([pscustomobject]@{ SourceScanCode = 58; DestinationScanCode = 29 })

    Creates a binary map from Caps Lock to Control.

    .INPUTS
    None

    .OUTPUTS
    System.Byte[]
    #>
    [CmdletBinding()]
    [OutputType([byte[]])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [ValidateNotNull()]
        [object[]]$Mapping
    )

    $normalizedMappings = @()
    $sourceScanCodes = [Collections.Generic.HashSet[uint16]]::new()
    foreach ($currentMapping in $Mapping) {
        if ($null -eq $currentMapping) {
            throw 'A Scancode Map mapping cannot be null.'
        }
        $sourceProperty = $currentMapping.PSObject.Properties['SourceScanCode']
        $destinationProperty = $currentMapping.PSObject.Properties['DestinationScanCode']
        if ($null -eq $sourceProperty -or $null -eq $destinationProperty) {
            throw 'Each Scancode Map mapping requires SourceScanCode and DestinationScanCode.'
        }

        try {
            $sourceNumber = [decimal]$sourceProperty.Value
            $destinationNumber = [decimal]$destinationProperty.Value
        } catch {
            throw 'Scancode Map values must be unsigned 16-bit integers.'
        }
        if (
            $sourceNumber -ne [decimal]::Truncate($sourceNumber) -or
            $destinationNumber -ne [decimal]::Truncate($destinationNumber) -or
            $sourceNumber -lt 0 -or
            $sourceNumber -gt [uint16]::MaxValue -or
            $destinationNumber -lt 0 -or
            $destinationNumber -gt [uint16]::MaxValue
        ) {
            throw 'Scancode Map values must be unsigned 16-bit integers.'
        }
        $sourceScanCode = [uint16]$sourceNumber
        $destinationScanCode = [uint16]$destinationNumber
        if ($sourceScanCode -eq 0) {
            throw 'A Scancode Map source scan code cannot be zero.'
        }
        if (-not $sourceScanCodes.Add($sourceScanCode)) {
            throw "The Scancode Map contains a duplicate source scan code: $sourceScanCode"
        }
        $normalizedMappings += [pscustomobject]@{
            SourceScanCode = $sourceScanCode
            DestinationScanCode = $destinationScanCode
        }
    }

    $entryCount = [uint32]($normalizedMappings.Count + 1)
    $value = [byte[]]::new(12 + ($entryCount * 4))
    $value[8] = [byte]($entryCount -band 0xFF)
    $value[9] = [byte](($entryCount -shr 8) -band 0xFF)
    $value[10] = [byte](($entryCount -shr 16) -band 0xFF)
    $value[11] = [byte](($entryCount -shr 24) -band 0xFF)

    for ($entryIndex = 0; $entryIndex -lt $normalizedMappings.Count; $entryIndex++) {
        $offset = 12 + ($entryIndex * 4)
        $currentMapping = $normalizedMappings[$entryIndex]
        $value[$offset] = [byte]($currentMapping.DestinationScanCode -band 0xFF)
        $value[$offset + 1] = [byte](($currentMapping.DestinationScanCode -shr 8) -band 0xFF)
        $value[$offset + 2] = [byte]($currentMapping.SourceScanCode -band 0xFF)
        $value[$offset + 3] = [byte](($currentMapping.SourceScanCode -shr 8) -band 0xFF)
    }

    Write-Output -NoEnumerate -InputObject $value
}
