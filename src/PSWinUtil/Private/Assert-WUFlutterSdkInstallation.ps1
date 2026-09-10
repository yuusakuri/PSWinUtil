function Assert-WUFlutterSdkInstallation {
    <#
    .SYNOPSIS
    Verifies the installed Flutter SDK and reports its diagnostic output.

    .DESCRIPTION
    Runs the installed Flutter and Dart commands directly, writes their output to the information stream, and throws when a version command fails. Flutter doctor output is informational because doctor reports environment issues through its exit code.

    .EXAMPLE
    Assert-WUFlutterSdkInstallation

    Verifies Flutter and Dart and displays the Flutter doctor report.

    .INPUTS
    None

    .OUTPUTS
    None
    #>
    [CmdletBinding()]
    param()

    Assert-WUCommand -Name 'flutter'
    Assert-WUCommand -Name 'dart'
    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'

        $flutterVersionOutput = @(& flutter --version 2>&1)
        $flutterVersionExitCode = $LASTEXITCODE
        foreach ($outputItem in $flutterVersionOutput) {
            Write-Information -MessageData ([string]$outputItem) -InformationAction Continue
        }
        if ($flutterVersionExitCode -ne 0) {
            throw "The Flutter SDK version command failed with exit code $flutterVersionExitCode."
        }

        $dartVersionOutput = @(& dart --version 2>&1)
        $dartVersionExitCode = $LASTEXITCODE
        foreach ($outputItem in $dartVersionOutput) {
            Write-Information -MessageData ([string]$outputItem) -InformationAction Continue
        }
        if ($dartVersionExitCode -ne 0) {
            throw "The Dart SDK version command failed with exit code $dartVersionExitCode."
        }

        $flutterDoctorOutput = @(& flutter doctor 2>&1)
        foreach ($outputItem in $flutterDoctorOutput) {
            Write-Information -MessageData ([string]$outputItem) -InformationAction Continue
        }
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
}
