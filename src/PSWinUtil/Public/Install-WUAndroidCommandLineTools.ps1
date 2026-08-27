function Install-WUAndroidCommandLineTools {
    <#
    .SYNOPSIS
    Installs the current Android command-line tools package.

    .DESCRIPTION
    Gets the current official Windows package URL, downloads the package directly over HTTP, and installs it under cmdline-tools\latest in an existing Android SDK directory. Running this command automatically accepts the Android SDK license shown on the official Android Studio download page. The command validates the extracted package before replacing an existing installation. The downloaded archive and temporary extraction directory are removed after the operation.

    .PARAMETER AndroidHome
    Specifies an existing Android SDK directory. The default value is ANDROID_HOME.

    .PARAMETER DownloadDirectory
    Specifies the existing directory used for the temporary package download. The default value is the current user Downloads directory.

    .PARAMETER TimeoutSeconds
    Specifies the maximum number of seconds for the HTTP download. The default value is 300.

    .PARAMETER PassThru
    Returns the installed cmdline-tools\latest directory.

    .EXAMPLE
    Install-WUAndroidCommandLineTools

    Installs the current package under ANDROID_HOME.

    .EXAMPLE
    Install-WUAndroidCommandLineTools -AndroidHome 'C:\Android\Sdk' -DownloadDirectory 'C:\Downloads' -PassThru

    Installs the current package and returns the installation directory.

    .INPUTS
    None

    .OUTPUTS
    System.IO.DirectoryInfo
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseSingularNouns',
        '',
        Justification = 'Android command-line tools is the official package name used by this public command.'
    )]
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.IO.DirectoryInfo])]
    param(
        [Parameter()]
        [AllowEmptyString()]
        [string]$AndroidHome = $env:ANDROID_HOME,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$DownloadDirectory = "$env:USERPROFILE\Downloads",

        [Parameter()]
        [ValidateRange(1, 86400)]
        [int]$TimeoutSeconds = 300,

        [Parameter()]
        [switch]$PassThru
    )

    if ([string]::IsNullOrWhiteSpace($AndroidHome)) {
        throw 'AndroidHome is required. Specify it or set ANDROID_HOME.'
    }
    $fullAndroidHome = Resolve-WUPath `
        -LiteralPath $AndroidHome `
        -DenyMultiplePaths |
        ConvertTo-WUFullPath
    Assert-WUPathProperty -LiteralPath $fullAndroidHome -Container
    $fullDownloadDirectory = Resolve-WUPath `
        -LiteralPath $DownloadDirectory `
        -DenyMultiplePaths |
        ConvertTo-WUFullPath
    Assert-WUPathProperty -LiteralPath $fullDownloadDirectory -Container

    $commandLineToolsRoot = Join-Path -Path $fullAndroidHome -ChildPath 'cmdline-tools'
    $latestPath = Join-Path -Path $commandLineToolsRoot -ChildPath 'latest'
    if (-not $PSCmdlet.ShouldProcess($latestPath, 'Download and install Android command-line tools')) {
        return
    }

    $downloadedPath = $null
    $temporaryDirectory = $null
    $backupPath = $null
    try {
        $packageUrl = Get-WUAndroidCommandLineToolsUrl
        $packageUri = [uri]$packageUrl
        $packageFileName = [IO.Path]::GetFileName($packageUri.AbsolutePath)
        if ([string]::IsNullOrWhiteSpace($packageFileName)) {
            throw "The package file name could not be determined from URL: $packageUrl"
        }

        $downloadName = "PSWinUtil-$([guid]::NewGuid().ToString('N'))-$packageFileName"
        $downloadedPath = Join-Path -Path $fullDownloadDirectory -ChildPath $downloadName
        $downloadParameters = @{
            Uri = $packageUri
            Path = $downloadedPath
            TimeoutSeconds = $TimeoutSeconds
        }
        $downloadedPath = Invoke-WUHttpFileDownload @downloadParameters

        $temporaryName = "PSWinUtil-AndroidTools-$([guid]::NewGuid().ToString('N'))"
        $temporaryDirectory = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath $temporaryName
        $extractPath = Join-Path -Path $temporaryDirectory -ChildPath 'extracted'
        $null = New-Item -Path $extractPath -ItemType Directory -Force -ErrorAction Stop

        Add-Type -AssemblyName 'System.IO.Compression.FileSystem' -ErrorAction Stop
        [IO.Compression.ZipFile]::ExtractToDirectory($downloadedPath, $extractPath)

        $extractedToolsPath = Join-Path -Path $extractPath -ChildPath 'cmdline-tools'
        $sdkManagerPath = Join-Path -Path $extractedToolsPath -ChildPath 'bin\sdkmanager.bat'
        if (
            -not (Test-Path -LiteralPath $extractedToolsPath -PathType Container) -or
            -not (Test-Path -LiteralPath $sdkManagerPath -PathType Leaf)
        ) {
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

        if ($PassThru) {
            Get-Item -LiteralPath $latestPath -ErrorAction Stop
        }
    } finally {
        if (
            $null -ne $backupPath -and
            (Test-Path -LiteralPath $backupPath) -and
            -not (Test-Path -LiteralPath $latestPath)
        ) {
            Move-Item -LiteralPath $backupPath -Destination $latestPath -ErrorAction Stop
        }
        if ($null -ne $temporaryDirectory -and (Test-Path -LiteralPath $temporaryDirectory)) {
            Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force -ErrorAction Stop
        }
        if ($null -ne $downloadedPath -and (Test-Path -LiteralPath $downloadedPath -PathType Leaf)) {
            Remove-Item -LiteralPath $downloadedPath -Force -ErrorAction Stop
        }
    }
}
