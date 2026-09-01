Describe 'Get-WUFileTreeWithContent' {
    BeforeEach {
        $script:RootPath = Join-Path -Path $TestDrive -ChildPath 'root'
        $script:ChildPath = Join-Path -Path $script:RootPath -ChildPath 'child'
        $null = New-Item -Path $script:ChildPath -ItemType Directory -Force
        $script:FirstFilePath = Join-Path -Path $script:RootPath -ChildPath 'first.txt'
        $script:NestedFilePath = Join-Path -Path $script:ChildPath -ChildPath 'nested.txt'
        [System.IO.File]::WriteAllText($script:FirstFilePath, 'first')
        [System.IO.File]::WriteAllText($script:NestedFilePath, 'nested')
    }

    It 'uses Path as the default parameter set' {
        $command = Get-Command -Name 'Get-WUFileTreeWithContent'

        $command.DefaultParameterSet | Should -Be 'Path'
    }

    It 'returns typed objects with exact text content' {
        $result = @(Get-WUFileTreeWithContent -LiteralPath $script:RootPath)

        $result | Should -HaveCount 3
        $result[0].Path | Should -Be $script:ChildPath
        $result[0].ItemType | Should -Be 'Directory'
        $result[0].Content | Should -BeNullOrEmpty
        $result[0].PSObject.TypeNames | Should -Contain 'PSWinUtil.FileTreeContent'
        $firstFile = $result | Where-Object { $_.Path -eq $script:FirstFilePath }
        $firstFile.ItemType | Should -Be 'File'
        $firstFile.Content | Should -Be 'first'
    }

    It 'uses the current location when no path is specified' {
        Push-Location -Path $script:RootPath
        try {
            $result = @(Get-WUFileTreeWithContent)
        } finally {
            Pop-Location
        }

        $result | Should -HaveCount 3
        $result.Path | Should -Contain $script:ChildPath
        $result.Path | Should -Contain $script:FirstFilePath
        $result.Path | Should -Contain $script:NestedFilePath
    }

    It 'applies minimum and maximum depth to directory inputs' {
        $depthZero = @(
            Get-WUFileTreeWithContent `
                -LiteralPath $script:RootPath `
                -MinDepth 0 `
                -MaxDepth 1
        )
        $depthTwo = @(
            Get-WUFileTreeWithContent `
                -LiteralPath $script:RootPath `
                -MinDepth 2 `
                -MaxDepth 2
        )

        $depthZero.Path | Should -Contain $script:RootPath
        $depthZero.Path | Should -Contain $script:ChildPath
        $depthZero.Path | Should -Contain $script:FirstFilePath
        $depthZero.Path | Should -Not -Contain $script:NestedFilePath
        $depthTwo | Should -HaveCount 1
        $depthTwo[0].Path | Should -Be $script:NestedFilePath
    }

    It 'always returns a directly specified file' {
        $result = Get-WUFileTreeWithContent `
            -LiteralPath $script:FirstFilePath `
            -MinDepth 10 `
            -MaxDepth 10

        $result.Path | Should -Be $script:FirstFilePath
        $result.Content | Should -Be 'first'
    }

    It 'accepts multiple pipeline paths' {
        $result = @(
            @($script:FirstFilePath, $script:NestedFilePath) |
                Get-WUFileTreeWithContent
        )

        $result | Should -HaveCount 2
        $result.Path | Should -Contain $script:FirstFilePath
        $result.Path | Should -Contain $script:NestedFilePath
    }

    It 'expands wildcard Path values' {
        $result = @(
            Get-WUFileTreeWithContent `
                -Path (Join-Path -Path $script:RootPath -ChildPath '*.txt')
        )

        $result | Should -HaveCount 1
        $result[0].Path | Should -Be $script:FirstFilePath
    }

    It 'returns null content for a binary file' {
        $binaryPath = Join-Path -Path $script:RootPath -ChildPath 'binary.dat'
        [System.IO.File]::WriteAllBytes($binaryPath, [byte[]]@(65, 0, 66))

        $result = Get-WUFileTreeWithContent -LiteralPath $binaryPath

        $result.ItemType | Should -Be 'File'
        $result.Content | Should -BeNullOrEmpty
    }

    It 'writes escaped XML fragments for all item types' {
        $escapedDirectory = Join-Path -Path $TestDrive -ChildPath 'xml&root'
        $null = New-Item -Path $escapedDirectory -ItemType Directory
        $escapedFile = Join-Path -Path $escapedDirectory -ChildPath 'a&b.txt'
        $sourceContent = '<tag value="one">''two'' & three</tag>'
        [System.IO.File]::WriteAllText($escapedFile, $sourceContent)

        $result = @(
            Get-WUFileTreeWithContent `
                -LiteralPath $escapedDirectory `
                -MinDepth 0 `
                -AsXml
        )
        [xml]$xml = $result -join [Environment]::NewLine

        $result | Should -HaveCount 4
        $result[0] | Should -Be '<documents>'
        $result[-1] | Should -Be '</documents>'
        $result[1] | Should -Match 'type="directory"'
        $result[2] | Should -Match '&amp;'
        $result[2] | Should -Match '&lt;tag'
        $result[2] | Should -Match '&quot;one&quot;'
        $result[2] | Should -Match '&apos;two&apos;'
        $xml.documents.document | Should -HaveCount 2
        $fileElement = $xml.documents.document | Where-Object { $_.type -eq 'file' }
        $fileElement.path | Should -Be $escapedFile
        $fileElement.InnerText | Should -Be $sourceContent
    }

    It 'rejects file content that XML cannot represent' {
        $invalidXmlPath = Join-Path -Path $script:RootPath -ChildPath 'invalid-xml.txt'
        $invalidXmlContent = 'before' + [char]1 + 'after'
        [System.IO.File]::WriteAllText($invalidXmlPath, $invalidXmlContent)

        {
            Get-WUFileTreeWithContent -LiteralPath $invalidXmlPath -AsXml
        } | Should -Throw
    }

    It 'writes one XML container for pipeline input' {
        $result = @(
            @($script:FirstFilePath, $script:NestedFilePath) |
                Get-WUFileTreeWithContent -AsXml
        )

        $result | Should -HaveCount 4
        $result | Where-Object { $_ -eq '<documents>' } | Should -HaveCount 1
        $result | Where-Object { $_ -eq '</documents>' } | Should -HaveCount 1
    }

    It 'rejects a missing path' {
        $missingPath = Join-Path -Path $TestDrive -ChildPath 'missing'

        { Get-WUFileTreeWithContent -LiteralPath $missingPath } | Should -Throw '*does not exist*'
    }

    It 'rejects an invalid depth range' {
        {
            Get-WUFileTreeWithContent `
                -LiteralPath $script:RootPath `
                -MinDepth 3 `
                -MaxDepth 2
        } | Should -Throw '*MinDepth*'
    }
}
