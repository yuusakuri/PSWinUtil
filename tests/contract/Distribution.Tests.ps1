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
}
