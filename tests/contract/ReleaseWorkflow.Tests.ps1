BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    . (Join-Path -Path $repositoryRoot -ChildPath 'dev.ps1')
    Import-RequiredModule -Name 'Microsoft.PowerShell.PSResourceGet'
    $script:ReleaseCommit = '1111111111111111111111111111111111111111'
}

Describe 'Release publication queries' {
    BeforeEach {
        Mock Import-RequiredModule {}
        Mock Get-RequiredApplication { $Name }
        Mock Invoke-ExternalCommand { '[[]]' }
    }

    It 'reports a Gallery version that exists' {
        Mock Find-PSResource { [pscustomobject]@{ Version = [version]'1.2.3' } }

        Test-GalleryPublication -Version '1.2.3' | Should -BeTrue
        Should -Invoke Find-PSResource -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'PSWinUtil' -and $Version -eq '[1.2.3]' -and
            $Repository -eq 'PSGallery' -and $ErrorAction -eq 'Stop'
        }
    }

    It 'accepts only the Gallery package-not-found error as unpublished' {
        Mock Find-PSResource {
            throw [System.Management.Automation.ErrorRecord]::new(
                [InvalidOperationException]::new('Package is absent.'),
                'PackageNotFound,Microsoft.PowerShell.PSResourceGet.Cmdlets.FindPSResource',
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                'PSWinUtil'
            )
        }

        Test-GalleryPublication -Version '1.2.3' | Should -BeFalse
    }

    It 'propagates Gallery failures even if they are categorized as not found' -ForEach @(
        @{ ErrorId = 'HttpRequestFailed'; Message = 'Connection failed.' }
        @{ ErrorId = 'ResourceNotFound'; Message = 'Repository endpoint returned HTTP 404.' }
        @{ ErrorId = 'FindVersionConvertToPSResourceFailure'; Message = 'Invalid Gallery response.' }
    ) {
        Mock Find-PSResource {
            throw [System.Management.Automation.ErrorRecord]::new(
                [InvalidOperationException]::new($Message),
                $ErrorId,
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                'PSGallery'
            )
        }

        { Test-GalleryPublication -Version '1.2.3' } | Should -Throw "*$Message*"
    }

    It 'reports an absent GitHub release after a successful complete query' {
        Test-GitHubRelease -GhPath 'gh' -TagName 'v1.2.3' | Should -BeFalse
        Should -Invoke Invoke-ExternalCommand -Times 1 -Exactly -ParameterFilter {
            $ArgumentList -contains '--paginate' -and $ArgumentList -contains '--slurp'
        }
    }

    It 'finds a GitHub release beyond the first page' {
        Mock Invoke-ExternalCommand {
            '[[{"tag_name":"v1.2.4","draft":false}],[{"tag_name":"v1.2.3","draft":false}]]'
        }

        Test-GitHubRelease -GhPath 'gh' -TagName 'v1.2.3' | Should -BeTrue
    }

    It 'rejects an unpublished GitHub draft' {
        Mock Invoke-ExternalCommand { '[[{"tag_name":"v1.2.3","draft":true}]]' }

        { Test-GitHubRelease -GhPath 'gh' -TagName 'v1.2.3' } | Should -Throw '*is a draft*'
    }

    It 'propagates GitHub authentication and API failures' {
        Mock Invoke-ExternalCommand { throw 'GitHub query failed.' }

        { Test-GitHubRelease -GhPath 'gh' -TagName 'v1.2.3' } | Should -Throw '*GitHub query failed*'
    }

    It 'rejects malformed GitHub responses' {
        Mock Invoke-ExternalCommand { 'not JSON' }

        { Test-GitHubRelease -GhPath 'gh' -TagName 'v1.2.3' } | Should -Throw
    }

    It 'uses the remote annotated tag commit to recognize a resumable publication' {
        Mock Invoke-ExternalCommand {
            "2222222222222222222222222222222222222222`trefs/tags/v1.2.3"
            "$($script:ReleaseCommit)`trefs/tags/v1.2.3^{}"
        }
        Mock Test-GalleryPublication { $false }
        Mock Test-GitHubRelease { $false }

        $state = Get-RemoteReleaseState -ReleaseCommit $script:ReleaseCommit -Version '1.2.3'

        $state.TagExists | Should -BeTrue
        Should -Invoke Invoke-ExternalCommand -Times 1 -Exactly -ParameterFilter {
            $ArgumentList[0] -eq 'ls-remote' -and $ArgumentList -contains 'origin'
        }
    }

    It 'does not treat a local-only tag as a published remote tag' {
        Mock Invoke-ExternalCommand {}
        Mock Test-GalleryPublication { $false }
        Mock Test-GitHubRelease { $false }

        $state = Get-RemoteReleaseState -ReleaseCommit $script:ReleaseCommit -Version '1.2.3'

        $state.TagExists | Should -BeFalse
    }

    It 'waits for a missing Gallery version to appear' {
        $script:Attempts = 0
        Mock Test-GalleryPublication { (++$script:Attempts) -eq 2 }
        Mock Start-Sleep {}

        Wait-GalleryPublication -Version '1.2.3' -MaximumAttempt 2

        Should -Invoke Test-GalleryPublication -Times 2 -Exactly
        Should -Invoke Start-Sleep -Times 1 -Exactly
    }

    It 'stops the publication wait when the Gallery cannot be queried' {
        Mock Test-GalleryPublication { throw 'TLS connection failed.' }
        Mock Start-Sleep {}

        { Wait-GalleryPublication -Version '1.2.3' } | Should -Throw '*TLS connection failed*'
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }

    It 'does not sleep after the final unsuccessful Gallery query' {
        Mock Test-GalleryPublication { $false }
        Mock Start-Sleep {}

        { Wait-GalleryPublication -Version '1.2.3' -MaximumAttempt 2 } | Should -Throw '*did not expose*'
        Should -Invoke Start-Sleep -Times 1 -Exactly
    }
}

