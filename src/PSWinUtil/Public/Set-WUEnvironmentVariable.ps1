function Set-WUEnvironmentVariable {
    <#
    .SYNOPSIS
    Sets one or more environment variables.

    .DESCRIPTION
    Sets an environment variable from a name and value, or reads variables from a PowerShell data file. The data file root must be a Hashtable. Each key is an environment variable name, and each value must be a string. Process changes affect only the current PowerShell process. User and Machine changes are persistent. Machine changes do not start an elevated process.

    .PARAMETER Name
    Specifies the environment variable name.

    .PARAMETER Value
    Specifies the environment variable value.

    .PARAMETER Path
    Specifies one or more .psd1 files. Each file must contain a Hashtable with environment variable names as keys and strings as values. Wildcards are supported.

    .PARAMETER Scope
    Specifies Process, User, or Machine. The default value is Process.

    .EXAMPLE
    Set-WUEnvironmentVariable -Name 'MY_TOOL_HOME' -Value 'C:\Tools' -Scope User

    Sets MY_TOOL_HOME for the current user.

    .EXAMPLE
    Set-WUEnvironmentVariable -Path '.\environment.psd1' -Scope User

    Reads environment variables from environment.psd1 and sets them for the current user.

    .INPUTS
    System.String

    .OUTPUTS
    None
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
        [AllowEmptyString()]
        [string]$Value,

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
        [string]$Scope = 'Process'
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'ByName') {
            $targetDescription = "$Scope environment variable '$Name'"
            if ($PSCmdlet.ShouldProcess($targetDescription, 'Set environment variable')) {
                Set-WUEnvironmentVariableValue -Name $Name -Value $Value -Scope $Scope -Confirm:$false
            }
        }

        if ($PSCmdlet.ParameterSetName -eq 'ByFile') {
            foreach ($currentPath in $Path) {
                try {
                    $resolvedPaths = @(Resolve-Path -Path $currentPath -ErrorAction Stop)
                } catch {
                    $PSCmdlet.WriteError($_)
                    continue
                }

                foreach ($resolvedPath in $resolvedPaths) {
                    if ($resolvedPath.Provider.Name -ne 'FileSystem') {
                        $exception = [System.InvalidOperationException]::new(
                            "The environment file must use the FileSystem provider: $($resolvedPath.Path)"
                        )
                        $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                            $exception,
                            'EnvironmentFileProviderNotSupported',
                            [System.Management.Automation.ErrorCategory]::InvalidArgument,
                            $resolvedPath
                        )
                        $PSCmdlet.WriteError($errorRecord)
                        continue
                    }

                    if (-not (Test-Path -LiteralPath $resolvedPath.ProviderPath -PathType Leaf)) {
                        $exception = [System.IO.FileNotFoundException]::new(
                            "The environment file was not found: $($resolvedPath.ProviderPath)",
                            $resolvedPath.ProviderPath
                        )
                        $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                            $exception,
                            'EnvironmentFileNotFound',
                            [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                            $resolvedPath.ProviderPath
                        )
                        $PSCmdlet.WriteError($errorRecord)
                        continue
                    }

                    try {
                        $environmentVariables = Import-PowerShellDataFile -Path $resolvedPath.ProviderPath -ErrorAction Stop
                    } catch {
                        $PSCmdlet.WriteError($_)
                        continue
                    }

                    if ($environmentVariables -isnot [System.Collections.Hashtable]) {
                        $exception = [System.FormatException]::new(
                            "The environment data file root must be a Hashtable: $($resolvedPath.ProviderPath)"
                        )
                        $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                            $exception,
                            'InvalidEnvironmentDataFileRoot',
                            [System.Management.Automation.ErrorCategory]::InvalidData,
                            $resolvedPath.ProviderPath
                        )
                        $PSCmdlet.WriteError($errorRecord)
                        continue
                    }

                    $invalidData = $false
                    foreach ($environmentEntry in $environmentVariables.GetEnumerator()) {
                        if (
                            $environmentEntry.Key -isnot [string] -or
                            [string]::IsNullOrEmpty($environmentEntry.Key) -or
                            $environmentEntry.Key.IndexOf([char]'=') -ge 0 -or
                            $environmentEntry.Key.IndexOf([char]0) -ge 0 -or
                            $environmentEntry.Value -isnot [string]
                        ) {
                            $invalidData = $true
                            $exception = [System.FormatException]::new(
                                "Every environment data file key must be a valid environment variable name, and every value must be a string: $($resolvedPath.ProviderPath)"
                            )
                            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                                $exception,
                                'InvalidEnvironmentDataFileEntry',
                                [System.Management.Automation.ErrorCategory]::InvalidData,
                                $environmentEntry
                            )
                            $PSCmdlet.WriteError($errorRecord)
                        }
                    }

                    if ($invalidData) {
                        continue
                    }

                    foreach ($environmentEntry in $environmentVariables.GetEnumerator()) {
                        $environmentName = [string]$environmentEntry.Key
                        $environmentValue = [string]$environmentEntry.Value
                        $targetDescription = "$Scope environment variable '$environmentName'"
                        if ($PSCmdlet.ShouldProcess($targetDescription, 'Set environment variable')) {
                            Set-WUEnvironmentVariableValue -Name $environmentName -Value $environmentValue -Scope $Scope -Confirm:$false
                        }
                    }
                }
            }
        }
    }
}
