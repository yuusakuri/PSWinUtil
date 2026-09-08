BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')

    $script:AndroidCliUri = [uri]'https://dl.google.com/android/cli/latest/windows_x86_64/android.exe'
    $script:ReferencePath = Join-Path -Path $TestDrive -ChildPath 'android-reference.exe'
    Invoke-WUHttpFileDownload -Uri $script:AndroidCliUri -Path $script:ReferencePath
    $script:ReferenceLength = (Get-Item -LiteralPath $script:ReferencePath).Length
    $script:ReferenceHash = (Get-FileHash -LiteralPath $script:ReferencePath -Algorithm SHA256).Hash

    function Invoke-AndroidCliRangeResumeIntegrationTest {
        param(
            [Parameter(Mandatory = $true)]
            [long[]]$DisconnectAt,

            [Parameter(Mandatory = $true)]
            [string]$Path
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

        Invoke-WUHttpFileDownload -Uri $script:AndroidCliUri -Path $Path

        (Get-Item -LiteralPath $Path).Length | Should -Be $script:ReferenceLength
        (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash | Should -Be $script:ReferenceHash
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

Describe 'Invoke-WUHttpFileDownload with the Google Android CLI server' -Tag 'Integration', 'Online' {
    It 'reconstructs Android CLI after one Range resume' {
        $downloadPath = Join-Path -Path $TestDrive -ChildPath 'android-one-resume.exe'

        Invoke-AndroidCliRangeResumeIntegrationTest `
            -DisconnectAt 1MB `
            -Path $downloadPath
    }

    It 'reconstructs Android CLI after two Range resumes' {
        $downloadPath = Join-Path -Path $TestDrive -ChildPath 'android-two-resumes.exe'

        Invoke-AndroidCliRangeResumeIntegrationTest `
            -DisconnectAt 1MB, 2MB `
            -Path $downloadPath
    }
}
