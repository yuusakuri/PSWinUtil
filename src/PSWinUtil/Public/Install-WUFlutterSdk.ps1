function Install-WUFlutterSdk {
    <#
    .SYNOPSIS
    Installs the Flutter SDK on Windows.

    .DESCRIPTION
    Downloads and verifies an official Windows Flutter SDK archive, validates its contents, installs it under the destination directory, and adds flutter\bin to the current user and process PATH values. An existing Flutter installation is kept until the new archive has been verified and is restored if installation fails. Temporary files are removed after the operation.

    .PARAMETER Version
    Specifies the Flutter SDK version. An omitted or empty value selects the current release for the requested channel.

    .PARAMETER Channel
    Specifies the stable or beta release channel. The default value is stable.

    .PARAMETER Architecture
    Specifies the x64 or arm64 SDK architecture. The default value is detected from the current Windows environment.

    .PARAMETER DestinationPath
    Specifies the directory that contains the installed flutter directory. The default value is USERPROFILE\develop.

    .PARAMETER TimeoutSeconds
    Specifies the maximum number of seconds for the HTTP download. The default value is 900.

    .EXAMPLE
    Install-WUFlutterSdk

    Installs the current stable Flutter SDK under USERPROFILE\develop\flutter.

    .EXAMPLE
    Install-WUFlutterSdk -Version '3.47.1' -DestinationPath 'C:\Development'

    Installs Flutter SDK 3.47.1 under C:\Development\flutter and returns that directory.

    .INPUTS
    System.String

    .OUTPUTS
    System.IO.DirectoryInfo
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.IO.DirectoryInfo])]
    param(
        [Parameter(
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [AllowEmptyString()]
        [string]$Version,

        [Parameter()]
        [ValidateSet('stable', 'beta')]
        [string]$Channel = 'stable',

        [Parameter()]
        [ValidateSet('x64', 'arm64')]
        [string]$Architecture = $(
            if (
                $env:PROCESSOR_ARCHITECTURE -eq 'ARM64' -or
                $env:PROCESSOR_ARCHITEW6432 -eq 'ARM64'
            ) {
                'arm64'
            } else {
                'x64'
            }
        ),

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$DestinationPath = (Join-Path -Path $env:USERPROFILE -ChildPath 'develop'),

        [Parameter()]
        [ValidateRange(1, 86400)]
        [int]$TimeoutSeconds = 900
    )

    process {
        $fullDestinationPath = ConvertTo-WUFullPath -Path $DestinationPath
        if (
            (Test-Path -LiteralPath $fullDestinationPath) -and
            -not (Test-Path -LiteralPath $fullDestinationPath -PathType Container)
        ) {
            throw "The destination path is not a directory: $fullDestinationPath"
        }

        $flutterPath = Join-Path -Path $fullDestinationPath -ChildPath 'flutter'
        $versionDescription = $Version
        if ([string]::IsNullOrWhiteSpace($versionDescription)) {
            $versionDescription = "current $Channel"
        }
        $actionDescription = "Install Flutter SDK $versionDescription for $Architecture"
        if (-not $PSCmdlet.ShouldProcess($flutterPath, $actionDescription)) {
            return
        }

        if (
            (Test-Path -LiteralPath $flutterPath) -and
            -not (Test-Path -LiteralPath $flutterPath -PathType Container)
        ) {
            throw "The Flutter installation path is not a directory: $flutterPath"
        }

        $releaseParameters = @{
            Version = $Version
            Channel = $Channel
            Architecture = $Architecture
        }
        $release = Get-WUFlutterSdkRelease @releaseParameters

        $temporaryDirectory = Join-Path `
            -Path ([IO.Path]::GetTempPath()) `
            -ChildPath "PSWinUtil-Flutter-$([guid]::NewGuid().ToString('N'))"
        $downloadedPath = $null
        $stagingDirectory = $null
        $backupPath = $null
        $destinationCreated = $false
        $newInstallationMoved = $false
        $environmentUpdateStarted = $false
        $originalUserPath = $null
        $originalProcessPath = $null
        try {
            $null = New-Item -Path $temporaryDirectory -ItemType Directory -Force -ErrorAction Stop
            $packageFileName = [IO.Path]::GetFileName($release.Uri.AbsolutePath)
            if ([string]::IsNullOrWhiteSpace($packageFileName)) {
                throw "The package file name could not be determined from URL: $($release.Uri)"
            }

            $downloadedPath = Join-Path -Path $temporaryDirectory -ChildPath $packageFileName
            $downloadParameters = @{
                Uri = $release.Uri
                Path = $downloadedPath
                TimeoutSeconds = $TimeoutSeconds
            }
            $downloadedPath = Invoke-WUHttpFileDownload @downloadParameters

            $actualHash = (Get-FileHash -LiteralPath $downloadedPath -Algorithm SHA256).Hash
            if ($actualHash -ine $release.Sha256) {
                throw 'The downloaded Flutter SDK archive does not match the official SHA-256 hash.'
            }

            if (-not (Test-Path -LiteralPath $fullDestinationPath -PathType Container)) {
                $null = New-Item `
                    -Path $fullDestinationPath `
                    -ItemType Directory `
                    -Force `
                    -ErrorAction Stop
                $destinationCreated = $true
            }

            $stagingDirectory = Join-Path `
                -Path $fullDestinationPath `
                -ChildPath ".flutter-install-$([guid]::NewGuid().ToString('N'))"
            $null = New-Item -Path $stagingDirectory -ItemType Directory -ErrorAction Stop

            Add-Type -AssemblyName 'System.IO.Compression.FileSystem' -ErrorAction Stop
            $archive = [IO.Compression.ZipFile]::OpenRead($downloadedPath)
            try {
                $stagingFullPath = [IO.Path]::GetFullPath($stagingDirectory)
                $stagingPrefix = $stagingFullPath.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
                foreach ($entry in $archive.Entries) {
                    $entryPath = $entry.FullName.Replace(
                        [IO.Path]::AltDirectorySeparatorChar,
                        [IO.Path]::DirectorySeparatorChar
                    )
                    $entryFullPath = [IO.Path]::GetFullPath(
                        [IO.Path]::Combine($stagingFullPath, $entryPath)
                    )
                    if (-not $entryFullPath.StartsWith(
                            $stagingPrefix,
                            [StringComparison]::OrdinalIgnoreCase
                        )) {
                        throw "The Flutter SDK archive contains an unsafe path: $($entry.FullName)"
                    }
                }
            } finally {
                $archive.Dispose()
            }

            [IO.Compression.ZipFile]::ExtractToDirectory($downloadedPath, $stagingDirectory)
            $stagedFlutterPath = Join-Path -Path $stagingDirectory -ChildPath 'flutter'
            $flutterCommandPath = Join-Path -Path $stagedFlutterPath -ChildPath 'bin\flutter.bat'
            if (
                -not (Test-Path -LiteralPath $stagedFlutterPath -PathType Container) -or
                -not (Test-Path -LiteralPath $flutterCommandPath -PathType Leaf)
            ) {
                throw 'The downloaded package does not contain the expected flutter\bin\flutter.bat file.'
            }

            if (Test-Path -LiteralPath $flutterPath -PathType Container) {
                $backupPath = Join-Path `
                    -Path $fullDestinationPath `
                    -ChildPath ".flutter-backup-$([guid]::NewGuid().ToString('N'))"
                Move-Item -LiteralPath $flutterPath -Destination $backupPath -ErrorAction Stop
            }

            Move-Item -LiteralPath $stagedFlutterPath -Destination $flutterPath -ErrorAction Stop
            $newInstallationMoved = $true

            $flutterBinPath = Join-Path -Path $flutterPath -ChildPath 'bin'
            $originalUserPath = [Environment]::GetEnvironmentVariable(
                'Path',
                [EnvironmentVariableTarget]::User
            )
            $originalProcessPath = [Environment]::GetEnvironmentVariable(
                'Path',
                [EnvironmentVariableTarget]::Process
            )
            $environmentUpdateStarted = $true
            Add-WUPathEnvironmentVariable `
                -Path $flutterBinPath `
                -Scope 'User' `
                -Prepend `
                -Confirm:$false
            Add-WUPathEnvironmentVariable `
                -Path $flutterBinPath `
                -Scope 'Process' `
                -Prepend `
                -Confirm:$false

            if ($null -ne $backupPath -and (Test-Path -LiteralPath $backupPath)) {
                Remove-Item -LiteralPath $backupPath -Recurse -Force -ErrorAction Stop
                $backupPath = $null
            }

            Get-Item -LiteralPath $flutterPath -ErrorAction Stop
        } catch {
            $operationError = $_
            if ($environmentUpdateStarted) {
                try {
                    [Environment]::SetEnvironmentVariable(
                        'Path',
                        $originalUserPath,
                        [EnvironmentVariableTarget]::User
                    )
                    [Environment]::SetEnvironmentVariable(
                        'Path',
                        $originalProcessPath,
                        [EnvironmentVariableTarget]::Process
                    )
                } catch {
                    $null = $_
                }
            }
            if ($newInstallationMoved -and (Test-Path -LiteralPath $flutterPath)) {
                Remove-Item `
                    -LiteralPath $flutterPath `
                    -Recurse `
                    -Force `
                    -ErrorAction SilentlyContinue
            }
            if ($null -ne $backupPath -and (Test-Path -LiteralPath $backupPath)) {
                Move-Item `
                    -LiteralPath $backupPath `
                    -Destination $flutterPath `
                    -ErrorAction SilentlyContinue
            }
            throw $operationError
        } finally {
            if ($null -ne $stagingDirectory -and (Test-Path -LiteralPath $stagingDirectory)) {
                Remove-Item `
                    -LiteralPath $stagingDirectory `
                    -Recurse `
                    -Force `
                    -ErrorAction SilentlyContinue
            }
            if (Test-Path -LiteralPath $temporaryDirectory) {
                Remove-Item `
                    -LiteralPath $temporaryDirectory `
                    -Recurse `
                    -Force `
                    -ErrorAction SilentlyContinue
            }
            if (
                $destinationCreated -and
                (Test-Path -LiteralPath $fullDestinationPath -PathType Container) -and
                @(Get-ChildItem -LiteralPath $fullDestinationPath -Force).Count -eq 0
            ) {
                Remove-Item `
                    -LiteralPath $fullDestinationPath `
                    -Force `
                    -ErrorAction SilentlyContinue
            }
        }
    }
}
