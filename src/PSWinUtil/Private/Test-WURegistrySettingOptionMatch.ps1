function Test-WURegistrySettingOptionMatch {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$PropertyState,

        [Parameter(Mandatory = $true)]
        [string]$OptionName
    )

    foreach ($item in $PropertyState) {
        $option = (@($item.Property.Options | Where-Object { $_.Name -ieq $OptionName }) | Select-Object -First 1)
        if ($option.Action -eq 'Remove') {
            if ($null -ne $item.RegistryProperty) {
                return $false
            }
            continue
        }

        if ($null -eq $item.RegistryProperty -or
            $item.RegistryProperty.Type -ine $item.Property.Type) {
            return $false
        }

        if (-not (Compare-WURegistryValue -ReferenceValue $option.Value -DifferenceValue $item.RegistryProperty.Value)) {
            return $false
        }
    }

    $true
}
