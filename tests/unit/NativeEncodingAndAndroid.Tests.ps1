BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $manifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
    Import-Module -Name $manifestPath -Force -ErrorAction Stop
}

Describe 'Set-WUNativeCommandEncoding' {
    BeforeEach {
        $script:SavedInputEncoding = [Console]::InputEncoding
        $script:SavedOutputEncoding = [Console]::OutputEncoding
        $script:SavedPipelineEncoding = $global:OutputEncoding
    }

    AfterEach {
        [Console]::InputEncoding = $script:SavedInputEncoding
        [Console]::OutputEncoding = $script:SavedOutputEncoding
        $global:OutputEncoding = $script:SavedPipelineEncoding
    }

    It 'sets all native command encodings to UTF-8' {
        Set-WUNativeCommandEncoding

        [Console]::InputEncoding.WebName | Should -Be 'utf-8'
        [Console]::OutputEncoding.WebName | Should -Be 'utf-8'
        $global:OutputEncoding.WebName | Should -Be 'utf-8'
        [Console]::OutputEncoding.GetPreamble().Length | Should -Be 0
    }

    It 'does not change encoding with WhatIf' {
        $ascii = [Text.Encoding]::ASCII
        [Console]::InputEncoding = $ascii
        [Console]::OutputEncoding = $ascii
        $global:OutputEncoding = $ascii

        Set-WUNativeCommandEncoding -WhatIf

        [Console]::InputEncoding.WebName | Should -Be 'us-ascii'
        [Console]::OutputEncoding.WebName | Should -Be 'us-ascii'
        $global:OutputEncoding.WebName | Should -Be 'us-ascii'
    }
}

Describe 'ConvertTo-WUNativeCommandArgument' {
    It 'preserves an empty argument in Windows PowerShell' {
        ConvertTo-WUNativeCommandArgument -Argument '' | Should -Be '""'
    }

    It 'returns nonempty arguments unchanged' {
        $arguments = @('plain', 'two words', 'say"hello')

        $result = @($arguments | ConvertTo-WUNativeCommandArgument)

        $result | Should -HaveCount 3
        for ($index = 0; $index -lt $arguments.Count; $index++) {
            $result[$index] | Should -Be $arguments[$index]
        }
    }
}

Describe 'Start-WUAndroidEmulator' {
    BeforeEach {
        InModuleScope -ModuleName PSWinUtil {
            $script:TestAndroidAvds = @('Pixel_API_35', 'Tablet_API_35')
            $script:TestAndroidExitCode = 0
            $script:CapturedAndroidArguments = @()

            function script:Invoke-WUTestAndroidEmulator {
                $script:CapturedAndroidArguments = @($args)
                $global:LASTEXITCODE = $script:TestAndroidExitCode
                $script:TestAndroidAvds
            }
        }
        Mock -CommandName Get-Command -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{ Source = 'Invoke-WUTestAndroidEmulator' }
        }
        Mock -CommandName Start-Process -ModuleName PSWinUtil -MockWith {
            Get-Process -Id $PID
        }
    }

    It 'requires emulator.exe on PATH' {
        Mock -CommandName Get-Command -ModuleName PSWinUtil

        { Start-WUAndroidEmulator } | Should -Throw '*not found on PATH*'
    }

    It 'reports a list command failure' {
        InModuleScope -ModuleName PSWinUtil {
            $script:TestAndroidExitCode = 1
            $script:TestAndroidAvds = @('list error')
        }

        { Start-WUAndroidEmulator } | Should -Throw '*exit code 1*'
        Should -Invoke -CommandName Start-Process -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'requires at least one Android virtual device' {
        InModuleScope -ModuleName PSWinUtil {
            $script:TestAndroidAvds = @()
        }

        { Start-WUAndroidEmulator } | Should -Throw '*No Android virtual device*'
    }

    It 'starts the first Android virtual device by default' {
        $process = Start-WUAndroidEmulator

        $process | Should -BeOfType ([System.Diagnostics.Process])
        Should -Invoke -CommandName Start-Process -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $FilePath -eq 'Invoke-WUTestAndroidEmulator' -and
            $ArgumentList -eq '@Pixel_API_35' -and
            $PassThru
        }
    }

    It 'starts the selected Android virtual device' {
        Start-WUAndroidEmulator -Name 'Tablet_API_35'

        Should -Invoke -CommandName Start-Process -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $ArgumentList -eq '@Tablet_API_35'
        }
    }

    It 'rejects an unknown Android virtual device name' {
        { Start-WUAndroidEmulator -Name 'Missing_API' } | Should -Throw '*was not found*'

        Should -Invoke -CommandName Start-Process -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'does not start a process with WhatIf' {
        Start-WUAndroidEmulator -WhatIf

        Should -Invoke -CommandName Start-Process -ModuleName PSWinUtil -Times 0 -Exactly
    }
}

Describe 'Get-WUAndroidCommandLineToolsUrl' {
    It 'returns the Windows package URL from the official page' {
        Mock -CommandName Invoke-WebRequest -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{
                Content = 'commandlinetools-win-123456_latest.zip commandlinetools-win-123456_latest.zip'
            }
        }

        Get-WUAndroidCommandLineToolsUrl |
            Should -Be 'https://dl.google.com/android/repository/commandlinetools-win-123456_latest.zip'
    }

    It 'reports an HTTP request failure' {
        Mock -CommandName Invoke-WebRequest -ModuleName PSWinUtil -MockWith {
            throw 'network failure'
        }

        { Get-WUAndroidCommandLineToolsUrl } | Should -Throw '*network failure*'
    }

    It 'reports a missing Windows package name' {
        Mock -CommandName Invoke-WebRequest -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{ Content = 'No Windows package is present.' }
        }

        { Get-WUAndroidCommandLineToolsUrl } | Should -Throw '*package was not found*'
    }
}
