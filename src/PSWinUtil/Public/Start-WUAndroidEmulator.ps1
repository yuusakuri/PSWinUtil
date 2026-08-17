function Start-WUAndroidEmulator {
    <#
    .SYNOPSIS
    Starts an Android virtual device.

    .DESCRIPTION
    Finds emulator.exe on PATH, gets the available Android virtual device names, and starts the selected device in a background process. When Name is omitted, the first available device is selected.

    .PARAMETER Name
    Specifies an Android virtual device name returned by emulator.exe. When omitted, the first available name is used.

    .EXAMPLE
    Start-WUAndroidEmulator -Name 'Pixel_API_35'

    Starts the Android virtual device named Pixel_API_35.

    .EXAMPLE
    Start-WUAndroidEmulator

    Starts the first available Android virtual device.

    .INPUTS
    None

    .OUTPUTS
    System.Diagnostics.Process
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.Diagnostics.Process])]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    $emulator = Get-Command -Name 'emulator.exe' -CommandType Application -ErrorAction Ignore |
        Select-Object -First 1
    if ($null -eq $emulator) {
        throw 'Android emulator.exe was not found on PATH.'
    }

    $commandOutput = @(& $emulator.Source '-list-avds' 2>&1)
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        $message = @($commandOutput | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine
        throw "emulator.exe -list-avds failed with exit code $exitCode.$([Environment]::NewLine)$message"
    }

    $avdNames = @(
        $commandOutput |
            ForEach-Object { $_.ToString().Trim() } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )
    if ($avdNames.Count -eq 0) {
        throw 'No Android virtual device is available.'
    }

    $selectedName = $avdNames[0]
    if ($PSBoundParameters.ContainsKey('Name')) {
        $matchingNames = @($avdNames | Where-Object { $_ -eq $Name })
        if ($matchingNames.Count -eq 0) {
            throw "The Android virtual device was not found: $Name"
        }
        $selectedName = $matchingNames[0]
    }

    $target = "Android virtual device '$selectedName'"
    if (-not $PSCmdlet.ShouldProcess($target, 'Start Android emulator')) {
        return
    }

    Start-Process -FilePath $emulator.Source -ArgumentList "@$selectedName" -PassThru -ErrorAction Stop
}
