Describe 'Machine PATH integration' {
    BeforeAll {
        $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
        $manifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
        Import-Module -Name $manifestPath -Force -ErrorAction Stop

        $script:EnvironmentTarget = [System.EnvironmentVariableTarget]::Machine
        $script:OriginalPathValue = [System.Environment]::GetEnvironmentVariable(
            'Path',
            $script:EnvironmentTarget
        )
        $script:TestPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath (
            'PSWinUtil-' + [guid]::NewGuid().ToString('N')
        )
        $null = [System.IO.Directory]::CreateDirectory($script:TestPath)
    }

    BeforeEach {
        [System.Environment]::SetEnvironmentVariable(
            'Path',
            $script:OriginalPathValue,
            $script:EnvironmentTarget
        )
    }

    AfterEach {
        [System.Environment]::SetEnvironmentVariable(
            'Path',
            $script:OriginalPathValue,
            $script:EnvironmentTarget
        )
    }

    AfterAll {
        [System.Environment]::SetEnvironmentVariable(
            'Path',
            $script:OriginalPathValue,
            $script:EnvironmentTarget
        )
        if ([System.IO.Directory]::Exists($script:TestPath)) {
            [System.IO.Directory]::Delete($script:TestPath, $true)
        }
    }

    It 'adds a path without changing existing items' {
        Add-WUPathEnvironmentVariable -Path $script:TestPath -Scope Machine

        $updatedValue = [System.Environment]::GetEnvironmentVariable('Path', $script:EnvironmentTarget)
        $updatedValue.Split([char]';') | Should -Contain $script:TestPath
        $updatedValue | Should -BeLike "$($script:OriginalPathValue)*"
    }

    It 'does not add a normalized duplicate' {
        Add-WUPathEnvironmentVariable -Path $script:TestPath -Scope Machine
        Add-WUPathEnvironmentVariable -Path ($script:TestPath.ToLowerInvariant() + '\') -Scope Machine

        $updatedValue = [System.Environment]::GetEnvironmentVariable('Path', $script:EnvironmentTarget)
        $matchingPaths = @(
            $updatedValue.Split([char]';') |
                Where-Object {
                    $_.TrimEnd([char]'\') -ieq $script:TestPath.TrimEnd([char]'\')
                }
        )
        $matchingPaths.Count | Should -Be 1
    }

    It 'removes a path by its normalized value' {
        Add-WUPathEnvironmentVariable -Path $script:TestPath -Scope Machine

        Remove-WUPathEnvironmentVariable -Path ($script:TestPath + '\') -Scope Machine

        $updatedValue = [System.Environment]::GetEnvironmentVariable('Path', $script:EnvironmentTarget)
        $matchingPaths = @(
            @($updatedValue -split ';') |
                Where-Object {
                    $_.TrimEnd([char]'\') -ieq $script:TestPath.TrimEnd([char]'\')
                }
        )
        $matchingPaths.Count | Should -Be 0
    }
}
