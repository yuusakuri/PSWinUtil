$sshKeygenAvailable = $null -ne (
    Get-Command -Name 'ssh-keygen.exe' -CommandType Application -ErrorAction SilentlyContinue
)

BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $manifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
    Import-Module -Name $manifestPath -Force -ErrorAction Stop
}

Describe 'SSH key integration' -Skip:(-not $sshKeygenAvailable) {
    It 'changes a passphrase and preserves the key after an incorrect passphrase' {
        $keyPath = Join-Path $TestDrive 'passphrase key[1]'
        $null = New-WUSshKey -Path $keyPath -Type ed25519 -Passphrase 'old secret'
        $publicKey = [IO.File]::ReadAllText("$keyPath.pub")
        $before = [Convert]::ToBase64String([IO.File]::ReadAllBytes($keyPath))
        { Edit-WUSshKey -LiteralPath $keyPath -CurrentPassphrase wrong -NewPassphrase 'new secret' } | Should -Throw
        [Convert]::ToBase64String([IO.File]::ReadAllBytes($keyPath)) | Should -Be $before
        $null = Edit-WUSshKey -LiteralPath $keyPath -CurrentPassphrase 'old secret' -NewPassphrase 'new secret'
        $null = Edit-WUSshKey -LiteralPath $keyPath -CurrentPassphrase 'new secret' -NewPassphrase ''
        [IO.File]::ReadAllText("$keyPath.pub") | Should -Be $publicKey
    }

    It 'preserves existing keys on duplicate creation and Force WhatIf' {
        $keyPath = Join-Path $TestDrive 'preserved-key'
        $null = New-WUSshKey -Path $keyPath -Type ed25519
        $before = (Get-FileHash -LiteralPath $keyPath).Hash
        { New-WUSshKey -Path $keyPath -Type ed25519 } | Should -Throw '*already exists*'
        New-WUSshKey -Path $keyPath -Type ed25519 -Force -WhatIf
        (Get-FileHash -LiteralPath $keyPath).Hash | Should -Be $before
    }

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
