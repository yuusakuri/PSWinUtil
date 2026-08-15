BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $script:OutputModuleDirectory = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil'
}

Describe 'Distribution contents' {
    It 'contains the module entry files' {
        @(
            Test-Path -LiteralPath (Join-Path -Path $script:OutputModuleDirectory -ChildPath 'PSWinUtil.psd1') -PathType Leaf
            Test-Path -LiteralPath (Join-Path -Path $script:OutputModuleDirectory -ChildPath 'PSWinUtil.psm1') -PathType Leaf
        ) | Should -Not -Contain $false
    }

    It 'contains the registry setting data copied by ModuleBuilder' {
        $registrySettingPath = Join-Path `
            -Path $script:OutputModuleDirectory `
            -ChildPath 'data/RegistrySettings.psd1'

        Test-Path -LiteralPath $registrySettingPath -PathType Leaf | Should -BeTrue
        $settings = Import-PowerShellDataFile -Path $registrySettingPath
        $settings.ContainsKey('DarkMode') | Should -BeTrue
    }
}
