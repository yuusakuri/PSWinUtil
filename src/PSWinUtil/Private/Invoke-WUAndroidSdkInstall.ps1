function Invoke-WUAndroidSdkInstall {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Package,

        [Parameter()]
        [switch]$Force
    )

    $arguments = @('--no-metrics', 'sdk', 'install', $Package)
    if ($Force) {
        $arguments += '--force'
    }

    $savedErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = @(& android.exe @arguments 2>&1)
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $savedErrorActionPreference
    }

    $textOutput = @($output | ForEach-Object { $_.ToString() })
    if ($exitCode -ne 0 -and $exitCode -ne -1073740791) {
        throw "android.exe failed with exit code $exitCode.$([Environment]::NewLine)$($textOutput -join [Environment]::NewLine)"
    }
}
