function Get-WURegistryProperty {
    <#
    .SYNOPSIS
    Gets a registry property.

    .DESCRIPTION
    Gets one named registry property and its registry value type. A missing key or property produces no output.

    .PARAMETER Path
    Specifies a registry provider path.

    .PARAMETER Name
    Specifies the registry property name. An empty string selects the default value.

    .EXAMPLE
    Get-WURegistryProperty -Path 'Registry::HKEY_CURRENT_USER\Software\Example' -Name 'Enabled'

    Gets the Enabled registry property.

    .INPUTS
    None

    .OUTPUTS
    System.Management.Automation.PSCustomObject
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^Registry::HKEY_(CURRENT_USER|LOCAL_MACHINE|CURRENT_CONFIG)\\.+')]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Name
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        return
    }

    $registryKey = Get-Item -LiteralPath $Path -ErrorAction Stop
    if ($Name -notin @($registryKey.GetValueNames())) {
        return
    }

    [pscustomobject]@{
        PSTypeName = 'PSWinUtil.RegistryProperty'
        Path = $Path
        Name = $Name
        Value = $registryKey.GetValue(
            $Name,
            $null,
            [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
        )
        Type = $registryKey.GetValueKind($Name).ToString()
    }
}
