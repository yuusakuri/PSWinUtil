function ConvertFrom-WUScancodeMap {
    <#
    .SYNOPSIS
    Parses a Windows Scancode Map value.

    .DESCRIPTION
    Validates and parses the binary Scancode Map format. Invalid headers, lengths, entry counts, terminators, zero source scan codes, and duplicate source scan codes produce an error.

    .PARAMETER Value
    Specifies the Scancode Map binary value.

    .EXAMPLE
    ConvertFrom-WUScancodeMap -Value $binaryValue

    Returns each source and destination scan code in the binary value.

    .INPUTS
    None

    .OUTPUTS
    System.Management.Automation.PSCustomObject
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [byte[]]$Value
    )

    if ($Value.Length -lt 16 -or (($Value.Length - 12) % 4) -ne 0) {
        throw 'The Scancode Map length is invalid.'
    }
    for ($index = 0; $index -lt 8; $index++) {
        if ($Value[$index] -ne 0) {
            throw 'The Scancode Map header is invalid.'
        }
    }

    $entryCount = (
        [uint32]$Value[8] -bor
        ([uint32]$Value[9] -shl 8) -bor
        ([uint32]$Value[10] -shl 16) -bor
        ([uint32]$Value[11] -shl 24)
    )
    if ($entryCount -lt 1 -or $Value.Length -ne 12 + ([uint64]$entryCount * 4)) {
        throw 'The Scancode Map entry count is invalid.'
    }

    $terminatorOffset = $Value.Length - 4
    for ($index = $terminatorOffset; $index -lt $Value.Length; $index++) {
        if ($Value[$index] -ne 0) {
            throw 'The Scancode Map terminator is invalid.'
        }
    }

    $sourceScanCodes = [Collections.Generic.HashSet[uint16]]::new()
    for ($entryIndex = 0; $entryIndex -lt ($entryCount - 1); $entryIndex++) {
        $offset = 12 + ($entryIndex * 4)
        $destinationScanCode = [uint16](
            [uint16]$Value[$offset] -bor ([uint16]$Value[$offset + 1] -shl 8)
        )
        $sourceScanCode = [uint16](
            [uint16]$Value[$offset + 2] -bor ([uint16]$Value[$offset + 3] -shl 8)
        )
        if ($sourceScanCode -eq 0) {
            throw 'A Scancode Map source scan code cannot be zero.'
        }
        if (-not $sourceScanCodes.Add($sourceScanCode)) {
            throw "The Scancode Map contains a duplicate source scan code: $sourceScanCode"
        }

        [pscustomobject]@{
            SourceScanCode = $sourceScanCode
            DestinationScanCode = $destinationScanCode
        }
    }
}
