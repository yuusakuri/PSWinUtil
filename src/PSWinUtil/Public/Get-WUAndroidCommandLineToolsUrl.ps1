function Get-WUAndroidCommandLineToolsUrl {
    <#
    .SYNOPSIS
    Gets the current Android command-line tools URL for Windows.

    .DESCRIPTION
    Reads the official Android Studio download page, finds the current Windows command-line tools package name, and returns its Google repository URL.

    .EXAMPLE
    Get-WUAndroidCommandLineToolsUrl

    Returns the current Windows command-line tools ZIP URL.

    .INPUTS
    None

    .OUTPUTS
    System.String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $downloadPageUri = 'https://developer.android.com/studio'
    $repositoryUri = 'https://dl.google.com/android/repository'
    $progressPreference = 'SilentlyContinue'
    try {
        $response = Invoke-WebRequest -UseBasicParsing -Uri $downloadPageUri -ErrorAction Stop
    } catch {
        throw "Could not read the Android Studio download page. $($_.Exception.Message)"
    }

    $packageNames = @(
        [regex]::Matches(
            [string]$response.Content,
            'commandlinetools-win-\d+_latest\.zip',
            [Text.RegularExpressions.RegexOptions]::IgnoreCase
        ) |
            ForEach-Object { $_.Value } |
            Select-Object -Unique
    )
    if ($packageNames.Count -eq 0) {
        throw 'The Windows Android command-line tools package was not found on the download page.'
    }

    "$repositoryUri/$($packageNames[0])"
}
