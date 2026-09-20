function Invoke-WUExternalCommand {
    <#
    .SYNOPSIS
    Runs an external command and returns its exit status.

    .DESCRIPTION
    Runs an executable or Windows batch command with separate argument values. Batch commands run through cmd.exe and reject values that cmd.exe cannot reliably preserve. Output appears in the console by default; CaptureOutput instead returns standard output and standard error in the result. A failed exit writes an error according to the caller's ErrorAction setting and still returns the result unless error handling stops execution. ContinueExitCodes marks additional exit codes as successful.

    .PARAMETER Command
    Specifies the external command name or path.

    .PARAMETER ArgumentList
    Specifies the values passed as individual arguments.

    .PARAMETER CaptureOutput
    Returns standard output and standard error as result properties instead of displaying them.

    .PARAMETER ContinueExitCodes
    Specifies additional exit codes treated as successful.

    .PARAMETER ErrorCommandLine
    Specifies a display-only command line for failure errors. Omit secrets before providing it. By default, the error contains only the command name, not its arguments.

    .EXAMPLE
    Invoke-WUExternalCommand -Command 'git' -ArgumentList @('status', '--short') -CaptureOutput

    Returns Git output and its exit status.

    .EXAMPLE
    Invoke-WUExternalCommand -Command 'npm.cmd' -ArgumentList @('install')

    Runs npm.cmd and returns its exit status.

    .OUTPUTS
    PSWinUtil.ExternalCommandResult
    #>
    [CmdletBinding()]
    [OutputType([PSWinUtil.ExternalCommandResult])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Command,

        [Parameter(Position = 1)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]]$ArgumentList = @(),

        [Parameter()]
        [switch]$CaptureOutput,

        [Parameter()]
        [int[]]$ContinueExitCodes = @(),

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$ErrorCommandLine
    )

    $commandInfo = $ExecutionContext.InvokeCommand.GetCommand(
        $Command,
        [System.Management.Automation.CommandTypes]::Application
    )
    if ($null -eq $commandInfo) {
        throw "Command '$Command' is not available."
    }
    $commandPath = $commandInfo.Path
    $process = [System.Diagnostics.Process]::new()
    try {
        $process.StartInfo.UseShellExecute = $false
        if ([System.IO.Path]::GetExtension($commandPath) -in '.cmd', '.bat') {
            $process.StartInfo.FileName = 'cmd.exe'
            $process.StartInfo.Arguments = New-WUCmdArgument -CommandPath $commandPath -ArgumentList $ArgumentList
        } else {
            $process.StartInfo.FileName = $commandPath
            $quotedArguments = @(
                foreach ($argument in $ArgumentList) {
                    ConvertTo-WUCommandLineArgument -Argument $argument
                }
            )
            $process.StartInfo.Arguments = $quotedArguments -join ' '
        }

        $process.StartInfo.RedirectStandardOutput = [bool]$CaptureOutput
        $process.StartInfo.RedirectStandardError = [bool]$CaptureOutput
        [void]$process.Start()
        if ($CaptureOutput) {
            $standardOutputTask = $process.StandardOutput.ReadToEndAsync()
            $standardErrorTask = $process.StandardError.ReadToEndAsync()
        }
        $process.WaitForExit()

        $standardOutput = $null
        $standardError = $null
        if ($CaptureOutput) {
            $standardOutput = $standardOutputTask.GetAwaiter().GetResult()
            $standardError = $standardErrorTask.GetAwaiter().GetResult()
        }

        $exitCode = $process.ExitCode
        $result = [PSWinUtil.ExternalCommandResult]::new(
            ($exitCode -eq 0 -or $ContinueExitCodes -contains $exitCode),
            $exitCode,
            $standardOutput,
            $standardError
        )
        if (-not $result.Succeeded) {
            $displayCommand = if ($PSBoundParameters.ContainsKey('ErrorCommandLine')) {
                $ErrorCommandLine
            } else {
                $Command
            }
            $diagnostic = [ordered]@{
                command = $displayCommand
                exit_code = $result.ExitCode
                message = $result.Message()
            } | ConvertTo-Json -Compress
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.InvalidOperationException]::new("Command failed: $diagnostic"),
                'ExternalCommandFailed',
                [System.Management.Automation.ErrorCategory]::NotSpecified,
                $result
            )
            $PSCmdlet.WriteError($errorRecord)
        }
        $result
    } finally {
        $process.Dispose()
    }
}
