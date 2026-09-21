Describe 'User PATH integration' {
    BeforeAll {
        $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
        $manifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
        Import-Module -Name $manifestPath -Force -ErrorAction Stop

        $script:EnvironmentTarget = [System.EnvironmentVariableTarget]::User
        $script:OriginalPathValue = [System.Environment]::GetEnvironmentVariable(
            'Path',
            $script:EnvironmentTarget
        )
        $registryKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', $false)
        try {
            if ($null -eq $registryKey) {
                $script:OriginalPathRawValue = $null
                $script:OriginalPathValueKind = $null
            } else {
                $script:OriginalPathRawValue = $registryKey.GetValue(
                    'Path',
                    $null,
                    [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
                )
                if ($null -eq $script:OriginalPathRawValue) {
                    $script:OriginalPathValueKind = $null
                } else {
                    $script:OriginalPathValueKind = $registryKey.GetValueKind('Path')
                }
            }
        } finally {
            if ($null -ne $registryKey) {
                $registryKey.Dispose()
            }
        }
        $script:TestPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath (
            'PSWinUtil-' + [guid]::NewGuid().ToString('N')
        )
        [System.IO.Directory]::CreateDirectory($script:TestPath) | Out-Null
        $script:RestoreUserPath = {
            $registryKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', $true)
            if ($null -eq $registryKey -and $null -eq $script:OriginalPathRawValue) {
                return
            }
            if ($null -eq $registryKey) {
                $registryKey = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey('Environment')
            }
            try {
                if ($null -eq $script:OriginalPathRawValue) {
                    $registryKey.DeleteValue('Path', $false)
                } else {
                    $registryKey.SetValue(
                        'Path',
                        $script:OriginalPathRawValue,
                        $script:OriginalPathValueKind
                    )
                }
            } finally {
                if ($null -ne $registryKey) {
                    $registryKey.Dispose()
                }
            }
            [PSWinUtil.EnvironmentChangeNotification]::Broadcast() | Out-Null
        }
    }

    BeforeEach {
        $script:OriginalProcessEnvironment = [Environment]::GetEnvironmentVariables('Process')
        & $script:RestoreUserPath
    }

    AfterEach {
        & $script:RestoreUserPath
        foreach ($name in [Environment]::GetEnvironmentVariables('Process').Keys) {
            if (-not $script:OriginalProcessEnvironment.Contains($name)) {
                [Environment]::SetEnvironmentVariable($name, $null, 'Process')
            }
        }
        foreach ($name in $script:OriginalProcessEnvironment.Keys) {
            [Environment]::SetEnvironmentVariable($name, $script:OriginalProcessEnvironment[$name], 'Process')
        }
    }

    AfterAll {
        & $script:RestoreUserPath
        if ([System.IO.Directory]::Exists($script:TestPath)) {
            [System.IO.Directory]::Delete($script:TestPath, $true)
        }
    }

    It 'adds a path without changing existing items' {
        Add-WUPathEnvironmentVariable -Path $script:TestPath -Scope User

        $updatedValue = [System.Environment]::GetEnvironmentVariable('Path', $script:EnvironmentTarget)
        $updatedValue.Split([char]';') | Should -Contain $script:TestPath
        $updatedValue | Should -BeLike "$($script:OriginalPathValue)*"
    }

    It 'does not add a normalized duplicate' {
        Add-WUPathEnvironmentVariable -Path $script:TestPath -Scope User
        Add-WUPathEnvironmentVariable -Path ($script:TestPath.ToLowerInvariant() + '\') -Scope User

        $updatedValue = [System.Environment]::GetEnvironmentVariable('Path', $script:EnvironmentTarget)
        $matchingPaths = @(
            $updatedValue.Split([char]';') |
                Where-Object {
                    $_.TrimEnd([char]'\') -ieq $script:TestPath.TrimEnd([char]'\')
                }
        )
        $matchingPaths.Count | Should -Be 1
    }

    It 'does not add a duplicate when one entry uses an environment variable' {
        $variableName = 'PSWINUTIL_PATH_ROOT_' + [guid]::NewGuid().ToString('N')
        $targetPath = Join-Path $script:TestPath 'bin'
        try {
            Set-WUEnvironmentVariable -Name $variableName -Value $script:TestPath -Scope User
            Add-WUPathEnvironmentVariable -Path $targetPath -Scope User
            Add-WUPathEnvironmentVariable -Path "%$variableName%\bin" -Scope User

            $rawPath = Get-WUEnvironmentVariable -Name 'Path' -Scope User -NoExpand
            $entries = @($rawPath -split ';')
            $entries | Should -Contain $targetPath
            $entries | Should -Not -Contain "%$variableName%\bin"

            Remove-WUPathEnvironmentVariable -Path $targetPath -Scope User
            Add-WUPathEnvironmentVariable -Path "%$variableName%\bin" -Scope User
            Add-WUPathEnvironmentVariable -Path $targetPath -Scope User

            $rawPath = Get-WUEnvironmentVariable -Name 'Path' -Scope User -NoExpand
            $entries = @($rawPath -split ';')
            $entries | Should -Contain "%$variableName%\bin"
            $entries | Should -Not -Contain $targetPath
        } finally {
            Remove-WUEnvironmentVariable -Name $variableName -Scope User
        }
    }

    It 'removes a path by its normalized value' {
        Add-WUPathEnvironmentVariable -Path $script:TestPath -Scope User

        Remove-WUPathEnvironmentVariable -Path ($script:TestPath + '\') -Scope User

        $updatedValue = [System.Environment]::GetEnvironmentVariable('Path', $script:EnvironmentTarget)
        $matchingPaths = @(
            @($updatedValue -split ';') |
                Where-Object {
                    $_.TrimEnd([char]'\') -ieq $script:TestPath.TrimEnd([char]'\')
                }
        )
        $matchingPaths.Count | Should -Be 0
    }

    It 'preserves expandable references in the persistent user PATH' {
        $variableName = 'PSWINUTIL_PATH_ROOT_' + [guid]::NewGuid().ToString('N')
        try {
            Set-WUEnvironmentVariable -Name $variableName -Value $script:TestPath -Scope User
            Add-WUPathEnvironmentVariable -Path "%$variableName%\bin" -Scope User

            $registryKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', $false)
            try {
                $storedPath = $registryKey.GetValue(
                    'Path',
                    $null,
                    [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
                )
                $storedPath | Should -Match "%$variableName%\\bin"
                $registryKey.GetValueKind('Path') | Should -Be ([Microsoft.Win32.RegistryValueKind]::ExpandString)
            } finally {
                if ($null -ne $registryKey) {
                    $registryKey.Dispose()
                }
            }

            Update-WUProcessEnvironment
            $env:Path |
                Should -Match ([regex]::Escape((Join-Path $script:TestPath 'bin')))
        } finally {
            Remove-WUEnvironmentVariable -Name $variableName -Scope User
            & $script:RestoreUserPath
        }
    }
}
