BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $script:ReleaseVersionScriptPath = Join-Path -Path $repositoryRoot -ChildPath 'scripts/Set-ReleaseVersion.ps1'
    $script:SourceManifestPath = Join-Path -Path $repositoryRoot -ChildPath 'src/PSWinUtil/PSWinUtil.psd1'
}

Describe 'Set-ReleaseVersion.ps1' {
    BeforeEach {
        $script:ManifestPath = Join-Path -Path $TestDrive -ChildPath 'PSWinUtil.psd1'
        Copy-Item -LiteralPath $script:SourceManifestPath -Destination $script:ManifestPath
        $script:OriginalManifestText = [System.IO.File]::ReadAllText($script:ManifestPath)
        $script:CurrentVersion = [version](
            Import-PowerShellDataFile -LiteralPath $script:ManifestPath
        ).ModuleVersion
        $script:NextVersion = [version]::new(
            $script:CurrentVersion.Major,
            ($script:CurrentVersion.Minor + 1),
            0
        ).ToString()
    }

    It 'updates only ModuleVersion to a greater stable version' {
        $result = & $script:ReleaseVersionScriptPath `
            -Version $script:NextVersion `
            -ManifestPath $script:ManifestPath

        $updatedManifest = Import-PowerShellDataFile -LiteralPath $script:ManifestPath
        [string]$updatedManifest.ModuleVersion | Should -Be $script:NextVersion
        $result.PreviousVersion | Should -Be $script:CurrentVersion.ToString()
        $result.Version | Should -Be $script:NextVersion

        $expectedManifestText = $script:OriginalManifestText.Replace(
            "ModuleVersion = '$($script:CurrentVersion)'",
            "ModuleVersion = '$($script:NextVersion)'"
        )
        [System.IO.File]::ReadAllText($script:ManifestPath) | Should -BeExactly $expectedManifestText
    }

    It 'rejects a version that is not greater than the current version' {
        {
            & $script:ReleaseVersionScriptPath `
                -Version $script:CurrentVersion.ToString() `
                -ManifestPath $script:ManifestPath
        } | Should -Throw '*must be greater*'

        [System.IO.File]::ReadAllText($script:ManifestPath) |
            Should -BeExactly $script:OriginalManifestText
    }

    It 'rejects a version lower than the current version' {
        {
            & $script:ReleaseVersionScriptPath `
                -Version '1.0.0' `
                -ManifestPath $script:ManifestPath
        } | Should -Throw '*must be greater*'

        [System.IO.File]::ReadAllText($script:ManifestPath) |
            Should -BeExactly $script:OriginalManifestText
    }

    It 'rejects a version outside the major.minor.patch format' {
        {
            & $script:ReleaseVersionScriptPath `
                -Version '2.1' `
                -ManifestPath $script:ManifestPath
        } | Should -Throw

        [System.IO.File]::ReadAllText($script:ManifestPath) |
            Should -BeExactly $script:OriginalManifestText
    }

    It 'does not update the manifest with WhatIf' {
        $null = & $script:ReleaseVersionScriptPath `
            -Version $script:NextVersion `
            -ManifestPath $script:ManifestPath `
            -WhatIf

        [System.IO.File]::ReadAllText($script:ManifestPath) |
            Should -BeExactly $script:OriginalManifestText
    }
}
