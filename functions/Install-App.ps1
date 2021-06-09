function Install-WUApp {
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
        $Pip3Package,

        [switch]
        $Unsafe,

        [switch]
        $Force,

        [ValidateSet('All', 'Scoop', 'Chocolatey', 'PSModule', 'Pip')]
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
            # PowerShell Gallery
            if (!(Get-PackageProvider | Where-Object Name -EQ 'NuGet')) {
                Install-PackageProvider -Name 'NuGet' -Force -Scope CurrentUser
            }
            if (!(Get-PSRepository | Where-Object { $_.Name -eq 'PSGallery' -and $_.InstallationPolicy -eq 'Trusted' })) {
                Set-PSRepository -Name 'PSGallery' -InstallationPolicy 'Trusted'
            }

            # Update PowerShellGet Module
            if (@(Get-Module 'PowerShellGet' -ListAvailable).Count -eq 1) {
                Install-Module -Name PowerShellGet -Force -AllowClobber -Scope CurrentUser
                Update-Module -Name PowerShellGet
            }

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
                scoop install git

                if (!(Get-Command -Name 'git.exe' -ErrorAction Ignore)) {
                    # If git installation fails, uninstall it and try installing again
                    Get-InstalledScoopApp |
                    Where-Object { $_.name -eq 'git' } |
                    Where-Object { $_.isFailed -eq $true } |
                    ForEach-Object {
                        scoop uninstall $_.name
                        scoop install $_.name
                    }
                }
                if (!(Get-Command -Name 'git.exe' -ErrorAction Ignore)) {
                    # Try to avoid Scoop updates and try to install in case Git is required to update Scoop
                    $currentLastUpdate = scoop config lastupdate
                    $newLastUpdate = $currentLastUpdate -replace '\|.+', ('|{0}' -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
                    scoop config lastupdate $newLastUpdate
                    scoop install git
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
                scoop install $_.AppName
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
                    scoop install $_.AppName
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
            $ScoopApp |
            Where-Object { $_ } |
            ForEach-Object {
                if ($Force) {
                    scoop install $_ --force
                }
                else {
                    scoop install $_
                }
            }

            if ($Optimize) {
                # Reinstall the failed apps
                Get-InstalledScoopApp |
                Where-Object { $_.isFailed -eq $true } |
                ForEach-Object {
                    $aFullName = '{0}/{1}' -f $_.bucketName, $_.name
                    scoop uninstall $aFullName
                    scoop install $aFullName
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

            if (!(Get-Command -Name chocolatey -ErrorAction Ignore)) {
                # Prevent function name conflicts
                $PSModuleAutoloadingPreference = 'ModuleQualified'
                $moduleNames = @(
                    'Carbon'
                )
                Remove-Module $moduleNames -ErrorAction Ignore

                # Install Chocolatey
                Invoke-WebRequest https://chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression

                # Set chocolatey config
                if ($Unsafe) {
                    # Disable confirm script execution
                    choco feature enable -n allowGlobalConfirmation
                    # Disable checksum
                    choco feature disable -n checksumFiles
                }

                $PSModuleAutoloadingPreference = $null
            }

            $ChocolateyPackage |
            Where-Object { $_ } |
            ForEach-Object {
                if ($Force) {
                    choco install $_ -y -limitoutput --force --ignore-checksums
                }
                else {
                    choco install $_ -y -limitoutput
                }
            }
        }
    }

    function Install-Pip3 {
        [CmdletBinding(SupportsShouldProcess)]
        param (
            [string[]]
            $Pip3Package,

            [switch]
            $Force,

            [switch]
            $Optimize
        )

        if ($Optimize -or $Pip3Package) {
            if (!(Get-Command -Name pip3 -ErrorAction Ignore)) {
                Install-Scoop -ScoopApp 'python'
            }

            $Pip3Package |
            Where-Object { $_ } |
            ForEach-Object {
                if ($Force) {
                    pip3 install --upgrade --force-reinstall $_
                }
                else {
                    pip3 install --upgrade $_
                }
            }
        }
    }

    $params = @{} + $PSBoundParameters
    $keyNames = @(
        'PSModule'
        'Force'
    )
    $removeKeyNames = $params.Keys | Where-Object { !($_ -in $keyNames) }
    $removeKeyNames | ForEach-Object { $params.Remove($_) }
    $params.Optimize = & $shouldOptimize -Provider 'PSModule'
    Install-PowerShellModule @params

    $params = @{} + $PSBoundParameters
    $keyNames = @(
        'ScoopApp'
        'ScoopBucket'
        'Force'
    )
    $removeKeyNames = $params.Keys | Where-Object { !($_ -in $keyNames) }
    $removeKeyNames | ForEach-Object { $params.Remove($_) }
    $params.Optimize = & $shouldOptimize -Provider 'Scoop'
    Install-Scoop @params

    $params = @{} + $PSBoundParameters
    $keyNames = @(
        'ChocolateyPackage'
        'Unsafe'
        'Force'
    )
    $removeKeyNames = $params.Keys | Where-Object { !($_ -in $keyNames) }
    $removeKeyNames | ForEach-Object { $params.Remove($_) }
    $params.Optimize = & $shouldOptimize -Provider 'Chocolatey'
    Install-Chocolatey @params

    $params = @{} + $PSBoundParameters
    $keyNames = @(
        'Pip3Package'
        'Force'
    )
    $removeKeyNames = $params.Keys | Where-Object { !($_ -in $keyNames) }
    $removeKeyNames | ForEach-Object { $params.Remove($_) }
    $params.Optimize = & $shouldOptimize -Provider 'Pip'
    Install-Pip3 @params
}
