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
    Invoke-WUNativeCommand -Command 'flutter' -ArgumentList @('--version') -ErrorAction Stop | Out-Null

    Invoke-WUNativeCommand -Command 'dart' -ArgumentList @('--version') -ErrorAction Stop | Out-Null

    Invoke-WUNativeCommand -Command 'flutter' -ArgumentList @('doctor') -ErrorAction Ignore | Out-Null
}
