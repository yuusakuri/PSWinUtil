function Get-WUEnvironmentVariable {
    <#
    .SYNOPSIS
    Reads environment variable values from Process, User, or Machine scope.

    .DESCRIPTION
    Gets environment variable values from one or more Process, User, or Machine scopes. A missing variable produces no output.

    .PARAMETER Name
    Specifies one or more environment variable names.

    .PARAMETER Scope
    Specifies one or more of Process, User, and Machine. The default value is Process.

    .PARAMETER NoExpand
    Returns persistent User or Machine values without expanding environment variable references. Process values are unchanged.

    .EXAMPLE
    Get-WUEnvironmentVariable -Name 'JAVA_HOME' -Scope User

    Gets JAVA_HOME from the current user environment.

    .EXAMPLE
    Get-WUEnvironmentVariable -Name 'JAVA_HOME' -Scope Process, User

    Gets JAVA_HOME from the current process and current user environments in the specified order.

    .INPUTS
    System.String

    .OUTPUTS
    System.String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^[^=\x00]+$')]
        [string[]]$Name,

        [Parameter()]
        [ValidateSet('Process', 'User', 'Machine')]
        [string[]]$Scope = 'Process',

        [Parameter()]
        [switch]$NoExpand
    )

    process {
        foreach ($inputName in $Name) {
            foreach ($targetScope in $Scope) {
                if ($targetScope -eq 'Process' -or -not $NoExpand) {
                    [System.Environment]::GetEnvironmentVariable(
                        $inputName,
                        [System.EnvironmentVariableTarget]$targetScope
                    )
                    continue
                }

                $registryPath = if ($targetScope -eq 'User') {
                    'Environment'
                } else {
                    'SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
                }
                $baseKey = if ($targetScope -eq 'User') {
                    [Microsoft.Win32.Registry]::CurrentUser
                } else {
                    [Microsoft.Win32.Registry]::LocalMachine
                }
                $registryKey = $baseKey.OpenSubKey($registryPath, $false)
                if ($null -eq $registryKey) {
                    continue
                }

                try {
                    $registryKey.GetValue(
                        $inputName,
                        $null,
                        [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
                    )
                } finally {
                    $registryKey.Dispose()
                }
            }
        }
    }
}
