$sshKeygenAvailable = $null -ne (
    Get-Command -Name 'ssh-keygen.exe' -CommandType Application -ErrorAction SilentlyContinue
)

BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $manifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
    Import-Module -Name $manifestPath -Force -ErrorAction Stop
}

Describe 'SSH key integration' -Skip:(-not $sshKeygenAvailable) {
    BeforeEach {
        $script:KeyPath = Join-Path -Path $TestDrive -ChildPath "key-$(New-WURandomString -Length 12)"
    }

    AfterEach {
        foreach ($pathToRemove in @($script:KeyPath, "$($script:KeyPath).pub")) {
            if (Test-Path -LiteralPath $pathToRemove) {
                Remove-Item -LiteralPath $pathToRemove -Force
            }
        }
    }

    It 'creates a private and public key' {
        $result = New-WUSshKey -Path $script:KeyPath -Type ed25519 -Comment 'integration test'

        $result.FullName | Should -Be $script:KeyPath
        Test-Path -LiteralPath $script:KeyPath -PathType Leaf | Should -BeTrue
        Test-Path -LiteralPath "$($script:KeyPath).pub" -PathType Leaf | Should -BeTrue
    }

    It 'changes a key comment' {
        $null = New-WUSshKey -Path $script:KeyPath -Type ed25519 -Comment 'first comment'

        $result = Edit-WUSshKey -KeyPath $script:KeyPath -CurrentPassphrase '' -Comment 'updated comment'

        $result.FullName | Should -Be $script:KeyPath
        [System.IO.File]::ReadAllText("$($script:KeyPath).pub").TrimEnd() | Should -Match ' updated comment$'
    }
}
