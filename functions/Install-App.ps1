﻿function Install-WUApp {
    [CmdletBinding()]
    param (
        [string[]]
        $ScoopApp,

        [hashtable]
        $ScoopBucket,

        [string[]]
        $ChocolateyPackage,

        [string[]]
        $PSModule,

        [string[]]
        $PipPackage,

        [string[]]
        $NpmPackage,

        [string[]]
        $NuGetPackage,

        [string]
        $Destination,

        # Only available for `NuGetPackage` installation
        [string]
        $RequiredVersion,

        [switch]
        $Unsafe,

        [switch]
        $Force,

        [ValidateSet('All', 'Scoop', 'Chocolatey', 'PSModule', 'pip', 'npm', 'NuGet')]
        [string[]]
        $Optimize
    )

    function Test-WUAdmin {
        (
            [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::
            GetCurrent()
        ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    $shouldOptimize = {
        param (
            [Parameter(Mandatory)]
            [ValidateNotNullOrEmpty()]
            [string]
            $Provider
        )

        return $Provider -in $Optimize `
            -or 'All' -in $Optimize
    }

    function Optimize-PackageManagement {
        [CmdletBinding(SupportsShouldProcess)]
        param (
        )

        # Install package provider 'NuGet'.
        if (!(Get-PackageProvider | Where-Object Name -EQ 'NuGet')) {
            Install-PackageProvider -Name 'NuGet' -Force -Scope CurrentUser
        }

        # Update PowerShellGet Module
        if (@(Get-Module 'PowerShellGet' -ListAvailable).Count -eq 1) {
            Install-Module -Name PowerShellGet -Force -AllowClobber -Scope CurrentUser -WarningAction Ignore
            Update-Module -Name PowerShellGet
        }

        # Set 'PSGallery' and 'NuGet' to trusted
        Get-PackageSource | `
            Where-Object ProviderName -Match 'PowerShellGet|NuGet' | `
            Where-Object IsTrusted -EQ $false | `
            ForEach-Object {
            $_ | Set-PackageSource -Trusted
        } | Out-String | Write-Verbose

        # for issue: https://github.com/PowerShell/PowerShellGetv2/issues/606
        "$env:LOCALAPPDATA\Microsoft\Windows\PowerShell\PowerShellGet\NuGet.exe" |
        Where-Object { !(Test-Path -LiteralPath $_ -PathType Leaf) } |
        ForEach-Object {
            (New-Object System.Net.WebClient).DownloadFile('https://dist.nuget.org/win-x86-commandline/latest/nuget.exe', $_)
        }
    }

    function Install-PowerShellModule {
        [CmdletBinding(SupportsShouldProcess)]
        param (
            [string[]]
            $PSModule,

            [switch]
            $Force,

            [switch]
            $Optimize
        )

        if ($Optimize -or $PSModule) {
            Optimize-PackageManagement

            $PSModule |
            Where-Object { $_ } |
            ForEach-Object {
                if ($Force) {
                    Install-Module -Name $_ -Scope CurrentUser -Force -AllowClobber
                }
                else {
                    Install-Module -Name $_ -Scope CurrentUser
                }
            }
        }
    }

    function Install-Scoop {
        [CmdletBinding(SupportsShouldProcess)]
        param (
            [string[]]
            $ScoopApp,

            [hashtable]
            $ScoopBucket,

            [switch]
            $Unsafe,

            [switch]
            $Force,

            [switch]
            $Optimize
        )

        function Get-InstalledScoopApp {
            $installedApps = @()
            $appListStrings = @()
            $appListStrings += scoop list 2>&1 6>&1 | ForEach-Object ToString

            $labelList = @{
                1 = 'name'
                2 = 'version'
                3 = 'bucketName'
                4 = 'isFailed'
            }

            for (($i = 1), ($labelId = 1); $i -lt $appListStrings.Count - 2; $i++, $labelId++) {
                if ($labelId -eq 4) {
                    $labelId = 0
                    continue
                }

                switch ($labelId) {
                    1 {
                        $installedApps += [PSCustomObject]@{}
                        $appListStrings[$i] = $appListStrings[$i] -replace '^\s*|\s*$'
                    }
                    3 {
                        if ($appListStrings[$i] -match '\*failed\*') {
                            $isFailed = $true

                            $installJsonPath = $env:SCOOP |
                            Join-Path -ChildPath ('apps\{0}\current\install.json' -f $installedApps[$installedApps.Count - 1].name)

                            $bucket = ''
                            $bucket = $installJsonPath |
                            Where-Object { Test-Path -LiteralPath $_ } |
                            Get-Content -LiteralPath { $_ } |
                            ConvertFrom-Json -ErrorAction Ignore |
                            Select-Object -ExpandProperty bucket -ErrorAction Ignore
                            $appListStrings[$i] = $bucket
                        }
                        else {
                            $isFailed = $false

                            $appListStrings[$i] = $appListStrings[$i] -replace '^\s*\[|\]$'
                        }

                        $installedApps[$installedApps.Count - 1] | Add-Member -MemberType NoteProperty -Name $labelList[4] -Value $isFailed
                    }
                }

                $installedApps[$installedApps.Count - 1] | Add-Member -MemberType NoteProperty -Name $labelList[$labelId] -Value $appListStrings[$i]
            }

            return $installedApps
        }

        function Install-ScoopApp {
            [CmdletBinding(SupportsShouldProcess)]
            param (
                [string[]]
                $ScoopApp,

                [switch]
                $Unsafe,

                [switch]
                $Force
            )

            $ScoopApp |
            Where-Object { $_ } |
            ForEach-Object {
                $cmd = 'scoop install "{0}"' -f $_
                if ($Force) {
                    $cmd = '{0} --force' -f $cmd
                }
                if ($Unsafe) {
                    $cmd = '{0} --skip' -f $cmd
                }
                Invoke-Expression $cmd
            }
        }

        if ($Optimize -or $ScoopApp -or $ScoopBucket) {
            # Install Scoop
            if (!(Get-Command -Name 'scoop' -ErrorAction Ignore)) {
                Invoke-WebRequest -useb get.scoop.sh | Invoke-Expression
            }

            # Set process environment variable 'SCOOP'
            $env:SCOOP = Get-Command -Name 'scoop' |
            Select-Object -ExpandProperty Path |
            Split-Path -Parent |
            Split-Path -Parent

            # Install depends
            if (!(Get-Command -Name 'git.exe' -ErrorAction Ignore)) {
                Install-ScoopApp -ScoopApp 'git' -Unsafe:$Unsafe -Force:$Force

                if (!(Get-Command -Name 'git.exe' -ErrorAction Ignore)) {
                    # If git installation fails, uninstall it and try installing again
                    Get-InstalledScoopApp |
                    Where-Object { $_.name -eq 'git' } |
                    Where-Object { $_.isFailed -eq $true } |
                    ForEach-Object {
                        scoop uninstall $_.name
                        Install-ScoopApp -ScoopApp $_.name -Unsafe:$Unsafe -Force:$Force
                    }
                }
                if (!(Get-Command -Name 'git.exe' -ErrorAction Ignore)) {
                    # Try to avoid Scoop updates and try to install in case Git is required to update Scoop
                    $currentLastUpdate = scoop config lastupdate
                    $newLastUpdate = $currentLastUpdate -replace '\|.+', ('|{0}' -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
                    scoop config lastupdate $newLastUpdate
                    Install-ScoopApp -ScoopApp 'git' -Unsafe:$Unsafe -Force:$Force
                    scoop update
                }
            }

            @(
                @{
                    CmdName = '7z.exe'
                    AppName = '7zip'
                }
            ) |
            Where-Object { !(Get-Command -Name $_.CmdName -ErrorAction Ignore) } |
            ForEach-Object {
                Install-ScoopApp -ScoopApp $_.AppName -Unsafe:$Unsafe -Force:$Force
            }

            if ($Optimize) {
                # Set user environment variable 'SCOOP'
                if (![Environment]::GetEnvironmentVariable('SCOOP', 'User')) {
                    [Environment]::SetEnvironmentVariable('SCOOP', $env:SCOOP, 'User')
                }

                # Set Scoop Repo to Shovel
                $scoopRepo = 'https://github.com/Ash258/Scoop-Core'
                if ((scoop config SCOOP_REPO) -ne $scoopRepo) {
                    scoop config SCOOP_REPO $scoopRepo
                    scoop update
                }

                # Register Shovel executables
                if (!(Get-Command -Name 'shovel' -ErrorAction Ignore)) {
                    Join-Path $env:SCOOP 'shims' |
                    Get-ChildItem -LiteralPath { $_ } -Filter 'scoop.*' |
                    Copy-Item -Destination {
                        Join-Path $_.Directory.FullName (($_.BaseName -replace 'scoop', 'shovel') + $_.Extension)
                    }
                }

                # Install the apps recommended by Scoop
                @(
                    @{
                        CmdName = 'aria2c.exe'
                        AppName = 'aria2'
                    }
                    @{
                        CmdName = 'innounp.exe'
                        AppName = 'innounp'
                    }
                    @{
                        CmdName = 'lessmsi.exe'
                        AppName = 'lessmsi'
                    }
                ) |
                Where-Object { !(Get-Command -Name $_.CmdName -ErrorAction Ignore) } |
                ForEach-Object {
                    Install-ScoopApp -ScoopApp $_.AppName -Unsafe:$Unsafe -Force:$Force
                }

                # Enable MSIEXTRACT_USE_LESSMSI by default
                if ((scoop config MSIEXTRACT_USE_LESSMSI) -eq "'MSIEXTRACT_USE_LESSMSI' is not set") {
                    scoop config MSIEXTRACT_USE_LESSMSI $true
                }
            }

            # Install Scoop buckets
            $installedBucketNames = scoop bucket list
            [string[]]$ScoopBucket.Keys |
            Where-Object { $_ } |
            Where-Object { !($_ -in $installedBucketNames) } |
            ForEach-Object {
                $aBucketName = $_
                if ($ScoopBucket.$aBucketName) {
                    scoop bucket add $aBucketName $ScoopBucket.$aBucketName
                }
                else {
                    scoop bucket add $aBucketName
                }
            }

            # Install Scoop apps
            Install-ScoopApp -ScoopApp $ScoopApp -Unsafe:$Unsafe -Force:$Force

            if ($Optimize) {
                # Reinstall the failed apps
                Get-InstalledScoopApp |
                Where-Object { $_.isFailed -eq $true } |
                ForEach-Object {
                    $aFullName = '{0}/{1}' -f $_.bucketName, $_.name
                    scoop uninstall $aFullName
                    Install-ScoopApp -ScoopApp $aFullName -Unsafe:$Unsafe -Force:$Force
                }
            }
        }
    }

    function Install-Chocolatey {
        [CmdletBinding(SupportsShouldProcess)]
        param (
            [string[]]
            $ChocolateyPackage,

            [switch]
            $Unsafe,

            [switch]
            $Force,

            [switch]
            $Optimize
        )

        if ($Optimize -or $ChocolateyPackage) {
            if (!(Test-WUAdmin)) {
                Write-Warning "Administrator privileges are required for Chocolatey."
                return
            }

            if (!(Get-Command -Name 'chocolatey' -ErrorAction Ignore)) {
                # Prevent function name conflicts
                $PSModuleAutoloadingPreference = 'ModuleQualified'
                $moduleNames = @(
                    'Carbon'
                )
                Remove-Module $moduleNames -ErrorAction Ignore

                # Install Chocolatey
                Invoke-WebRequest https://chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression

                $PSModuleAutoloadingPreference = $null
            }

            # Set chocolatey configs
            if ($Optimize) {
                if ($Unsafe) {
                    # Disable confirm script execution
                    choco feature enable -n allowGlobalConfirmation
                    # Disable checksum
                    choco feature disable -n checksumFiles
                }
            }

            # Install Chocolatey apps
            $ChocolateyPackage |
            Where-Object { $_ } |
            ForEach-Object {
                $cmd = 'choco install "{0}" --limitoutput --yes' -f $_
                if ($Force) {
                    $cmd = '{0} --force' -f $cmd
                }
                if ($Unsafe) {
                    $cmd = '{0} --ignore-checksums' -f $cmd
                }
                Invoke-Expression $cmd
            }
        }
    }

    function Install-Pip {
        [CmdletBinding(SupportsShouldProcess)]
        param (
            [string[]]
            $PipPackage,

            [switch]
            $Force,

            [switch]
            $Optimize
        )

        if ($Optimize -or $PipPackage) {
            if (!(Get-Command -Name 'pip' -ErrorAction Ignore)) {
                Install-Scoop -ScoopApp 'python'
            }

            $PipPackage |
            Where-Object { $_ } |
            ForEach-Object {
                if ($Force) {
                    pip install --upgrade --force-reinstall $_
                }
                else {
                    pip install --upgrade $_
                }
            }
        }
    }

    function Install-Npm {
        [CmdletBinding(SupportsShouldProcess)]
        param (
            [string[]]
            $NpmPackage,

            [switch]
            $Force,

            [switch]
            $Optimize
        )

        if ($Optimize -or $NpmPackage) {
            if (!(Get-Command -Name 'npm' -ErrorAction Ignore)) {
                Install-Scoop -ScoopApp 'nodejs'
            }

            $NpmPackage |
            Where-Object { $_ } |
            ForEach-Object {
                if ($Force) {
                    npm install --global --force $_
                }
                else {
                    npm install --global $_
                }
            }
        }
    }

    function Install-NuGet {
        [CmdletBinding(SupportsShouldProcess)]
        param (
            [string[]]
            $NuGetPackage,

            [string]
            [ValidateNotNullOrEmpty()]
            $Destination = (
                $env:NUGET_PACKAGE_DIR, $PWD |
                Where-Object { $_ } |
                Where-Object { Test-Path -LiteralPath $_ -PathType Container } |
                Select-Object -First 1
            ),

            [string]
            $RequiredVersion,

            [switch]
            $Optimize
        )

        if ($Optimize -or $NuGetPackage) {
            Optimize-PackageManagement

            if (!(Get-Command -Name nuget -ErrorAction Ignore)) {
                Install-Scoop -ScoopApp 'nuget'
            }

            if (!(Test-WUPathProperty -LiteralPath $Destination -PSProvider FileSystem -PathType Container)) {
                New-Item -Path $Destination -ItemType 'Directory' -Force | Out-String | Write-Verbose
                if (!(Test-WUPathProperty -LiteralPath $Destination -PSProvider FileSystem -PathType Container)) {
                    return
                }
            }

            # Install-Package -Name $_ -Destination $Destination -ProviderName NuGet @installPackageArgs
            # The above code is slow.
            $NuGetPackage |
            Where-Object { $_ } |
            ForEach-Object {
                $cmd = 'nuget install "{0}"' -f $_
                $cmd = '{0} -OutputDirectory "{1}"' -f $cmd, ($Destination | Convert-WUString -Type EscapeForPowerShellDoubleQuotation)
                if ($RequiredVersion) {
                    $cmd = '{0} -Version "{1}"' -f $cmd, $RequiredVersion
                }
                Invoke-Expression $cmd
            }
        }
    }

    $params = @{} + $PSBoundParameters
    $keyNames = @(
        'PSModule'
        'Force'
    )
    [string[]]$params.Keys |
    Where-Object { !($_ -in $keyNames) } |
    ForEach-Object { $params.Remove($_) }
    $params.Optimize = & $shouldOptimize -Provider 'PSModule'
    Install-PowerShellModule @params | ForEach-Object { Write-Host $_ }

    $params = @{} + $PSBoundParameters
    $keyNames = @(
        'ScoopApp'
        'ScoopBucket'
        'Unsafe'
        'Force'
    )
    [string[]]$params.Keys |
    Where-Object { !($_ -in $keyNames) } |
    ForEach-Object { $params.Remove($_) }
    $params.Optimize = & $shouldOptimize -Provider 'Scoop'
    Install-Scoop @params | ForEach-Object { Write-Host $_ }

    $params = @{} + $PSBoundParameters
    $keyNames = @(
        'ChocolateyPackage'
        'Unsafe'
        'Force'
    )
    [string[]]$params.Keys |
    Where-Object { !($_ -in $keyNames) } |
    ForEach-Object { $params.Remove($_) }
    $params.Optimize = & $shouldOptimize -Provider 'Chocolatey'
    Install-Chocolatey @params | ForEach-Object { Write-Host $_ }

    $params = @{} + $PSBoundParameters
    $keyNames = @(
        'PipPackage'
        'Force'
    )
    [string[]]$params.Keys |
    Where-Object { !($_ -in $keyNames) } |
    ForEach-Object { $params.Remove($_) }
    $params.Optimize = & $shouldOptimize -Provider 'pip'
    Install-Pip @params | ForEach-Object { Write-Host $_ }

    $params = @{} + $PSBoundParameters
    $keyNames = @(
        'NpmPackage'
        'Force'
    )
    [string[]]$params.Keys |
    Where-Object { !($_ -in $keyNames) } |
    ForEach-Object { $params.Remove($_) }
    $params.Optimize = & $shouldOptimize -Provider 'npm'
    Install-Npm @params | ForEach-Object { Write-Host $_ }

    $params = @{} + $PSBoundParameters
    $keyNames = @(
        'NuGetPackage'
        'Destination'
        'RequiredVersion'
    )
    [string[]]$params.Keys |
    Where-Object { !($_ -in $keyNames) } |
    ForEach-Object { $params.Remove($_) }
    $params.Optimize = & $shouldOptimize -Provider 'NuGet'
    Install-NuGet @params | ForEach-Object { Write-Host $_ }
}
