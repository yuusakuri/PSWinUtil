function Remove-WURegistryProperty {
    <#
    .SYNOPSIS
    Removes a registry property.

    .DESCRIPTION
    Removes one named registry property. A missing key or property produces no change. The registry key is preserved.

    .PARAMETER Path
    Specifies a registry provider path.

    .PARAMETER Name
    Specifies the registry property name.

    .EXAMPLE
    Remove-WURegistryProperty `
        -Path 'Registry::HKEY_CURRENT_USER\Software\Example' `
        -Name 'Enabled'

    Removes the Enabled registry property when it exists.

    .INPUTS
    None

    .OUTPUTS
    None
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^Registry::HKEY_(CURRENT_USER|LOCAL_MACHINE|CURRENT_CONFIG)\\.+')]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    if ($null -eq (Get-WURegistryProperty -Path $Path -Name $Name)) {
        return
    }

    $targetDescription = "${Path}::$Name"
    if (-not $PSCmdlet.ShouldProcess($targetDescription, 'Remove registry property')) {
        return
    }

    Remove-ItemProperty -LiteralPath $Path -Name $Name -ErrorAction Stop
}
