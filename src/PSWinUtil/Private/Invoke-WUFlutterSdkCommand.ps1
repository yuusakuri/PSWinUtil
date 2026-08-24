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
        [switch]$IgnoreExitCode
    )

    $application = Get-Command `
        -Name $Command `
        -CommandType Application `
        -ErrorAction Stop |
        Select-Object -First 1
    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $commandOutput = @(& $application.Source @ArgumentList 2>&1)
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    foreach ($outputItem in $commandOutput) {
        Write-Information -MessageData ([string]$outputItem) -InformationAction Continue
    }

    if ($exitCode -ne 0 -and -not $IgnoreExitCode) {
        $displayCommand = @($Command) + $ArgumentList -join ' '
        throw "The Flutter SDK command failed with exit code $exitCode`: $displayCommand"
    }
}
