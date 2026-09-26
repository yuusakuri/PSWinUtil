BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $script:OutputModuleDirectory = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil'
    $script:DevScriptPath = Join-Path -Path $repositoryRoot -ChildPath 'dev.ps1'
}

Describe 'Distribution contents' {
    It 'contains the module entry files' {
        @(
            Test-Path -LiteralPath (Join-Path -Path $script:OutputModuleDirectory -ChildPath 'PSWinUtil.psd1') -PathType Leaf
            Test-Path -LiteralPath (Join-Path -Path $script:OutputModuleDirectory -ChildPath 'PSWinUtil.psm1') -PathType Leaf
        ) | Should -Not -Contain $false
    }

    It 'contains the registry config data copied by ModuleBuilder' {
        $registryConfigPath = Join-Path -Path $script:OutputModuleDirectory -ChildPath 'data/RegistryConfig.psd1'

        Test-Path -LiteralPath $registryConfigPath -PathType Leaf | Should -BeTrue
        $registryConfig = Import-PowerShellDataFile -Path $registryConfigPath
        @($registryConfig.Configs.Name) | Should -Contain 'DarkMode'
    }

    It 'can be imported through the development command' {
        & $script:DevScriptPath import

        $importedModules = @(
            Get-Module -Name 'PSWinUtil' |
                Where-Object { $_.ModuleBase -eq $script:OutputModuleDirectory }
        )
        $importedModules.Count | Should -BeGreaterThan 0
    }
}
