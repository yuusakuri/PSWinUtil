function Set-WUEnvironmentVariable {
    <#
    .SYNOPSIS
    Sets one or more environment variables.

    .DESCRIPTION
    Sets an environment variable from a name and value, or reads variables from a PowerShell data file. A null value removes a named variable. The data file root must be a Hashtable. Each key is an environment variable name, and each value must be a string. Process changes affect only the current PowerShell process. User and Machine changes are persistent. Machine changes do not start an elevated process.

    .PARAMETER Name
    Specifies the environment variable name.

    .PARAMETER Value
    Specifies the environment variable value. A null value removes the variable.

    .PARAMETER Path
    Specifies one or more .psd1 files. Each file must contain a Hashtable with environment variable names as keys and strings as values. Wildcards are supported.

    .PARAMETER Scope
    Specifies Process, User, or Machine. The default value is Process.

    .PARAMETER PassThru
    Returns the name, stored value, and scope after each variable is set.

    .EXAMPLE
    Set-WUEnvironmentVariable -Name 'MY_TOOL_HOME' -Value 'C:\Tools' -Scope User

    Sets MY_TOOL_HOME for the current user.

    .EXAMPLE
    Set-WUEnvironmentVariable -Name 'MY_TOOL_HOME' -Value $null -Scope User

    Removes MY_TOOL_HOME from the current user environment.

    .EXAMPLE
    Set-WUEnvironmentVariable -Path '.\environment.psd1' -Scope User -WhatIf

    Shows the variables that would be read from environment.psd1 and set for the current user.

    .INPUTS
    System.String

    .OUTPUTS
    System.Management.Automation.PSCustomObject
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'ByName',
        SupportsShouldProcess = $true
    )]
    param(
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'ByName',
            Position = 0,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^[^=\x00]+$')]
        [string]$Name,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'ByName',
            Position = 1,
            ValueFromPipelineByPropertyName = $true
        )]
        [AllowNull()]
        [object]$Value,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'ByFile',
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ [System.IO.Path]::GetExtension($_) -ieq '.psd1' })]
        [SupportsWildcards()]
        [string[]]$Path,

        [Parameter()]
        [ValidateSet('Process', 'User', 'Machine')]
        [string]$Scope = 'Process',

        [Parameter()]
        [switch]$PassThru
    )

    begin {
        $settings = @()
        $dataPaths = @()
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'ByName') {
            if ($null -ne $Value -and $Value -isnot [string]) {
                throw 'The environment variable value must be a string or null.'
            }

            $settings += [pscustomobject]@{
                Name = $Name
                Value = $Value
                Scope = $Scope
            }
        } else {
            $dataPaths += $Path
        }
    }

    end {
        if ($PSCmdlet.ParameterSetName -eq 'ByFile') {
            $settings = @(Import-WUEnvironmentVariableSetting -Path $dataPaths -Scope $Scope)
        }

        foreach ($setting in $settings) {
            $targetDescription = "$($setting.Scope) environment variable '$($setting.Name)'"
            $actionDescription = 'Set environment variable'
            if ($null -eq $setting.Value) {
                $actionDescription = 'Remove environment variable'
            }

            if (-not $PSCmdlet.ShouldProcess($targetDescription, $actionDescription)) {
                continue
            }

            $target = [System.EnvironmentVariableTarget]$setting.Scope
            [System.Environment]::SetEnvironmentVariable($setting.Name, $setting.Value, $target)
            if ($PassThru) {
                [pscustomobject]@{
                    Name = $setting.Name
                    Value = [System.Environment]::GetEnvironmentVariable($setting.Name, $target)
                    Scope = $setting.Scope
                }
            }
        }
    }
}
