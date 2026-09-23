function Get-WUAndroidSdkPackageVersion {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Platform', 'BuildTools')]
        [string]$Component,

        [Parameter()]
        [switch]$Latest
    )

    $packagePattern = switch ($Component) {
        'Platform' { 'platforms/android-*' }
        'BuildTools' { 'build-tools/*' }
    }
    $versionPattern = switch ($Component) {
        'Platform' { '(?m)^\s*platforms/android-(\d+)\s+' }
        'BuildTools' { '(?m)^\s*build-tools/([0-9]+\.[0-9]+\.[0-9]+)\s+' }
    }
    $result = Invoke-WUNativeCommand `
        -Command 'android.exe' `
        -ArgumentList @(
        '--no-metrics'
        'sdk'
        'list'
        $packagePattern
        '--all'
        '--all-versions'
    ) `
        -CaptureOutput `
        -ContinueExitCodes @(-1073740791) `
        -ErrorAction Stop

    $text = @($result.StandardOutput | Split-WUNewLine) -join "`n"
    $versions = @(
        [regex]::Matches($text, $versionPattern) |
            ForEach-Object {
                if ($Component -eq 'Platform') {
                    [int]$_.Groups[1].Value
                } else {
                    [version]$_.Groups[1].Value
                }
            } |
            Sort-Object -Descending -Unique
    )
    if ($versions.Count -eq 0) {
        throw "No stable Android SDK $Component package was found."
    }

    if ($Latest) {
        [string]$versions[0]
        return
    }

    foreach ($version in $versions) {
        [string]$version
    }
}
