$runAndroidIntegration = $env:PSWINUTIL_RUN_ANDROID_INTEGRATION -eq '1'

BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')
}

Describe 'Android SDK selected Command-Line Tools integration' -Tag @('Android', 'AndroidSdk') -Skip:(-not $runAndroidIntegration) {
    BeforeAll {
        # The workflow already supplies Android CLI. Exercise actual SDK installation
        # without installing WinGet packages or persisting runner environment settings.
        Mock -CommandName Install-WUWingetPackage -ModuleName PSWinUtil
        Mock -CommandName Update-WUProcessEnvironment -ModuleName PSWinUtil
        Mock -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil
        $script:SavedSdkInstallPath = $env:Path
        Mock -CommandName Add-WUPathEnvironmentVariable -ModuleName PSWinUtil -MockWith {
            $expandedPaths = @($Path | ForEach-Object { [Environment]::ExpandEnvironmentVariables($_) })
            $env:Path = ($expandedPaths -join ';') + ';' + $script:SavedSdkInstallPath
        }
    }

    AfterAll {
        $env:Path = $script:SavedSdkInstallPath
    }

    It 'installs versioned Command-Line Tools and a pinned SDK Platform revision' {
        Install-WUAndroidSdk -PlatformVersion 29 -PlatformPackageVersion '5.0.0' -BuildToolsVersion '36.0.0' -CommandLineToolsVersion '22.0' | Out-Null

        $toolsDirectory = Join-Path $env:PSWINUTIL_ANDROID_TEST_SDK 'cmdline-tools/22.0'
        [IO.File]::ReadAllText((Join-Path $toolsDirectory 'source.properties')) |
            Should -Match '(?m)^Pkg.Revision\s*=\s*22(?:\.0){0,2}\s*$'
        (Get-Command -Name avdmanager.bat).Path | Should -Be (Join-Path $toolsDirectory 'bin/avdmanager.bat')
        $profiles = @(& avdmanager.bat list device -c)
        $LASTEXITCODE | Should -Be 0
        $profiles | Should -Contain 'pixel_8'
    }
}