Describe 'Invoke-ReleasePublish' {
    BeforeEach {
        $script:SavedApiKey = $env:PSGALLERY_API_KEY
        $env:PSGALLERY_API_KEY = 'test-key'
        $script:PublicationEvents = [System.Collections.Generic.List[string]]::new()
        $script:PublishArguments = @{
            ReleaseCommit = $script:ReleaseCommit
            Version = '1.2.3'
            State = Get-ReleasePublicationState -TagName 'v1.2.3' -Version '1.2.3' -ReleaseCommit $script:ReleaseCommit
            ModuleDirectory = $TestDrive
            ArtifactPath = Join-Path -Path $TestDrive -ChildPath 'PSWinUtil-1.2.3.zip'
        }
        $manifestPath = Join-Path -Path $TestDrive -ChildPath 'PSWinUtil.psd1'
        New-ModuleManifest -Path $manifestPath -ModuleVersion '1.2.3'
        [System.IO.File]::WriteAllText($script:PublishArguments.ArtifactPath, 'original archive')
        Mock Get-RequiredApplication { $Name }
        Mock Import-RequiredModule {}
        Mock Invoke-ReleasePack { $script:PublicationEvents.Add('pack') }
        Mock Publish-PSResource {
            $script:PublicationEvents.Add('gallery')
            'publisher output'
        }
        Mock Wait-GalleryPublication { $script:PublicationEvents.Add('wait') }
        Mock Invoke-ExternalCommand {
            if ($ArgumentList -contains '--list') { return }
            $script:PublicationEvents.Add($ArgumentList[0])
        }
    }

    AfterEach {
        $env:PSGALLERY_API_KEY = $script:SavedApiKey
    }

    It 'honors WhatIf without requiring a key or modifying the artifact' {
        $env:PSGALLERY_API_KEY = ''

        $result = Invoke-ReleasePublish @script:PublishArguments -WhatIf

        $result | Should -BeNullOrEmpty
        $script:PublicationEvents.Count | Should -Be 0
        [System.IO.File]::ReadAllText($script:PublishArguments.ArtifactPath) | Should -BeExactly 'original archive'
    }

    It 'checks the credential before creating the archive or tag' {
        $env:PSGALLERY_API_KEY = ''

        { Invoke-ReleasePublish @script:PublishArguments -Confirm:$false } | Should -Throw '*PSGALLERY_API_KEY*'
        $script:PublicationEvents.Count | Should -Be 0
    }

    It 'publishes in order and returns exactly one structured result' {
        $results = @(Invoke-ReleasePublish @script:PublishArguments -Confirm:$false)

        ($script:PublicationEvents -join ',') | Should -BeExactly 'pack,tag,push,gallery,wait,release'
        $results.Count | Should -Be 1
        $results[0].Version | Should -Be '1.2.3'
        $results[0].ArtifactPath | Should -Be $script:PublishArguments.ArtifactPath
    }

    It 'reuses a matching local tag after a failed push' {
        Mock Invoke-ExternalCommand { 'v1.2.3' } -ParameterFilter { $ArgumentList -contains '--list' }
        Mock Invoke-ExternalCommand { $script:ReleaseCommit } -ParameterFilter { $ArgumentList[0] -eq 'rev-parse' }

        $null = Invoke-ReleasePublish @script:PublishArguments -Confirm:$false

        ($script:PublicationEvents -join ',') | Should -BeExactly 'pack,push,gallery,wait,release'
    }

    It 'rejects a local tag on a different commit even with WhatIf' {
        Mock Invoke-ExternalCommand { 'v1.2.3' } -ParameterFilter { $ArgumentList -contains '--list' }
        Mock Invoke-ExternalCommand { '2222222222222222222222222222222222222222' } -ParameterFilter {
            $ArgumentList[0] -eq 'rev-parse'
        }

        { Invoke-ReleasePublish @script:PublishArguments -WhatIf } | Should -Throw '*Local tag*does not point*'
        $script:PublicationEvents.Count | Should -Be 0
    }

    It 'does not publish to Gallery after a tag push failure' {
        Mock Invoke-ExternalCommand { throw 'Push failed.' } -ParameterFilter { $ArgumentList[0] -eq 'push' }

        { Invoke-ReleasePublish @script:PublishArguments -Confirm:$false } | Should -Throw '*Push failed*'
        Should -Invoke Publish-PSResource -Times 0 -Exactly
    }

    It 'does not create a GitHub Release before Gallery confirmation' {
        Mock Wait-GalleryPublication { throw 'Gallery unavailable.' }

        { Invoke-ReleasePublish @script:PublishArguments -Confirm:$false } | Should -Throw '*Gallery unavailable*'
        Should -Invoke Invoke-ExternalCommand -Times 0 -Exactly -ParameterFilter { $ArgumentList[0] -eq 'release' }
    }

    It 'resumes after Gallery publication without a credential or duplicate publish' {
        $env:PSGALLERY_API_KEY = ''
        $script:PublishArguments.State = Get-ReleasePublicationState `
            -TagName 'v1.2.3' -Version '1.2.3' -ReleaseCommit $script:ReleaseCommit `
            -TagCommit $script:ReleaseCommit -GalleryExists

        $null = Invoke-ReleasePublish @script:PublishArguments -Confirm:$false

        ($script:PublicationEvents -join ',') | Should -BeExactly 'pack,release'
    }

    It 'skips a completed publication and returns no artifact for attestation' {
        $script:PublishArguments.State = Get-ReleasePublicationState `
            -TagName 'v1.2.3' -Version '1.2.3' -ReleaseCommit $script:ReleaseCommit `
            -TagCommit $script:ReleaseCommit -GalleryExists -GitHubReleaseExists

        $results = @(Invoke-ReleasePublish @script:PublishArguments -Confirm:$false)

        $results.Count | Should -Be 1
        $results[0].ArtifactPath | Should -Be ''
        $script:PublicationEvents.Count | Should -Be 0
    }

    It 'rejects an artifact built with a different version even with WhatIf' {
        $script:PublishArguments.Version = '1.2.4'

        { Invoke-ReleasePublish @script:PublishArguments -WhatIf } | Should -Throw '*does not match the release version*'
        $script:PublicationEvents.Count | Should -Be 0
    }
}

