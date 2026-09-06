BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    . (Join-Path -Path $repositoryRoot -ChildPath 'dev.ps1')
    $script:GetReleaseIdentity = $getReleaseIdentity
    $script:SourceManifestPath = Join-Path -Path $repositoryRoot -ChildPath 'src/PSWinUtil/PSWinUtil.psd1'
}

Describe 'dev.ps1 getReleaseIdentity' {
    BeforeEach {
        $script:ManifestPath = Join-Path -Path $TestDrive -ChildPath 'PSWinUtil.psd1'
        Copy-Item -LiteralPath $script:SourceManifestPath -Destination $script:ManifestPath
        $script:ManifestVersion = [string](
            Import-PowerShellDataFile -LiteralPath $script:ManifestPath
        ).ModuleVersion
    }

    It 'resolves the version and tag from the release branch' {
        $identity = & $script:GetReleaseIdentity `
            -Branch "release/$($script:ManifestVersion)" `
            -ManifestPath $script:ManifestPath

        $identity.Version | Should -Be $script:ManifestVersion
        $identity.TagName | Should -Be "v$($script:ManifestVersion)"
    }

    It 'accepts a tag that already exists for the same release' {
        $identity = & $script:GetReleaseIdentity `
            -Branch "release/$($script:ManifestVersion)" `
            -ManifestPath $script:ManifestPath `
            -ExistingTagName @("v$($script:ManifestVersion)", 'v1.0.0')

        $identity.Version | Should -Be $script:ManifestVersion
    }

    It 'accepts an empty tag list' {
        $identity = & $script:GetReleaseIdentity `
            -Branch "release/$($script:ManifestVersion)" `
            -ManifestPath $script:ManifestPath `
            -ExistingTagName @()

        $identity.Version | Should -Be $script:ManifestVersion
    }

    It 'ignores tags that are not stable release tags' {
        $identity = & $script:GetReleaseIdentity `
            -Branch "release/$($script:ManifestVersion)" `
            -ManifestPath $script:ManifestPath `
            -ExistingTagName @('v9.9.9-preview', 'nightly', 'v1.0.0')

        $identity.Version | Should -Be $script:ManifestVersion
    }

    It 'rejects a branch that is not a release branch' -ForEach @(
        @{ Branch = 'master' }
        @{ Branch = 'release/1.2' }
        @{ Branch = 'release/1.2.3.4' }
        @{ Branch = 'release/01.2.3' }
        @{ Branch = 'release/1.2.3-preview' }
        @{ Branch = 'feature/release/1.2.3' }
    ) {
        {
            & $script:GetReleaseIdentity -Branch $Branch -ManifestPath $script:ManifestPath
        } | Should -Throw "Invalid release branch: $Branch"
    }

    It 'rejects a branch version that does not match ModuleVersion' {
        {
            & $script:GetReleaseIdentity `
                -Branch 'release/99.98.97' `
                -ManifestPath $script:ManifestPath
        } | Should -Throw "*does not match ModuleVersion $($script:ManifestVersion)*"
    }

    It 'rejects a version older than an existing release tag' {
        {
            & $script:GetReleaseIdentity `
                -Branch "release/$($script:ManifestVersion)" `
                -ManifestPath $script:ManifestPath `
                -ExistingTagName @('v99.0.0')
        } | Should -Throw '*is older than existing tag v99.0.0*'
    }
}
