BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $manifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
    Import-Module -Name $manifestPath -Force -ErrorAction Stop
}

Describe 'ConvertTo-WUFullPath' {
    It 'converts a relative path without requiring it to exist' {
        Push-Location -LiteralPath $TestDrive
        try {
            $result = ConvertTo-WUFullPath -Path '.\missing\item.txt'
        } finally {
            Pop-Location
        }

        [System.IO.Path]::IsPathRooted($result) | Should -BeTrue
        $result | Should -Be (Join-Path -Path $TestDrive -ChildPath 'missing/item.txt')
    }

    It 'accepts multiple pipeline inputs' {
        $results = @('one.txt', 'two.txt') | ConvertTo-WUFullPath

        $results.Count | Should -Be 2
        $results | ForEach-Object { [System.IO.Path]::IsPathRooted($_) | Should -BeTrue }
    }

    It 'rejects a non-file-system provider path' {
        { ConvertTo-WUFullPath -Path 'Env:\Path' } | Should -Throw '*FileSystem provider*'
    }
}

Describe 'Resolve-WUExistingFileSystemPath' {
    BeforeEach {
        $script:FirstDataFile = Join-Path -Path $TestDrive -ChildPath 'first.psd1'
        $script:LiteralDataFile = Join-Path -Path $TestDrive -ChildPath 'environment[1].psd1'
        [System.IO.File]::WriteAllText($script:FirstDataFile, '@{}')
        [System.IO.File]::WriteAllText($script:LiteralDataFile, '@{}')
    }

    It 'expands wildcard Path values' {
        $result = InModuleScope -ModuleName PSWinUtil -Parameters @{ DataDirectory = $TestDrive } {
            param($DataDirectory)
            @(Resolve-WUExistingFileSystemPath -Path "$DataDirectory\*.psd1" -Leaf)
        }

        $result | Should -HaveCount 2
        $result | Should -Contain $script:FirstDataFile
        $result | Should -Contain $script:LiteralDataFile
    }

    It 'resolves LiteralPath without wildcard interpretation' {
        $result = InModuleScope -ModuleName PSWinUtil -Parameters @{ DataPath = $script:LiteralDataFile } {
            param($DataPath)
            Resolve-WUExistingFileSystemPath -LiteralPath $DataPath -Leaf
        }

        $result | Should -Be $script:LiteralDataFile
    }

    It 'rejects a resolved path with the wrong item type' {
        {
            InModuleScope -ModuleName PSWinUtil -Parameters @{ DataPath = $script:FirstDataFile } {
                param($DataPath)
                Resolve-WUExistingFileSystemPath -LiteralPath $DataPath -Container
            }
        } | Should -Throw '*required properties*'
    }

    It 'rejects a non-file-system provider' {
        {
            InModuleScope -ModuleName PSWinUtil {
                Resolve-WUExistingFileSystemPath -LiteralPath 'Env:\PATH'
            }
        } | Should -Throw '*FileSystem provider*'
    }
}

Describe 'Test-WUPathProperty' {
    BeforeEach {
        $script:TestFile = Join-Path -Path $TestDrive -ChildPath 'item.txt'
        [System.IO.File]::WriteAllText($script:TestFile, 'value')
        $script:TestDirectory = Join-Path -Path $TestDrive -ChildPath 'directory'
        $null = New-Item -Path $script:TestDirectory -ItemType Directory -Force
    }

    It 'returns false for a missing path' {
        Test-WUPathProperty -Path (Join-Path -Path $TestDrive -ChildPath 'missing') | Should -BeFalse
    }

    It 'distinguishes files and directories' {
        Test-WUPathProperty -Path $script:TestFile -Leaf | Should -BeTrue
        Test-WUPathProperty -Path $script:TestFile -Container | Should -BeFalse
        Test-WUPathProperty -Path $script:TestDirectory -Container | Should -BeTrue
        Test-WUPathProperty -Path $script:TestDirectory -Leaf | Should -BeFalse
    }

    It 'tests readable and writable paths' {
        Test-WUPathProperty -Path $script:TestFile -Readable -Writable | Should -BeTrue
        Test-WUPathProperty -Path $script:TestDirectory -Readable -Writable | Should -BeTrue
    }

    It 'rejects conflicting item types' {
        { Test-WUPathProperty -Path $script:TestFile -Leaf -Container } | Should -Throw
    }
}

Describe 'Assert-WUPathProperty' {
    It 'produces no output for a matching path' {
        $result = Assert-WUPathProperty -Path $TestDrive -Container -Readable -Writable

        $result | Should -BeNullOrEmpty
    }

    It 'reports an error for a missing path' {
        {
            Assert-WUPathProperty -Path (Join-Path -Path $TestDrive -ChildPath 'missing') -Exists
        } | Should -Throw '*required properties*'
    }

    It 'allows a missing path while validating the type of an existing path' {
        $missingPath = Join-Path -Path $TestDrive -ChildPath 'missing-directory'
        $filePath = Join-Path -Path $TestDrive -ChildPath 'existing-file.txt'
        [System.IO.File]::WriteAllText($filePath, 'content')

        { Assert-WUPathProperty -Path $missingPath -Container -AllowNonExisting } |
            Should -Not -Throw
        { Assert-WUPathProperty -Path $filePath -Container -AllowNonExisting } |
            Should -Throw '*required properties*'
    }

    It 'rejects conflicting existence requirements' {
        {
            Assert-WUPathProperty -Path $TestDrive -Exists -AllowNonExisting
        } | Should -Throw '*cannot be specified together*'
    }
}
