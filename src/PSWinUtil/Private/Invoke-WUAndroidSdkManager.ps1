function Invoke-WUAndroidSdkManager {
    <#
    .SYNOPSIS
    Runs Android SDK Manager and validates its exit code.

    .DESCRIPTION
    Runs a selected sdkmanager.bat file with the supplied arguments and returns its text output. A nonzero exit code raises an error that includes the command output.

    .PARAMETER SdkManagerPath
    Specifies the sdkmanager.bat file to run.

    .PARAMETER ArgumentList
    Specifies arguments passed to SDK Manager.

    .EXAMPLE
    Invoke-WUAndroidSdkManager -SdkManagerPath 'C:\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat' -ArgumentList '--list'

    Lists Android SDK packages.

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
        [string]$SdkManagerPath,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]$ArgumentList
    )

    Assert-WUPathProperty -LiteralPath $SdkManagerPath -Leaf
    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $commandOutput = @(& $SdkManagerPath @ArgumentList 2>&1)
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    $textOutput = @($commandOutput | ForEach-Object { $_.ToString() })
    if ($exitCode -ne 0) {
        $message = $textOutput -join [Environment]::NewLine
        throw "sdkmanager.bat failed with exit code $exitCode.$([Environment]::NewLine)$message"
    }

    $textOutput
}
