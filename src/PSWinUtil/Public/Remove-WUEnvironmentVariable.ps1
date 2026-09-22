function Remove-WUEnvironmentVariable {
    <#
    .SYNOPSIS
    Removes environment variables from selected Process, User, or Machine scopes.

    .DESCRIPTION
    Removes one or more environment variables from Process, User, or Machine scopes. Missing variables are ignored. When persistent User or Machine values change, one Windows environment-change notification is sent after all names have been processed. Supports WhatIf and Confirm for each selected name and scope.

    .PARAMETER Name
    Specifies one or more environment variable names.

    .PARAMETER Scope
    Specifies one or more of Process, User, and Machine. The default value is Process.

    .EXAMPLE
    Remove-WUEnvironmentVariable -Name 'MY_TOOL_HOME' -Scope User

    Removes MY_TOOL_HOME from the current user environment.

    .EXAMPLE
    Remove-WUEnvironmentVariable -Name 'MY_TOOL_HOME' -Scope Process, User

    Removes MY_TOOL_HOME from the current process and current user environments.

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
        [string[]]$Scope = 'Process'
    )

    begin {
        $settings = @()
        $shouldProcessParameters = Select-WUBoundParameter -BoundParameters $PSBoundParameters -Name 'WhatIf', 'Confirm'
    }

    process {
        foreach ($inputName in $Name) {
            $settings += [pscustomobject]@{
                Name = $inputName
                Value = $null
            }
        }
    }

    end {
        $settings | Set-WUEnvironmentVariable -Scope $Scope @shouldProcessParameters
    }
}
