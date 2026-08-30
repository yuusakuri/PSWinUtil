function Set-WURegistryProperty {
    <#
    .SYNOPSIS
    Sets a registry property.

    .DESCRIPTION
    Creates the registry key when needed and sets a named registry property. An identical value and type produce no change. The command does not start an elevated process.

    .PARAMETER Path
    Specifies a registry provider path.

    .PARAMETER Name
    Specifies the registry property name. An empty string selects the default value.

    .PARAMETER Value
    Specifies the registry property value.

    .PARAMETER Type
    Specifies String, ExpandString, Binary, DWord, MultiString, or QWord.

    .PARAMETER PassThru
    Returns the stored registry property.

    .EXAMPLE
    Set-WURegistryProperty -Path 'Registry::HKEY_CURRENT_USER\Software\Example' -Name 'Enabled' -Value 1 -Type DWord

    Creates or updates the Enabled registry property.

    .INPUTS
    None

    .OUTPUTS
    System.Management.Automation.PSCustomObject
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^Registry::HKEY_(CURRENT_USER|LOCAL_MACHINE|CURRENT_CONFIG)\\.+')]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [object]$Value,

        [Parameter(Mandatory = $true)]
        [ValidateSet('String', 'ExpandString', 'Binary', 'DWord', 'MultiString', 'QWord')]
        [string]$Type,

        [Parameter()]
        [switch]$PassThru
    )

    $normalizedValue = $Value
    switch ($Type) {
        'String' { $normalizedValue = [string]$Value; break }
        'ExpandString' { $normalizedValue = [string]$Value; break }
        'Binary' { $normalizedValue = [byte[]]$Value; break }
        'DWord' { $normalizedValue = [int]$Value; break }
        'MultiString' { $normalizedValue = [string[]]$Value; break }
        'QWord' { $normalizedValue = [long]$Value; break }
    }

    $currentProperty = Get-WURegistryProperty -Path $Path -Name $Name
    if (
        $null -ne $currentProperty -and
        $currentProperty.Type -ieq $Type -and
        (Compare-WURegistryValue -ReferenceValue $normalizedValue -DifferenceValue $currentProperty.Value)
    ) {
        if ($PassThru) {
            $currentProperty
        }
        return
    }

    $propertyDescription = $Name
    if ($Name.Length -eq 0) {
        $propertyDescription = '(default)'
    }
    $targetDescription = "${Path}::$propertyDescription"
    if (-not $PSCmdlet.ShouldProcess($targetDescription, 'Set registry property')) {
        return
    }

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        $null = New-Item -Path $Path -Force -ErrorAction Stop
    }
    if ($Name.Length -eq 0) {
        $registryKey = Open-WURegistryKeyForWrite -Path $Path
        try {
            $valueKind = [Microsoft.Win32.RegistryValueKind]::$Type
            $registryKey.SetValue('', $normalizedValue, $valueKind)
        } finally {
            $registryKey.Dispose()
        }
    } else {
        $propertyParameters = @{
            LiteralPath = $Path
            Name = $Name
            Value = $normalizedValue
            PropertyType = $Type
            Force = $true
            ErrorAction = 'Stop'
        }
        $null = New-ItemProperty @propertyParameters
    }

    if ($PassThru) {
        Get-WURegistryProperty -Path $Path -Name $Name
    }
}
