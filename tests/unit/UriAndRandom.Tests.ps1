BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $manifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
    Import-Module -Name $manifestPath -Force -ErrorAction Stop
}

Describe 'Join-WUUri' {
    It 'uses System.Uri to resolve relative segments' {
        $result = Join-WUUri -BaseUri 'https://example.test/api/v1/' -RelativeUri '../status'

        $result | Should -BeOfType ([uri])
        $result.AbsoluteUri | Should -Be 'https://example.test/api/status'
    }

    It 'rejects a relative base URI' {
        { Join-WUUri -BaseUri '/api/' -RelativeUri 'status' } | Should -Throw '*must be absolute*'
    }
}

Describe 'Convert-WUUri' {
    It 'removes only the selected URI components' {
        $withoutQuery = Convert-WUUri -Uri 'https://example.test/items?q=one#top' -WithoutQuery
        $withoutFragment = Convert-WUUri -Uri 'https://example.test/items?q=one#top' -WithoutFragment
        $withoutBoth = Convert-WUUri -Uri 'https://example.test/items?q=one#top' -WithoutQuery -WithoutFragment

        $withoutQuery.AbsoluteUri | Should -Be 'https://example.test/items#top'
        $withoutFragment.AbsoluteUri | Should -Be 'https://example.test/items?q=one'
        $withoutBoth.AbsoluteUri | Should -Be 'https://example.test/items'
    }

    It 'requires a conversion option' {
        { Convert-WUUri -Uri 'https://example.test/items' } | Should -Throw
    }
}

Describe 'New-WURandomString' {
    It 'returns the requested length and character set' {
        $result = New-WURandomString -Length 128

        $result.Length | Should -Be 128
        $result | Should -Match '^[A-Za-z0-9]+$'
    }

    It 'rejects a zero length' {
        { New-WURandomString -Length 0 } | Should -Throw
    }
}
