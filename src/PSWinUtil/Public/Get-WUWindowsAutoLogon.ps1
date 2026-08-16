function Get-WUWindowsAutoLogon {
    <#
    .SYNOPSIS
    Gets the Windows auto logon configuration.

    .DESCRIPTION
    Gets the enabled state, user name, and optional domain from the Winlogon registry key. The password and LSA private data are never read or returned.

    .EXAMPLE
    Get-WUWindowsAutoLogon

    Gets the current Windows auto logon configuration.

    .INPUTS
    None

    .OUTPUTS
    PSWinUtil.WindowsAutoLogon
    #>
    [CmdletBinding()]
    [OutputType('PSWinUtil.WindowsAutoLogon')]
    param()

    $registryPath = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
    $enabledProperty = Get-WURegistryProperty -Path $registryPath -Name 'AutoAdminLogon'
    $userNameProperty = Get-WURegistryProperty -Path $registryPath -Name 'DefaultUserName'
    $domainProperty = Get-WURegistryProperty -Path $registryPath -Name 'DefaultDomainName'

    [pscustomobject]@{
        PSTypeName = 'PSWinUtil.WindowsAutoLogon'
        Enabled = $null -ne $enabledProperty -and [string]$enabledProperty.Value -eq '1'
        UserName = if ($null -eq $userNameProperty) { $null } else { [string]$userNameProperty.Value }
        Domain = if ($null -eq $domainProperty) { $null } else { [string]$domainProperty.Value }
    }
}
