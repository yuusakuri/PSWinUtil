function Install-WUAndroidCommandLineTools {
    <#
    .SYNOPSIS
    Installs Android SDK Command-Line Tools when missing.

    .DESCRIPTION
    Installs the current official Windows Command-Line Tools package under cmdline-tools\latest when sdkmanager.bat is missing. The SDK directory is created when necessary. Running this command automatically accepts the Android SDK license shown on the official Android Studio download page. The downloaded archive and extraction directory are removed after the operation.

    .PARAMETER SdkPath
    Specifies the Android SDK directory. The default value is LOCALAPPDATA\Android\Sdk.

    .EXAMPLE
    Install-WUAndroidCommandLineTools

    Installs Command-Line Tools in the default Android SDK directory when missing.

    .EXAMPLE
    Install-WUAndroidCommandLineTools -SdkPath 'D:\Android\Sdk'

    Installs Command-Line Tools in D:\Android\Sdk when missing.

    .INPUTS
    None

    .OUTPUTS
    None
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseSingularNouns',
        '',
        Justification = 'Android Command-Line Tools is the official package name used by this public command.'
    )]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter()]
        [AllowEmptyString()]
        [string]$SdkPath = $(
            if ([string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
                ''
            } else {
                Join-Path -Path $env:LOCALAPPDATA -ChildPath 'Android\Sdk'
            }
        )
    )

    if ([string]::IsNullOrWhiteSpace($SdkPath)) {
        throw 'SdkPath is required. Specify it or set LOCALAPPDATA.'
    }
    $fullSdkPath = ConvertTo-WUFullPath -Path $SdkPath
    Assert-WUPathProperty -LiteralPath $fullSdkPath -Container -AllowNonExisting
    $commandLineToolsRoot = Join-Path -Path $fullSdkPath -ChildPath 'cmdline-tools'
    $latestPath = Join-Path -Path $commandLineToolsRoot -ChildPath 'latest'
    $sdkManagerPath = Join-Path -Path $latestPath -ChildPath 'bin\sdkmanager.bat'
    if (Test-Path -LiteralPath $sdkManagerPath -PathType Leaf) {
        return
    }
    if (-not $PSCmdlet.ShouldProcess($latestPath, 'Install Android SDK Command-Line Tools')) {
        return
    }

    $temporaryDirectory = Join-Path `
        -Path ([System.IO.Path]::GetTempPath()) `
        -ChildPath "PSWinUtil-AndroidTools-$([guid]::NewGuid().ToString('N'))"
    $backupPath = $null
    $sdkDirectoryCreated = $false
    try {
        if (-not (Test-Path -LiteralPath $fullSdkPath -PathType Container)) {
            $null = New-Item -Path $fullSdkPath -ItemType Directory -Force -ErrorAction Stop
            $sdkDirectoryCreated = $true
        }
        $null = New-Item -Path $temporaryDirectory -ItemType Directory -Force -ErrorAction Stop

        $package = Get-WUAndroidCommandLineToolsPackage
        $downloadedPath = Join-Path -Path $temporaryDirectory -ChildPath $package.FileName
        $downloadedPath = Invoke-WUHttpFileDownload `
            -Uri $package.Uri `
            -Path $downloadedPath `
            -Confirm:$false
        $downloadHash = (Get-FileHash -LiteralPath $downloadedPath -Algorithm SHA256).Hash
        if ($downloadHash -ne $package.Sha256) {
            throw "The Android Command-Line Tools package checksum is invalid: $downloadedPath"
        }
        $extractPath = Join-Path -Path $temporaryDirectory -ChildPath 'extracted'
        $null = New-Item -Path $extractPath -ItemType Directory -Force -ErrorAction Stop

        Add-Type -AssemblyName 'System.IO.Compression.FileSystem' -ErrorAction Stop
        $archive = [System.IO.Compression.ZipFile]::OpenRead($downloadedPath)
        try {
            $extractFullPath = [System.IO.Path]::GetFullPath($extractPath)
            $extractPrefix = $extractFullPath.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
            foreach ($entry in $archive.Entries) {
                $entryPath = $entry.FullName.Replace(
                    [System.IO.Path]::AltDirectorySeparatorChar,
                    [System.IO.Path]::DirectorySeparatorChar
                )
                $entryFullPath = [System.IO.Path]::GetFullPath(
                    [System.IO.Path]::Combine($extractFullPath, $entryPath)
                )
                if (-not $entryFullPath.StartsWith(
                        $extractPrefix,
                        [System.StringComparison]::OrdinalIgnoreCase
                    )) {
                    throw "The Android Command-Line Tools archive contains an unsafe path: $($entry.FullName)"
                }
            }
        } finally {
            $archive.Dispose()
        }
        [System.IO.Compression.ZipFile]::ExtractToDirectory($downloadedPath, $extractPath)

        $extractedToolsPath = Join-Path -Path $extractPath -ChildPath 'cmdline-tools'
        $extractedSdkManagerPath = Join-Path `
            -Path $extractedToolsPath `
            -ChildPath 'bin\sdkmanager.bat'
        if (-not (Test-Path -LiteralPath $extractedSdkManagerPath -PathType Leaf)) {
            throw 'The downloaded package does not contain the expected cmdline-tools directory.'
        }

        if (-not (Test-Path -LiteralPath $commandLineToolsRoot -PathType Container)) {
            $null = New-Item -Path $commandLineToolsRoot -ItemType Directory -Force -ErrorAction Stop
        }
        if (Test-Path -LiteralPath $latestPath) {
            $backupName = ".latest-backup-$([guid]::NewGuid().ToString('N'))"
            $backupPath = Join-Path -Path $commandLineToolsRoot -ChildPath $backupName
            Move-Item -LiteralPath $latestPath -Destination $backupPath -ErrorAction Stop
        }

        try {
            Move-Item -LiteralPath $extractedToolsPath -Destination $latestPath -ErrorAction Stop
        } catch {
            if (
                $null -ne $backupPath -and
                (Test-Path -LiteralPath $backupPath) -and
                -not (Test-Path -LiteralPath $latestPath)
            ) {
                Move-Item -LiteralPath $backupPath -Destination $latestPath -ErrorAction Stop
                $backupPath = $null
            }
            throw
        }

        if ($null -ne $backupPath -and (Test-Path -LiteralPath $backupPath)) {
            Remove-Item -LiteralPath $backupPath -Recurse -Force -ErrorAction Stop
            $backupPath = $null
        }
    } finally {
        if (
            $null -ne $backupPath -and
            (Test-Path -LiteralPath $backupPath) -and
            -not (Test-Path -LiteralPath $latestPath)
        ) {
            Move-Item -LiteralPath $backupPath -Destination $latestPath -ErrorAction Stop
        }
        if (Test-Path -LiteralPath $temporaryDirectory) {
            Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force -ErrorAction SilentlyContinue
        }
        if (
            $sdkDirectoryCreated -and
            (Test-Path -LiteralPath $fullSdkPath -PathType Container) -and
            @(Get-ChildItem -LiteralPath $fullSdkPath -Force).Count -eq 0
        ) {
            Remove-Item -LiteralPath $fullSdkPath -Force -ErrorAction SilentlyContinue
        }
    }
}
