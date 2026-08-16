function Get-WUEnvironmentVariable {
    <#
    .SYNOPSIS
    Gets one or more environment variable values.

    .DESCRIPTION
    Gets environment variable values from the Process, User, or Machine scope. A missing variable produces no output.

    .PARAMETER Name
    Specifies one or more environment variable names.

    .PARAMETER Scope
    Specifies Process, User, or Machine. The default value is Process.

    .EXAMPLE
    Get-WUEnvironmentVariable -Name 'JAVA_HOME' -Scope User

    Gets JAVA_HOME from the current user environment.

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
        [string]$Scope = 'Process'
    )

    process {
        $target = [System.EnvironmentVariableTarget]$Scope
        foreach ($currentName in $Name) {
            [System.Environment]::GetEnvironmentVariable($currentName, $target)
        }
    }
}
