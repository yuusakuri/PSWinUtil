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
}
