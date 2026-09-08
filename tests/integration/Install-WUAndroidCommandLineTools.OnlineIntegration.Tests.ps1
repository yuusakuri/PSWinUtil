BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')

    function Invoke-AndroidCommandLineToolsOnlineIntegrationTest {
        param(
            [Parameter(Mandatory = $true)]
            [long[]]$DisconnectAt,

            [Parameter(Mandatory = $true)]
            [string]$SdkPath
        )

        $state = @{
            CallIndex = 0
            StartPositions = [System.Collections.Generic.List[long]]::new()
        }
        Mock -CommandName Copy-WUHttpContent -ModuleName PSWinUtil -MockWith {
            param($InputStream, $OutputStream)

            $state.StartPositions.Add($OutputStream.Position)
            if ($state.CallIndex -lt $DisconnectAt.Count) {
                $targetLength = $DisconnectAt[$state.CallIndex]
                $buffer = [byte[]]::new(81920)
                while ($OutputStream.Position -lt $targetLength) {
                    $remaining = $targetLength - $OutputStream.Position
                    $count = [int][Math]::Min($buffer.Length, $remaining)
                    $read = $InputStream.Read($buffer, 0, $count)
                    if ($read -eq 0) {
                        throw 'The Google response ended before the simulated interruption position.'
                    }
                    $OutputStream.Write($buffer, 0, $read)
                }

                $state.CallIndex++
                throw [System.IO.IOException]::new('Simulated connection interruption.')
            }

            $InputStream.CopyTo($OutputStream)
        }

        Install-WUAndroidCommandLineTools -SdkPath $SdkPath

        $sdkManagerPath = Join-Path `
            -Path $SdkPath `
            -ChildPath 'cmdline-tools\latest\bin\sdkmanager.bat'
        $sdkManagerPath | Should -Exist

        $previousErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            $sdkManagerOutput = @(& $sdkManagerPath --version 2>&1)
            $sdkManagerExitCode = $LASTEXITCODE
        } finally {
            $ErrorActionPreference = $previousErrorActionPreference
        }
        $sdkManagerExitCode | Should -Be 0
        $sdkManagerOutput.Count | Should -BeGreaterThan 0

        $expectedStarts = @([long]0) + @($DisconnectAt)
        $state.StartPositions.Count | Should -Be $expectedStarts.Count
        for ($index = 0; $index -lt $expectedStarts.Count; $index++) {
            $state.StartPositions[$index] | Should -Be $expectedStarts[$index]
        }
        Should -Invoke -CommandName Copy-WUHttpContent `
            -ModuleName PSWinUtil `
            -Times $expectedStarts.Count `
            -Exactly
    }
}

Describe 'Install-WUAndroidCommandLineTools' -Tag 'Integration', 'Online' {
    It 'installs usable tools after one interrupted Google download' {
        $sdkPath = Join-Path -Path $TestDrive -ChildPath 'AndroidSdkOneInterruption'

        Invoke-AndroidCommandLineToolsOnlineIntegrationTest `
            -DisconnectAt 10MB `
            -SdkPath $sdkPath
    }

    It 'installs usable tools after two interrupted Google downloads' {
        $sdkPath = Join-Path -Path $TestDrive -ChildPath 'AndroidSdkTwoInterruptions'

        Invoke-AndroidCommandLineToolsOnlineIntegrationTest `
            -DisconnectAt 10MB, 25MB `
            -SdkPath $sdkPath
    }
}
