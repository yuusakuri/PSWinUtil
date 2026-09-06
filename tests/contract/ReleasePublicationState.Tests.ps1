BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    . (Join-Path -Path $repositoryRoot -ChildPath 'dev.ps1')
    $script:GetReleasePublicationState = $getReleasePublicationState
    $script:ReleaseCommit = '1111111111111111111111111111111111111111'
}

Describe 'dev.ps1 getReleasePublicationState' {
    It 'reports an unpublished release when nothing exists yet' {
        $state = & $script:GetReleasePublicationState `
            -TagName 'v1.2.3' `
            -Version '1.2.3' `
            -ReleaseCommit $script:ReleaseCommit

        $state.TagExists | Should -BeFalse
        $state.GalleryExists | Should -BeFalse
        $state.GitHubReleaseExists | Should -BeFalse
    }

    It 'reports a tag that already points at the release commit' {
        $state = & $script:GetReleasePublicationState `
            -TagName 'v1.2.3' `
            -Version '1.2.3' `
            -ReleaseCommit $script:ReleaseCommit `
            -TagCommit $script:ReleaseCommit

        $state.TagExists | Should -BeTrue
        $state.GalleryExists | Should -BeFalse
    }

    It 'reports a completed release so a rerun skips every publication' {
        $state = & $script:GetReleasePublicationState `
            -TagName 'v1.2.3' `
            -Version '1.2.3' `
            -ReleaseCommit $script:ReleaseCommit `
            -TagCommit $script:ReleaseCommit `
            -GalleryExists `
            -GitHubReleaseExists

        $state.TagExists | Should -BeTrue
        $state.GalleryExists | Should -BeTrue
        $state.GitHubReleaseExists | Should -BeTrue
    }

    It 'rejects a tag that points at another commit' {
        {
            & $script:GetReleasePublicationState `
                -TagName 'v1.2.3' `
                -Version '1.2.3' `
                -ReleaseCommit $script:ReleaseCommit `
                -TagCommit '2222222222222222222222222222222222222222'
        } | Should -Throw "*does not point to release commit $($script:ReleaseCommit)*"
    }

    It 'rejects a published Gallery version without its tag' {
        {
            & $script:GetReleasePublicationState `
                -TagName 'v1.2.3' `
                -Version '1.2.3' `
                -ReleaseCommit $script:ReleaseCommit `
                -GalleryExists
        } | Should -Throw '*exists without tag v1.2.3*'
    }

    It 'rejects a GitHub Release published before its tag' {
        {
            & $script:GetReleasePublicationState `
                -TagName 'v1.2.3' `
                -Version '1.2.3' `
                -ReleaseCommit $script:ReleaseCommit `
                -GitHubReleaseExists
        } | Should -Throw '*before its tag and Gallery publication are complete*'
    }

    It 'rejects a GitHub Release published before the Gallery version' {
        {
            & $script:GetReleasePublicationState `
                -TagName 'v1.2.3' `
                -Version '1.2.3' `
                -ReleaseCommit $script:ReleaseCommit `
                -TagCommit $script:ReleaseCommit `
                -GitHubReleaseExists
        } | Should -Throw '*before its tag and Gallery publication are complete*'
    }
}
