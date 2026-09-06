BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $script:ReleaseIdentityScriptPath = Join-Path -Path $repositoryRoot -ChildPath 'scripts/Get-ReleaseIdentity.ps1'
    $script:SourceManifestPath = Join-Path -Path $repositoryRoot -ChildPath 'src/PSWinUtil/PSWinUtil.psd1'
}

Describe 'Get-ReleaseIdentity.ps1' {
    BeforeEach {
        $script:ManifestPath = Join-Path -Path $TestDrive -ChildPath 'PSWinUtil.psd1'
        Copy-Item -LiteralPath $script:SourceManifestPath -Destination $script:ManifestPath
        $script:ManifestVersion = [string](
            Import-PowerShellDataFile -LiteralPath $script:ManifestPath
        ).ModuleVersion
    }

    It 'resolves the version and tag from the release branch' {
        $identity = & $script:ReleaseIdentityScriptPath `
            -Branch "release/$($script:ManifestVersion)" `
            -ManifestPath $script:ManifestPath

        $identity.Version | Should -Be $script:ManifestVersion
        $identity.TagName | Should -Be "v$($script:ManifestVersion)"
    }

    It 'accepts a tag that already exists for the same release' {
        $identity = & $script:ReleaseIdentityScriptPath `
            -Branch "release/$($script:ManifestVersion)" `
            -ManifestPath $script:ManifestPath `
            -ExistingTagName @("v$($script:ManifestVersion)", 'v1.0.0')

        $identity.Version | Should -Be $script:ManifestVersion
    }

    It 'accepts an empty tag list' {
        $identity = & $script:ReleaseIdentityScriptPath `
            -Branch "release/$($script:ManifestVersion)" `
            -ManifestPath $script:ManifestPath `
            -ExistingTagName @()

        $identity.Version | Should -Be $script:ManifestVersion
    }

    It 'ignores tags that are not stable release tags' {
        $identity = & $script:ReleaseIdentityScriptPath `
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
            & $script:ReleaseIdentityScriptPath -Branch $Branch -ManifestPath $script:ManifestPath
        } | Should -Throw "Invalid release branch: $Branch"
    }

    It 'rejects a branch version that does not match ModuleVersion' {
        {
            & $script:ReleaseIdentityScriptPath `
                -Branch 'release/99.98.97' `
                -ManifestPath $script:ManifestPath
        } | Should -Throw "*does not match ModuleVersion $($script:ManifestVersion)*"
    }

    It 'rejects a version older than an existing release tag' {
        {
            & $script:ReleaseIdentityScriptPath `
                -Branch "release/$($script:ManifestVersion)" `
                -ManifestPath $script:ManifestPath `
                -ExistingTagName @('v99.0.0')
        } | Should -Throw '*is older than existing tag v99.0.0*'
    }
}
