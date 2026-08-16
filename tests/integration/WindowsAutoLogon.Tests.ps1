$isAdministrator = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
$runDestructiveIntegration = $isAdministrator -and $env:PSWINUTIL_RUN_AUTOLOGON_INTEGRATION -eq '1'

BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $manifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
    Import-Module -Name $manifestPath -Force -ErrorAction Stop

    $script:WinlogonPath = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
}

Describe 'Windows auto logon commands' {
    It 'gets auto logon state without exposing a password' {
        $result = Get-WUWindowsAutoLogon

        $result.Enabled | Should -BeOfType ([bool])
        $result.PSObject.TypeNames | Should -Contain 'PSWinUtil.WindowsAutoLogon'
        $result.PSObject.Properties.Name | Should -Not -Contain 'Password'
        $result.PSObject.Properties.Name | Should -Not -Contain 'Secret'
    }

    It 'sets and removes auto logon data in a dedicated test environment' -Skip:(-not $runDestructiveIntegration) {
        $propertyNames = @('AutoAdminLogon', 'DefaultUserName', 'DefaultDomainName')
        $savedProperties = @{}
        foreach ($propertyName in $propertyNames) {
            $savedProperties[$propertyName] = Get-WURegistryProperty -Path $script:WinlogonPath -Name $propertyName
        }
        $password = [securestring]::new()
        foreach ($character in ('PSWinUtil_' + [guid]::NewGuid().ToString('N')).ToCharArray()) {
            $password.AppendChar($character)
        }
        $password.MakeReadOnly()

        try {
            $parameters = @{
                UserName = 'PSWinUtilIntegrationUser'
                Password = $password
                Domain = 'PSWINUTIL'
                PassThru = $true
            }
            $enabledState = Enable-WUWindowsAutoLogon @parameters
            $enabledState.Enabled | Should -BeTrue
            $enabledState.UserName | Should -Be 'PSWinUtilIntegrationUser'
            $enabledState.Domain | Should -Be 'PSWINUTIL'
            Get-WURegistryProperty -Path $script:WinlogonPath -Name 'DefaultPassword' |
                Should -BeNullOrEmpty

            $disabledState = Disable-WUWindowsAutoLogon -PassThru
            $disabledState.Enabled | Should -BeFalse
            $disabledState.UserName | Should -BeNullOrEmpty
            $disabledState.Domain | Should -BeNullOrEmpty
        } finally {
            Set-WUAutoLogonPassword -Password $null -Confirm:$false
            foreach ($propertyName in $propertyNames) {
                $savedProperty = $savedProperties[$propertyName]
                if ($null -eq $savedProperty) {
                    Remove-WURegistryProperty -Path $script:WinlogonPath -Name $propertyName -Confirm:$false
                    continue
                }
                $restoreParameters = @{
                    Path = $script:WinlogonPath
                    Name = $propertyName
                    Value = $savedProperty.Value
                    Type = $savedProperty.Type
                    Confirm = $false
                }
                Set-WURegistryProperty @restoreParameters
            }
        }
    }
}
