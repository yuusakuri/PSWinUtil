function Invoke-WUFlutterSdkCommand {
    <#
    .SYNOPSIS
    Runs a Flutter SDK command and displays its output.

    .DESCRIPTION
    Runs a command through PATH, writes its standard output and standard error to the information stream, and reports a command failure for a nonzero exit code unless IgnoreExitCode is specified.

    .PARAMETER Command
    Specifies the command name resolved through PATH.

    .PARAMETER ArgumentList
    Specifies the command arguments.

    .PARAMETER IgnoreExitCode
    Prevents a nonzero exit code from causing an error.

    .PARAMETER RespondToYesPrompt
    Sends y to the command's standard input when a y/N prompt is displayed.

    .EXAMPLE
    Invoke-WUFlutterSdkCommand -Command 'flutter' -ArgumentList '--version'

    Displays the Flutter SDK version and reports a nonzero exit code.

    .EXAMPLE
    Invoke-WUFlutterSdkCommand -Command 'flutter' -ArgumentList 'doctor' -IgnoreExitCode

    Displays the Flutter development environment report without using its exit code as a success condition.

    .INPUTS
    None

    .OUTPUTS
    None
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Command,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [string[]]$ArgumentList,

        [Parameter()]
        [switch]$IgnoreExitCode,

        [Parameter()]
        [switch]$RespondToYesPrompt
    )

    $application = Get-Command -Name $Command -CommandType Application -ErrorAction Stop |
        Select-Object -First 1
    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        if ($RespondToYesPrompt) {
            $startInfo = [Diagnostics.ProcessStartInfo]::new()
            $quotedArguments = @(
                foreach ($argument in $ArgumentList) {
                    $argumentText = [string]$argument
                    if ($argumentText -notmatch '[\s"]') {
                        $argumentText
                        continue
                    }
                    $escapedArgument = $argumentText -replace '(\\*)"', '$1$1\"'
                    $escapedArgument = $escapedArgument -replace '(\\+)$', '$1$1'
                    '"' + $escapedArgument + '"'
                }
            )
            if ([IO.Path]::GetExtension($application.Source) -in @('.bat', '.cmd')) {
                $startInfo.FileName = [Environment]::GetEnvironmentVariable('ComSpec')
                $commandLine = ('"' + $application.Source + '" ' + ($quotedArguments -join ' ')).Trim()
                $startInfo.Arguments = "/d /s /c `"$commandLine`""
            } else {
                $startInfo.FileName = $application.Source
                $startInfo.Arguments = $quotedArguments -join ' '
            }
            $startInfo.UseShellExecute = $false
            $startInfo.CreateNoWindow = $true
            $startInfo.RedirectStandardInput = $true
            $startInfo.RedirectStandardOutput = $true
            $startInfo.RedirectStandardError = $true
            $process = [Diagnostics.Process]::new()
            $process.StartInfo = $startInfo
            $processStarted = $false
            try {
                $processStarted = $process.Start()
                if (-not $processStarted) {
                    throw "Could not start the Flutter SDK command: $Command"
                }
                $standardErrorTask = $process.StandardError.ReadToEndAsync()
                $standardOutputBuilder = [Text.StringBuilder]::new()
                $promptBuffer = [Text.StringBuilder]::new()
                $promptPattern = '(?i)(\(y/n\)|\[y/n\])\??'
                while (($character = $process.StandardOutput.Read()) -ne -1) {
                    $character = [char]$character
                    [void]$standardOutputBuilder.Append($character)
                    [void]$promptBuffer.Append($character)
                    if ($promptBuffer.ToString() -match $promptPattern) {
                        try {
                            $process.StandardInput.WriteLine('y')
                            $process.StandardInput.Flush()
                        } catch [IO.IOException] {
                            break
                        } catch [ObjectDisposedException] {
                            break
                        }
                        $promptBuffer.Clear()
                    } elseif ($promptBuffer.Length -gt 128) {
                        $null = $promptBuffer.Remove(0, $promptBuffer.Length - 64)
                    }
                }
                $process.StandardInput.Close()
                $process.WaitForExit()
                $commandOutput = @()
                foreach ($outputText in @(
                        $standardOutputBuilder.ToString()
                        $standardErrorTask.GetAwaiter().GetResult()
                    )) {
                    if (-not [string]::IsNullOrEmpty($outputText)) {
                        $commandOutput += $outputText -split "`r?`n"
                    }
                }
                $exitCode = $process.ExitCode
            } finally {
                if ($processStarted -and -not $process.HasExited) {
                    $process.Kill()
                    $process.WaitForExit()
                }
                $process.Dispose()
            }
        } else {
            $commandOutput = @(& $application.Source @ArgumentList 2>&1)
            $exitCode = $LASTEXITCODE
        }
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    foreach ($outputItem in $commandOutput) {
        Write-Information -MessageData ([string]$outputItem) -InformationAction Continue
    }

    if ($exitCode -ne 0 -and -not $IgnoreExitCode) {
        $displayCommand = (@($Command) + $ArgumentList) -join ' '
        throw "The Flutter SDK command failed with exit code $exitCode`: $displayCommand"
    }
}
