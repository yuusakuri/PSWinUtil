function Invoke-WUAndroidCli {
    <#
    .SYNOPSIS
    Runs Android CLI for an Android SDK directory.

    .DESCRIPTION
    Runs android.exe with the selected SDK directory and metrics disabled. The command returns text output and raises an error containing that output when Android CLI exits with a nonzero code.

    .PARAMETER AndroidCliPath
    Specifies the android.exe file to run.

    .PARAMETER SdkPath
    Specifies the Android SDK directory passed through the global --sdk option.

    .PARAMETER ArgumentList
    Specifies arguments passed to Android CLI.

    .EXAMPLE
    Invoke-WUAndroidCli -AndroidCliPath 'C:\Tools\android.exe' -SdkPath 'C:\Android\Sdk' -ArgumentList 'sdk', 'list', 'platforms/android-*'

    Lists Android SDK Platform packages.

    .INPUTS
    None

    .OUTPUTS
    System.String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$AndroidCliPath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SdkPath,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]$ArgumentList
    )

    Assert-WUPathProperty -LiteralPath $AndroidCliPath -Leaf
    $arguments = @("--sdk=$SdkPath", '--no-metrics') + $ArgumentList
    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $commandOutput = @(& $AndroidCliPath @arguments 2>&1)
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    $textOutput = @($commandOutput | ForEach-Object { $_.ToString() })
    if ($exitCode -ne 0) {
        $message = $textOutput -join [Environment]::NewLine
        throw "android.exe failed with exit code $exitCode.$([Environment]::NewLine)$message"
    }

    $textOutput
}
