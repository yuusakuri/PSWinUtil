BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    . (Join-Path -Path $repositoryRoot -ChildPath 'dev.ps1')
    $script:SourceManifestPath = Join-Path -Path $repositoryRoot -ChildPath 'src/PSWinUtil/PSWinUtil.psd1'
}

Describe 'Set-ReleaseVersion' {
    BeforeEach {
        $script:ManifestPath = Join-Path -Path $TestDrive -ChildPath 'PSWinUtil.psd1'
        Copy-Item -LiteralPath $script:SourceManifestPath -Destination $script:ManifestPath
        $script:OriginalManifestText = [System.IO.File]::ReadAllText($script:ManifestPath)
        $script:CurrentManifest = Import-PowerShellDataFile -LiteralPath $script:ManifestPath
        $script:CurrentVersion = Get-ReleaseManifestVersion -Manifest $script:CurrentManifest
        $script:BaseVersion = [string]$script:CurrentManifest.ModuleVersion
        $script:NextVersion = "$($script:BaseVersion)-preview1"
    }

    It 'updates ModuleVersion and Prerelease for a preview version' {
        $result = Set-ReleaseVersion `
            -Version $script:NextVersion `
            -ManifestPath $script:ManifestPath

        $updatedManifest = Import-PowerShellDataFile -LiteralPath $script:ManifestPath
        [string]$updatedManifest.ModuleVersion | Should -Be $script:BaseVersion
        $updatedManifest.PrivateData.PSData.Prerelease | Should -Be 'preview1'
        $result.PreviousVersion | Should -Be $script:CurrentVersion
        $result.Version | Should -Be $script:NextVersion

        $expectedManifestText = $script:OriginalManifestText.Replace(
            "Prerelease = 'preview0'",
            "Prerelease = 'preview1'"
        )
        [System.IO.File]::ReadAllText($script:ManifestPath) | Should -BeExactly $expectedManifestText
    }

    It 'clears Prerelease for the stable version with the same base' {
        $result = Set-ReleaseVersion `
            -Version $script:BaseVersion `
            -ManifestPath $script:ManifestPath

        $updatedManifest = Import-PowerShellDataFile -LiteralPath $script:ManifestPath
        [string]$updatedManifest.ModuleVersion | Should -Be $script:BaseVersion
        $updatedManifest.PrivateData.PSData.Prerelease | Should -BeNullOrEmpty
        $result.Version | Should -Be $script:BaseVersion
    }

    It 'rejects a version that is not greater than the current version' {
        {
            Set-ReleaseVersion `
                -Version $script:CurrentVersion `
                -ManifestPath $script:ManifestPath
        } | Should -Throw '*must be greater*'

        [System.IO.File]::ReadAllText($script:ManifestPath) |
            Should -BeExactly $script:OriginalManifestText
    }

    It 'rejects a version lower than the current version' {
        {
            Set-ReleaseVersion `
                -Version '1.0.0' `
                -ManifestPath $script:ManifestPath
        } | Should -Throw '*must be greater*'

        [System.IO.File]::ReadAllText($script:ManifestPath) |
            Should -BeExactly $script:OriginalManifestText
    }

    It 'rejects an unsupported release version' -ForEach @(
        @{ Version = '2.1' }
        @{ Version = '2.1.0-preview.1' }
        @{ Version = '2.1.0-preview+1' }
        @{ Version = '2.1.0-preview-1' }
    ) {
        {
            Set-ReleaseVersion `
                -Version $Version `
                -ManifestPath $script:ManifestPath
        } | Should -Throw

        [System.IO.File]::ReadAllText($script:ManifestPath) |
            Should -BeExactly $script:OriginalManifestText
    }

    It 'does not update the manifest with WhatIf' {
        $null = Set-ReleaseVersion `
            -Version $script:NextVersion `
            -ManifestPath $script:ManifestPath `
            -WhatIf

        [System.IO.File]::ReadAllText($script:ManifestPath) |
            Should -BeExactly $script:OriginalManifestText
    }
}