Describe 'Release checkout validation' {
    BeforeEach {
        Mock Get-RequiredApplication { $Name }
        Mock Invoke-ExternalCommand {
            if ($ArgumentList[0] -eq 'rev-parse') { $script:ReleaseCommit }
        }
        Mock Get-ReleaseManifest { @{ ModuleVersion = '1.2.3' } }
        Mock Get-RemoteReleaseState {
            Get-ReleasePublicationState -TagName 'v1.2.3' -Version '1.2.3' -ReleaseCommit $script:ReleaseCommit
        }
        Mock Invoke-ReleasePublish {}
    }

    It 'uses the committed manifest version and explicitly refreshes origin/master' {
        Mock Invoke-ReleasePublish {
            $WhatIfPreference | Should -BeTrue
        }
        Invoke-Release -ReleaseCommit $script:ReleaseCommit -Branch 'release/1.2.3' -WhatIf

        Should -Invoke Invoke-ExternalCommand -Times 1 -Exactly -ParameterFilter {
            $ArgumentList[0] -eq 'fetch' -and
            $ArgumentList -contains '+refs/heads/master:refs/remotes/origin/master'
        }
        Should -Invoke Get-ReleaseManifest -Times 1 -Exactly -ParameterFilter {
            $ReleaseCommit -eq $script:ReleaseCommit
        }
        Should -Invoke Invoke-ReleasePublish -Times 1 -Exactly -ParameterFilter { $Version -eq '1.2.3' }
    }

    It 'rejects a checkout on a different commit' {
        Mock Invoke-ExternalCommand { '2222222222222222222222222222222222222222' } -ParameterFilter {
            $ArgumentList[0] -eq 'rev-parse'
        }

        { Invoke-Release -ReleaseCommit $script:ReleaseCommit -Branch 'release/1.2.3' } | Should -Throw '*does not match release commit*'
        Should -Invoke Invoke-ReleasePublish -Times 0 -Exactly
    }

    It 'rejects a nonexistent commit object' {
        Mock Invoke-ExternalCommand { throw 'Unknown commit.' } -ParameterFilter { $ArgumentList[0] -eq 'cat-file' }

        { Invoke-Release -ReleaseCommit $script:ReleaseCommit -Branch 'release/1.2.3' } | Should -Throw '*Unknown commit*'
        Should -Invoke Get-RemoteReleaseState -Times 0 -Exactly
    }

    It 'rejects a commit outside origin/master' {
        Mock Invoke-ExternalCommand { throw 'Not an ancestor.' } -ParameterFilter { $ArgumentList[0] -eq 'merge-base' }

        { Invoke-Release -ReleaseCommit $script:ReleaseCommit -Branch 'release/1.2.3' } | Should -Throw '*Not an ancestor*'
        Should -Invoke Invoke-ReleasePublish -Times 0 -Exactly
    }

    It 'rejects modified or untracked source files' -ForEach @(
        @{ GitCommand = 'status' }
        @{ GitCommand = 'ls-files' }
    ) {
        Mock Invoke-ExternalCommand { 'src/PSWinUtil/Public/Example.ps1' } -ParameterFilter {
            $ArgumentList[0] -eq $GitCommand
        }

        { Invoke-Release -ReleaseCommit $script:ReleaseCommit -Branch 'release/1.2.3' -WhatIf } | Should -Throw '*uncommitted changes*'
        Should -Invoke Invoke-ReleasePublish -Times 0 -Exactly
    }

    It 'rejects a branch version that differs from the committed manifest' {
        { Invoke-Release -ReleaseCommit $script:ReleaseCommit -Branch 'release/1.2.4' -WhatIf } | Should -Throw '*does not match ModuleVersion*'
        Should -Invoke Get-RemoteReleaseState -Times 0 -Exactly
    }

    It 'does not publish when state inspection fails' {
        Mock Get-RemoteReleaseState { throw 'Remote service unavailable.' }

        { Invoke-Release -ReleaseCommit $script:ReleaseCommit -Branch 'release/1.2.3' } | Should -Throw '*Remote service unavailable*'
        Should -Invoke Invoke-ReleasePublish -Times 0 -Exactly
    }
}

