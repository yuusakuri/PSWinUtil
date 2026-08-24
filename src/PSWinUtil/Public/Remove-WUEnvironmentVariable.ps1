function Remove-WUEnvironmentVariable {
    <#
    .SYNOPSIS
    Removes an environment variable.

    .DESCRIPTION
    Removes an environment variable from the Process, User, or Machine scope. If the variable does not exist, the command makes no change. Machine changes do not start an elevated process.

    .PARAMETER Name
    Specifies the environment variable name.

    .PARAMETER Scope
    Specifies Process, User, or Machine. The default value is Process.

    .EXAMPLE
    Remove-WUEnvironmentVariable -Name 'MY_TOOL_HOME' -Scope User

    Removes MY_TOOL_HOME from the current user environment.

    .INPUTS
    System.String

    .OUTPUTS
    None
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSShouldProcess',
        '',
        Justification = 'Set-WUEnvironmentVariable evaluates ShouldProcess for the delegated change.'
    )]
    [CmdletBinding(SupportsShouldProcess = $true)]
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

    begin {
        $shouldProcessParameters = Select-WUBoundParameter `
            -BoundParameters $PSBoundParameters `
            -Name 'WhatIf', 'Confirm'
    }

    process {
        foreach ($currentName in $Name) {
            Set-WUEnvironmentVariable `
                -Name $currentName `
                -Value $null `
                -Scope $Scope `
                @shouldProcessParameters
        }
    }
}
