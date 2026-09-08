BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    . (Join-Path -Path $repositoryRoot -ChildPath 'dev.ps1')
    $script:Utf8 = [System.Text.UTF8Encoding]::new($false)
}

Describe 'Command reference generation' {
    BeforeEach {
        $script:FixtureName = 'ReferenceFixture' + [guid]::NewGuid().ToString('N')
        $fixtureDirectory = Join-Path -Path $TestDrive -ChildPath $script:FixtureName
        $null = New-Item -Path $fixtureDirectory -ItemType Directory
        $script:FixtureModulePath = Join-Path -Path $fixtureDirectory -ChildPath "$($script:FixtureName).psm1"
        $script:FixtureManifestPath = Join-Path -Path $fixtureDirectory -ChildPath "$($script:FixtureName).psd1"
        $script:ReferencePath = Join-Path -Path $fixtureDirectory -ChildPath 'commands.md'
        $script:FixtureSource = @'
function Get-Zulu {
    <#
    .SYNOPSIS
    Gets the last item.
    #>
}
function Get-Alpha {
    <#
    .SYNOPSIS
    Gets the first | item.
    Continues on another line.
    #>
}
function Get-Hidden {
    <#
    .SYNOPSIS
    Gets an internal item.
    #>
}
Export-ModuleMember -Function Get-Zulu, Get-Alpha
'@
        [System.IO.File]::WriteAllText($script:FixtureModulePath, $script:FixtureSource, $script:Utf8)
        New-ModuleManifest `
            -Path $script:FixtureManifestPath `
            -RootModule "$($script:FixtureName).psm1" `
            -ModuleVersion '1.0.0' `
            -FunctionsToExport 'Get-Zulu', 'Get-Alpha'
    }

    AfterEach {
        Get-Module -Name $script:FixtureName -All | Remove-Module -Force
    }

    It 'renders only exported commands in ordinal order with escaped summaries' {
        $reference = Get-CommandReference -ManifestPath $script:FixtureManifestPath
        $rows = @($reference -split "`n" | Where-Object { $_ -match '^\| `Get-' })

        $rows | Should -HaveCount 2
        $rows[0] | Should -BeExactly '| `Get-Alpha` | Gets the first &#124; item.<br>Continues on another line. |'
        $rows[1] | Should -BeExactly '| `Get-Zulu` | Gets the last item. |'
        $reference | Should -Not -Match 'Get-Hidden'
        $reference | Should -Not -Match "`r"
        Get-CommandReference -ManifestPath $script:FixtureManifestPath |
            Should -BeExactly $reference
    }

    It 'uses the requested manifest when another version is already loaded' {
        $olderDirectory = Join-Path -Path $TestDrive -ChildPath 'older'
        $null = New-Item -Path $olderDirectory -ItemType Directory
        $olderModulePath = Join-Path -Path $olderDirectory -ChildPath "$($script:FixtureName).psm1"
        [System.IO.File]::WriteAllText(
            $olderModulePath,
            $script:FixtureSource.Replace('Gets the last item.', 'Gets an old item.'),
            $script:Utf8
        )
        Import-Module -Name $olderModulePath -Global -Force

        $reference = Get-CommandReference -ManifestPath $script:FixtureManifestPath

        $reference | Should -Match 'Gets the last item\.'
        $reference | Should -Not -Match 'Gets an old item\.'
    }

    It 'excludes session functions that are outside the module exports' {
        $sessionFunction = @'

Set-Item -Path 'Function:global:Get-Placed' -Value {
    <#
    .SYNOPSIS
    Gets a session item.
    #>
}
'@
        [System.IO.File]::WriteAllText(
            $script:FixtureModulePath,
            $script:FixtureSource + $sessionFunction,
            $script:Utf8
        )

        try {
            $reference = Get-CommandReference -ManifestPath $script:FixtureManifestPath
            $reference | Should -Not -Match 'Get-Placed'
            $reference | Should -Match 'Get-Alpha'
        } finally {
            Remove-Item -LiteralPath 'Function:Get-Placed' -ErrorAction SilentlyContinue
        }
    }

    It 'rejects missing or empty comment-based help' -TestCases @(
        @{ Source = 'function Get-Alpha {}' }
        @{ Source = "function Get-Alpha { <#`n.SYNOPSIS`n `n#>`n}" }
    ) {
        param($Source)

        [System.IO.File]::WriteAllText($script:FixtureModulePath, $Source, $script:Utf8)
        [System.IO.File]::WriteAllText($script:ReferencePath, 'existing reference', $script:Utf8)

        {
            Update-CommandReference -ManifestPath $script:FixtureManifestPath -Path $script:ReferencePath
        } | Should -Throw '*Comment-based Synopsis is required*'
        [System.IO.File]::ReadAllText($script:ReferencePath) | Should -BeExactly 'existing reference'
    }

    It 'writes UTF-8 without BOM and preserves matching output during checks' {
        $source = $script:FixtureSource.Replace('Gets the last item.', "Gets caf$([char]0xE9).")
        [System.IO.File]::WriteAllText(
            $script:FixtureModulePath,
            $source,
            [System.Text.UTF8Encoding]::new($true)
        )
        Update-CommandReference -ManifestPath $script:FixtureManifestPath -Path $script:ReferencePath
        $reference = Get-CommandReference -ManifestPath $script:FixtureManifestPath
        $actualBytes = [System.IO.File]::ReadAllBytes($script:ReferencePath)
        [System.Linq.Enumerable]::SequenceEqual($actualBytes, $script:Utf8.GetBytes($reference)) |
            Should -BeTrue
        [System.Net.WebUtility]::HtmlDecode($reference) | Should -Match "caf$([char]0xE9)"
        $originalTime = [datetime]::new(2000, 1, 1, 0, 0, 0, [DateTimeKind]::Utc)
        [System.IO.File]::SetLastWriteTimeUtc($script:ReferencePath, $originalTime)

        Update-CommandReference -ManifestPath $script:FixtureManifestPath -Path $script:ReferencePath -Check

        [System.IO.File]::GetLastWriteTimeUtc($script:ReferencePath) | Should -Be $originalTime
    }

    It 'rejects a missing reference during checks' {
        {
            Update-CommandReference -ManifestPath $script:FixtureManifestPath -Path $script:ReferencePath -Check
        } | Should -Throw '*out of date*'
        Test-Path -LiteralPath $script:ReferencePath | Should -BeFalse
    }

    It 'detects a synopsis change after the module has already been imported' {
        Update-CommandReference -ManifestPath $script:FixtureManifestPath -Path $script:ReferencePath
        $updatedSource = $script:FixtureSource.Replace('Gets the last item.', 'Gets the updated item.')
        [System.IO.File]::WriteAllText($script:FixtureModulePath, $updatedSource, $script:Utf8)

        {
            Update-CommandReference -ManifestPath $script:FixtureManifestPath -Path $script:ReferencePath -Check
        } | Should -Throw '*out of date*'

        Update-CommandReference -ManifestPath $script:FixtureManifestPath -Path $script:ReferencePath
        [System.IO.File]::ReadAllText($script:ReferencePath) | Should -Match 'Gets the updated item\.'
    }

    It 'rejects stale content and byte differences without rewriting the file' -TestCases @(
        @{ Difference = 'Synopsis' }
        @{ Difference = 'Command' }
        @{ Difference = 'CRLF' }
        @{ Difference = 'BOM' }
    ) {
        param($Difference)

        $reference = Get-CommandReference -ManifestPath $script:FixtureManifestPath
        $bytes = switch ($Difference) {
            'Synopsis' { $script:Utf8.GetBytes($reference.Replace('Gets the last item.', 'Outdated summary.')) }
            'Command' { $script:Utf8.GetBytes($reference.Replace('Get-Zulu', 'Get-Other')) }
            'CRLF' { $script:Utf8.GetBytes($reference.Replace("`n", "`r`n")) }
            'BOM' { [byte[]](0xEF, 0xBB, 0xBF) + $script:Utf8.GetBytes($reference) }
        }
        [System.IO.File]::WriteAllBytes($script:ReferencePath, [byte[]]$bytes)

        {
            Update-CommandReference -ManifestPath $script:FixtureManifestPath -Path $script:ReferencePath -Check
        } | Should -Throw '*out of date*'
        [System.Linq.Enumerable]::SequenceEqual(
            [System.IO.File]::ReadAllBytes($script:ReferencePath),
            [byte[]]$bytes
        ) | Should -BeTrue
    }
}

Describe 'Built command reference' {
    It 'matches the exported commands and their help' {
        $manifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
        $referencePath = Join-Path -Path $repositoryRoot -ChildPath 'docs/reference/commands.md'

        Update-CommandReference -ManifestPath $manifestPath -Path $referencePath -Check
    }
}
