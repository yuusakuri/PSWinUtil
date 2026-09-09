function Invoke-WUAndroidSdkTool {
    <#
    .SYNOPSIS
    Runs an Android SDK tool and checks its exit status.

    .DESCRIPTION
    Captures diagnostic output even when Windows PowerShell treats native stderr as errors. Answers no to interactive prompts; SDK licenses must already be accepted.

    .PARAMETER FilePath
    Specifies the resolved native command path.

    .PARAMETER ArgumentList
    Specifies the command arguments.

    .EXAMPLE
    Invoke-WUAndroidSdkTool -FilePath 'C:\Android\Sdk\cmdline-tools\latest\bin\avdmanager.bat' -ArgumentList 'list', 'device', '-c'

    Returns available device identifiers.

    .OUTPUTS
    System.String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string[]]$ArgumentList

        ,
        [Parameter()]
        [switch]$AllowAndroidCliWindowsExitCode
    )

    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = @('no' | & $FilePath @ArgumentList 2>&1)
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    $lines = @($output | ForEach-Object { $_.ToString() })
    if ($exitCode -ne 0 -and -not ($AllowAndroidCliWindowsExitCode -and $FilePath -eq 'android.exe' -and $exitCode -eq -1073740791)) {
        throw "Android SDK tool failed with exit code ${exitCode}: $FilePath$([Environment]::NewLine)$($lines -join [Environment]::NewLine)"
    }
    $lines
}
