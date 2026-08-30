function Enable-WUWindowsAutoLogon {
    <#
    .SYNOPSIS
    Enables Windows auto logon.

    .DESCRIPTION
    Stores the user name and optional domain in the Winlogon registry key, stores the password as LSA private data, and enables auto logon last. The password is never stored in the registry or returned. The command does not start an elevated process.

    .PARAMETER UserName
    Specifies the Windows account user name.

    .PARAMETER Password
    Specifies the account password as a secure string.

    .PARAMETER Domain
    Specifies the account domain. When omitted, the existing default domain is removed.

    .PARAMETER PassThru
    Returns the resulting Windows auto logon configuration without a password.

    .EXAMPLE
    Enable-WUWindowsAutoLogon -UserName 'ExampleUser' -Password $securePassword -Domain 'EXAMPLE'

    Enables auto logon for the EXAMPLE domain account.

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
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$UserName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [ValidateScript({ $_.Length -le 32766 })]
        [securestring]$Password,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Domain,

        [Parameter()]
        [switch]$PassThru
    )

    $registryPath = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
    $shouldProcessParameters = Select-WUBoundParameter -BoundParameters $PSBoundParameters -Name 'WhatIf', 'Confirm'

    $userNameParameters = @{
        Path = $registryPath
        Name = 'DefaultUserName'
        Value = $UserName
        Type = 'String'
    }
    Set-WURegistryProperty @userNameParameters @shouldProcessParameters

    if ($PSBoundParameters.ContainsKey('Domain')) {
        $domainParameters = @{
            Path = $registryPath
            Name = 'DefaultDomainName'
            Value = $Domain
            Type = 'String'
        }
        Set-WURegistryProperty @domainParameters @shouldProcessParameters
    } else {
        Remove-WURegistryProperty -Path $registryPath -Name 'DefaultDomainName' @shouldProcessParameters
    }

    Set-WUAutoLogonPassword -Password $Password @shouldProcessParameters

    $enabledParameters = @{
        Path = $registryPath
        Name = 'AutoAdminLogon'
        Value = '1'
        Type = 'String'
    }
    Set-WURegistryProperty @enabledParameters @shouldProcessParameters

    if ($PassThru) {
        Get-WUWindowsAutoLogon
    }
}
