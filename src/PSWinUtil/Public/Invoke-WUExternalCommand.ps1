function Invoke-WUExternalCommand {
    <#
    .SYNOPSIS
    Runs an external command and returns its exit status.

    .DESCRIPTION
    Runs an executable or Windows batch command with separate argument values. Batch commands run through cmd.exe and reject values that cmd.exe cannot reliably preserve. Output appears in the console by default; CaptureOutput instead returns standard output and standard error in the result. ContinueExitCodes marks additional exit codes as successful.

    .PARAMETER Command
    Specifies the external command name or path.

    .PARAMETER ArgumentList
    Specifies the values passed as individual arguments.

    .PARAMETER CaptureOutput
    Returns standard output and standard error as result properties instead of displaying them.

    .PARAMETER ContinueExitCodes
    Specifies additional exit codes treated as successful.

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
        [int[]]$ContinueExitCodes = @()
    )

    $commandInfo = Get-Command -Name $Command -CommandType Application -ErrorAction Stop
    $commandPath = $commandInfo.Path
    $process = [System.Diagnostics.Process]::new()
    try {
        $process.StartInfo.UseShellExecute = $false
        if ([System.IO.Path]::GetExtension($commandPath) -in '.cmd', '.bat') {
            $process.StartInfo.FileName = Join-Path -Path ([Environment]::SystemDirectory) -ChildPath 'cmd.exe'
            $process.StartInfo.Arguments = New-WUCmdArgument -CommandPath $commandPath -ArgumentList $ArgumentList
        } else {
            $process.StartInfo.FileName = $commandPath
            $process.StartInfo.Arguments = (@($ArgumentList | ConvertTo-WUProcessArgument) -join ' ')
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
        [PSWinUtil.ExternalCommandResult]::new(
            ($exitCode -eq 0 -or $ContinueExitCodes -contains $exitCode),
            $exitCode,
            $standardOutput,
            $standardError
        )
    } finally {
        $process.Dispose()
    }
}
