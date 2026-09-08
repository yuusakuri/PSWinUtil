BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    . (Join-Path -Path $repositoryRoot -ChildPath 'dev.ps1')
    $script:SourceManifestPath = Join-Path -Path $repositoryRoot -ChildPath 'src/PSWinUtil/PSWinUtil.psd1'
}

Describe 'Get-ReleaseIdentity' {
    BeforeEach {
        $script:ManifestPath = Join-Path -Path $TestDrive -ChildPath 'PSWinUtil.psd1'
        Copy-Item -LiteralPath $script:SourceManifestPath -Destination $script:ManifestPath
        $script:ManifestVersion = Get-ReleaseManifestVersion -Manifest (
            Import-PowerShellDataFile -LiteralPath $script:ManifestPath
        )
    }

    It 'resolves the version and tag from the release branch' {
        $identity = Get-ReleaseIdentity `
            -Branch "release/$($script:ManifestVersion)" `
            -ManifestPath $script:ManifestPath

        $identity.Version | Should -Be $script:ManifestVersion
        $identity.TagName | Should -Be "v$($script:ManifestVersion)"
        $identity.IsPrerelease | Should -BeTrue
        $identity.Prerelease | Should -Be 'preview0'
    }

    It 'accepts a tag that already exists for the same release' {
        $identity = Get-ReleaseIdentity `
            -Branch "release/$($script:ManifestVersion)" `
            -ManifestPath $script:ManifestPath `
            -ExistingTagName @("v$($script:ManifestVersion)", 'v1.0.0')

        $identity.Version | Should -Be $script:ManifestVersion
    }

    It 'accepts an empty tag list' {
        $identity = Get-ReleaseIdentity `
            -Branch "release/$($script:ManifestVersion)" `
            -ManifestPath $script:ManifestPath `
            -ExistingTagName @()

        $identity.Version | Should -Be $script:ManifestVersion
    }

    It 'ignores tags that are not supported release tags' {
        $identity = Get-ReleaseIdentity `
            -Branch "release/$($script:ManifestVersion)" `
            -ManifestPath $script:ManifestPath `
            -ExistingTagName @('v9.9.9-preview.1', 'v09.9.9', 'nightly', 'v1.0.0')

        $identity.Version | Should -Be $script:ManifestVersion
    }

    It 'rejects a branch that is not a release branch' -ForEach @(
        @{ Branch = 'master' }
        @{ Branch = 'release/1.2' }
        @{ Branch = 'release/1.2.3.4' }
        @{ Branch = 'release/01.2.3' }
        @{ Branch = 'release/1.2.3-preview.1' }
        @{ Branch = 'release/1.2.3-preview-1' }
        @{ Branch = 'feature/release/1.2.3' }
    ) {
        {
            Get-ReleaseIdentity -Branch $Branch -ManifestPath $script:ManifestPath
        } | Should -Throw "Invalid release branch: $Branch"
    }

    It 'rejects a branch version that does not match the manifest version' {
        {
            Get-ReleaseIdentity `
                -Branch 'release/99.98.97' `
                -ManifestPath $script:ManifestPath
        } | Should -Throw "*does not match manifest version $($script:ManifestVersion)*"
    }

    It 'rejects a version older than an existing release tag' {
        {
            Get-ReleaseIdentity `
                -Branch "release/$($script:ManifestVersion)" `
                -ManifestPath $script:ManifestPath `
                -ExistingTagName @('v99.0.0')
        } | Should -Throw '*is older than existing tag v99.0.0*'
    }

    It 'treats a stable version as newer than its preview' {
        $identity = Get-ReleaseIdentity `
            -Branch 'release/2.0.0' `
            -ManifestVersion '2.0.0' `
            -ExistingTagName @('v2.0.0-preview9')

        $identity.Version | Should -Be '2.0.0'
        $identity.IsPrerelease | Should -BeFalse
    }

    It 'rejects a preview older than an existing preview' {
        {
            Get-ReleaseIdentity `
                -Branch 'release/2.0.0-preview1' `
                -ManifestVersion '2.0.0-preview1' `
                -ExistingTagName @('v2.0.0-preview2')
        } | Should -Throw '*is older than existing tag v2.0.0-preview2*'
    }
}
