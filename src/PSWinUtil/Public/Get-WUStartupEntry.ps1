function Get-WUStartupEntry {
    <#
    .SYNOPSIS
    Gets Windows startup entries.

    .DESCRIPTION
    Gets startup command lines from one or more current user and local machine Run registry keys. Command lines are returned exactly as stored and are not parsed.

    .PARAMETER Name
    Specifies the startup entry name. When omitted, all named entries in the selected scope are returned.

    .PARAMETER Scope
    Specifies one or more of All, User, and Machine. All selects User and Machine. The default value is All.

    .EXAMPLE
    Get-WUStartupEntry -Name 'ExampleApp' -Scope User

    Gets the current user startup entry named ExampleApp.

    .EXAMPLE
    Get-WUStartupEntry -Name 'ExampleApp' -Scope User, Machine

    Gets ExampleApp from the current user and local machine startup entries.

    .INPUTS
    None

    .OUTPUTS
    PSWinUtil.StartupEntry
    #>
    [CmdletBinding()]
    [OutputType('PSWinUtil.StartupEntry')]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter()]
        [ValidateSet('All', 'User', 'Machine')]
        [string[]]$Scope = 'All'
    )

    $scopePaths = [ordered]@{
        User = 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run'
        Machine = 'Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run'
    }
    $selectedScopes = @($scopePaths.Keys)
    if ($Scope -notcontains 'All') {
        $selectedScopes = @($Scope | Select-Object -Unique)
    }

    foreach ($selectedScope in $selectedScopes) {
        $registryPath = $scopePaths[$selectedScope]
        if (-not (Test-Path -LiteralPath $registryPath -PathType Container)) {
            continue
        }

        $registryKey = Get-Item -LiteralPath $registryPath -ErrorAction Stop
        $valueNames = @($registryKey.GetValueNames() | Where-Object { -not [string]::IsNullOrEmpty($_) })
        if ($PSBoundParameters.ContainsKey('Name')) {
            $valueNames = @($valueNames | Where-Object { $_ -eq $Name })
        }

        foreach ($valueName in $valueNames) {
            [pscustomobject]@{
                PSTypeName = 'PSWinUtil.StartupEntry'
                Name = $valueName
                Scope = $selectedScope
                CommandLine = $registryKey.GetValue(
                    $valueName,
                    $null,
                    [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
                )
            }
        }
    }
}
