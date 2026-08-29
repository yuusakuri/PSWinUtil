function Get-WUEnvironmentVariable {
    <#
    .SYNOPSIS
    Gets one or more environment variable values.

    .DESCRIPTION
    Gets environment variable values from one or more Process, User, or Machine scopes. A missing variable produces no output.

    .PARAMETER Name
    Specifies one or more environment variable names.

    .PARAMETER Scope
    Specifies one or more of Process, User, and Machine. The default value is Process.

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
        [string[]]$Scope = 'Process'
    )

    process {
        foreach ($inputName in $Name) {
            foreach ($targetScope in $Scope) {
                $target = [System.EnvironmentVariableTarget]$targetScope
                [System.Environment]::GetEnvironmentVariable($inputName, $target)
            }
        }
    }
}
