function Assert-WUFlutterSdkInstallation {
    <#
    .SYNOPSIS
    Verifies the installed Flutter SDK and reports its diagnostic output.

    .DESCRIPTION
    Displays Flutter and Dart version reports and the Flutter doctor report. Throws when a version command fails. Flutter doctor output is informational because doctor reports environment issues through its exit code.

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
    $flutterVersion = Invoke-WUNativeCommand -Command 'flutter' -ArgumentList @('--version') -ErrorAction Ignore
    if (-not $flutterVersion.Succeeded) {
        throw "The Flutter SDK version command failed with exit code $($flutterVersion.ExitCode)."
    }

    $dartVersion = Invoke-WUNativeCommand -Command 'dart' -ArgumentList @('--version') -ErrorAction Ignore
    if (-not $dartVersion.Succeeded) {
        throw "The Dart SDK version command failed with exit code $($dartVersion.ExitCode)."
    }

    Invoke-WUNativeCommand -Command 'flutter' -ArgumentList @('doctor') -ErrorAction Ignore | Out-Null
}