Describe 'Committed release manifest' {
    It 'reads the version from the requested commit' {
        Mock Invoke-ExternalCommand { "@{ ModuleVersion = '1.2.3' }" }

        $manifest = Get-ReleaseManifest -GitPath 'git' -ReleaseCommit $script:ReleaseCommit

        $manifest.ModuleVersion | Should -Be '1.2.3'
        Should -Invoke Invoke-ExternalCommand -Times 1 -Exactly -ParameterFilter {
            $ArgumentList[0] -eq 'show' -and
            $ArgumentList[1] -eq "$($script:ReleaseCommit):src/PSWinUtil/PSWinUtil.psd1"
        }
    }

    It 'rejects a manifest without a version' {
        Mock Invoke-ExternalCommand { "@{ Description = 'No version' }" }

        { Get-ReleaseManifest -GitPath 'git' -ReleaseCommit $script:ReleaseCommit } | Should -Throw '*does not define ModuleVersion*'
    }

    It 'rejects executable manifest contents without running them' {
        Mock Invoke-ExternalCommand { "@{ ModuleVersion = (Invoke-ReleasePack -ModuleDirectory x -ArtifactPath y) }" }
        Mock Invoke-ReleasePack { throw 'Manifest command was executed.' }

        { Get-ReleaseManifest -GitPath 'git' -ReleaseCommit $script:ReleaseCommit } | Should -Throw
        Should -Invoke Invoke-ReleasePack -Times 0 -Exactly
    }

    It 'rejects more than one data table' {
        Mock Invoke-ExternalCommand { "@{ ModuleVersion = '1.2.3' }; @{ ModuleVersion = '1.2.4' }" }

        { Get-ReleaseManifest -GitPath 'git' -ReleaseCommit $script:ReleaseCommit } | Should -Throw '*one data table*'
    }
}

Describe 'Invoke-Bump WhatIf' {
    BeforeEach {
        Mock Get-RequiredApplication { $Name }
        Mock Invoke-ExternalCommand {}
        Mock Set-ReleaseVersion { throw 'Version must not be written.' }
    }

    It 'does not write, commit, push, or create a pull request' {
        $currentVersion = [version](Import-PowerShellDataFile -LiteralPath $sourceManifestPath).ModuleVersion
        $nextVersion = [version]::new($currentVersion.Major, ($currentVersion.Minor + 1), 0).ToString()

        Invoke-Bump -Version $nextVersion -WhatIf

        Should -Invoke Set-ReleaseVersion -Times 0 -Exactly
        Should -Invoke Invoke-ExternalCommand -Times 0 -Exactly -ParameterFilter {
            $ArgumentList[0] -in @('switch', 'add', 'commit', 'push', 'pr')
        }
    }

    It 'validates version ordering even with WhatIf' {
        { Invoke-Bump -Version '0.0.0' -WhatIf } | Should -Throw '*must be greater*'
    }
}
