function Disable-WUWindowsAutoLogon {
    <#
    .SYNOPSIS
    Disables Windows auto logon.

    .DESCRIPTION
    Disables Windows auto logon before removing its LSA password, default user name, and default domain. The command does not start an elevated process.

    .PARAMETER PassThru
    Returns the resulting Windows auto logon configuration without a password.

    .EXAMPLE
    Disable-WUWindowsAutoLogon

    Disables Windows auto logon and removes its stored account information.

    .INPUTS
    None

    .OUTPUTS
    PSWinUtil.WindowsAutoLogon
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSShouldProcess',
        '',
        Justification = 'Registry commands and Set-WUAutoLogonPassword evaluate each delegated change.'
    )]
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType('PSWinUtil.WindowsAutoLogon')]
    param(
        [Parameter()]
        [switch]$PassThru
    )

    $registryPath = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
    $shouldProcessParameters = Select-WUBoundParameter -BoundParameters $PSBoundParameters -Name 'WhatIf', 'Confirm'

    $disabledParameters = @{
        Path = $registryPath
        Name = 'AutoAdminLogon'
        Value = '0'
        Type = 'String'
    }
    Set-WURegistryProperty @disabledParameters @shouldProcessParameters
    Set-WUAutoLogonPassword -Password $null @shouldProcessParameters
    Remove-WURegistryProperty -Path $registryPath -Name 'DefaultUserName' @shouldProcessParameters
    Remove-WURegistryProperty -Path $registryPath -Name 'DefaultDomainName' @shouldProcessParameters

    if ($PassThru) {
        Get-WUWindowsAutoLogon
    }
}
