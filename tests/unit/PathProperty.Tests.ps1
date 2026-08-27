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

    It 'converts PathInfo pipeline input from Resolve-WUPath' {
        $result = Resolve-WUPath -LiteralPath $TestDrive |
            ConvertTo-WUFullPath

        $result | Should -Be $TestDrive
    }

    It 'rejects a non-file-system provider path' {
        { ConvertTo-WUFullPath -Path 'Env:\Path' } | Should -Throw '*FileSystem provider*'
    }

    It 'rejects non-file-system PathInfo pipeline input' {
        { Resolve-WUPath -LiteralPath 'Env:\PATH' | ConvertTo-WUFullPath } |
            Should -Throw '*FileSystem provider*'
    }
}

Describe 'Resolve-WUPath' {
    BeforeEach {
        $script:ResolvePathDirectory = Join-Path -Path $TestDrive -ChildPath 'Resolve-WUPath'
        $null = New-Item -Path $script:ResolvePathDirectory -ItemType Directory -Force
        $script:FirstPath = Join-Path -Path $script:ResolvePathDirectory -ChildPath 'first.txt'
        $script:SecondPath = Join-Path -Path $script:ResolvePathDirectory -ChildPath 'second.txt'
        $script:LiteralPath = Join-Path -Path $script:ResolvePathDirectory -ChildPath 'item[1].txt'
        [System.IO.File]::WriteAllText($script:FirstPath, 'first')
        [System.IO.File]::WriteAllText($script:SecondPath, 'second')
        [System.IO.File]::WriteAllText($script:LiteralPath, 'literal')
    }

    It 'preserves Resolve-Path wildcard behavior' {
        $results = @(Resolve-WUPath -Path "$script:ResolvePathDirectory\*.txt")

        $results | Should -HaveCount 3
        @($results.ProviderPath) | Should -Contain $script:FirstPath
        @($results.ProviderPath) | Should -Contain $script:SecondPath
        @($results.ProviderPath) | Should -Contain $script:LiteralPath
    }

    It 'resolves LiteralPath without wildcard interpretation' {
        $result = Resolve-WUPath -LiteralPath $script:LiteralPath

        $result.ProviderPath | Should -Be $script:LiteralPath
    }

    It 'preserves relative path output' {
        Push-Location -LiteralPath $script:ResolvePathDirectory
        try {
            $result = Resolve-WUPath -LiteralPath $script:FirstPath -Relative
        } finally {
            Pop-Location
        }

        $result | Should -Be '.\first.txt'
    }

    It 'accepts path values from the pipeline' {
        $results = @($script:FirstPath, $script:SecondPath) | Resolve-WUPath

        $results | Should -HaveCount 2
        @($results.ProviderPath) | Should -Contain $script:FirstPath
        @($results.ProviderPath) | Should -Contain $script:SecondPath
    }

    It 'returns one path when DenyMultiplePaths receives one result' {
        $result = Resolve-WUPath `
            -LiteralPath $script:FirstPath `
            -DenyMultiplePaths

        $result.ProviderPath | Should -Be $script:FirstPath
    }

    It 'rejects multiple wildcard results when DenyMultiplePaths is specified' {
        try {
            $null = Resolve-WUPath `
                -Path "$script:ResolvePathDirectory\*.txt" `
                -DenyMultiplePaths
            throw 'Expected Resolve-WUPath to report an error.'
        } catch {
            $_.Exception | Should -BeOfType ([System.ArgumentException])
            $_.Exception.Message | Should -Be 'Path resolved to more than one result'
        }
    }

    It 'rejects multiple pipeline results when DenyMultiplePaths is specified' {
        { @($script:FirstPath, $script:SecondPath) | Resolve-WUPath -DenyMultiplePaths } |
            Should -Throw '*more than one result*'
    }

    It 'reports ItemNotFoundException for no result with DenyMultiplePaths' {
        $missingPath = Join-Path -Path $script:ResolvePathDirectory -ChildPath 'missing.txt'

        try {
            $null = Resolve-WUPath `
                -LiteralPath $missingPath `
                -DenyMultiplePaths
            throw 'Expected Resolve-WUPath to report an error.'
        } catch {
            $_.Exception | Should -BeOfType (
                [System.Management.Automation.ItemNotFoundException]
            )
        }
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

    It 'returns true for an existing path when no additional property is specified' {
        Test-WUPathProperty -Path $script:TestFile | Should -BeTrue
    }

    It 'distinguishes files and directories' {
        Test-WUPathProperty -Path $script:TestFile -Leaf | Should -BeTrue
        Test-WUPathProperty -Path $script:TestFile -Container | Should -BeFalse
        Test-WUPathProperty -Path $script:TestDirectory -Container | Should -BeTrue
        Test-WUPathProperty -Path $script:TestDirectory -Leaf | Should -BeFalse
    }

    It 'returns one result for each wildcard Path match' {
        $secondFile = Join-Path -Path $TestDrive -ChildPath 'second.txt'
        [System.IO.File]::WriteAllText($secondFile, 'second')

        $results = @(Test-WUPathProperty -Path "$TestDrive\*.txt" -Leaf)

        $results | Should -HaveCount 2
        $results | Should -Not -Contain $false
    }

    It 'returns false for a wildcard Path without matches' {
        Test-WUPathProperty -Path "$TestDrive\missing-*.txt" -Leaf |
            Should -BeFalse
    }

    It 'tests LiteralPath values without wildcard interpretation' {
        $literalPath = Join-Path -Path $TestDrive -ChildPath 'item[1].txt'
        [System.IO.File]::WriteAllText($literalPath, 'content')

        Test-WUPathProperty -LiteralPath $literalPath -Leaf |
            Should -BeTrue
    }

    It 'tests paths from a non-file-system provider' {
        Test-WUPathProperty -LiteralPath 'Env:\PATH' -Leaf | Should -BeTrue
        Test-WUPathProperty -LiteralPath 'Env:\PATH' -Container | Should -BeFalse
    }

    It 'rejects conflicting item types' {
        { Test-WUPathProperty -Path $script:TestFile -Leaf -Container } | Should -Throw
    }
}

Describe 'Assert-WUPathProperty' {
    It 'produces no output for a matching path' {
        $result = Assert-WUPathProperty -Path $TestDrive -Container

        $result | Should -BeNullOrEmpty
    }

    It 'reports an error for a missing path' {
        {
            Assert-WUPathProperty -Path (Join-Path -Path $TestDrive -ChildPath 'missing')
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

    It 'expands wildcard Path values' {
        $firstFile = Join-Path -Path $TestDrive -ChildPath 'first.pem'
        $secondFile = Join-Path -Path $TestDrive -ChildPath 'second.pem'
        [System.IO.File]::WriteAllText($firstFile, 'first')
        [System.IO.File]::WriteAllText($secondFile, 'second')

        { Assert-WUPathProperty -Path "$TestDrive\*.pem" -Leaf } |
            Should -Not -Throw
    }

    It 'validates every wildcard match' {
        $filePath = Join-Path -Path $TestDrive -ChildPath 'entry-file'
        $directoryPath = Join-Path -Path $TestDrive -ChildPath 'entry-directory'
        [System.IO.File]::WriteAllText($filePath, 'content')
        $null = New-Item -Path $directoryPath -ItemType Directory -Force

        { Assert-WUPathProperty -Path "$TestDrive\entry-*" -Leaf } |
            Should -Throw '*required properties*'
    }

    It 'allows a wildcard Path without matches when AllowNonExisting is specified' {
        { Assert-WUPathProperty -Path "$TestDrive\missing-*.pem" -Leaf -AllowNonExisting } |
            Should -Not -Throw
    }

    It 'checks LiteralPath values without wildcard interpretation' {
        $literalPath = Join-Path -Path $TestDrive -ChildPath 'certificate[1].pem'
        [System.IO.File]::WriteAllText($literalPath, 'content')

        { Assert-WUPathProperty -LiteralPath $literalPath -Leaf } |
            Should -Not -Throw
    }

    It 'checks paths from a non-file-system provider' {
        { Assert-WUPathProperty -LiteralPath 'Env:\PATH' -Leaf } |
            Should -Not -Throw
        { Assert-WUPathProperty -LiteralPath 'Env:\PATH' -Container } |
            Should -Throw '*required properties*'
    }
}
