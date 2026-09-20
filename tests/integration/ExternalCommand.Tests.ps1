BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')
}

Describe 'Invoke-WUExternalCommand' {
    BeforeAll {
        $script:CommandDirectory = Join-Path -Path $TestDrive -ChildPath 'batch tools & data'
        New-Item -Path $script:CommandDirectory -ItemType Directory -Force | Out-Null
        $script:BatchPath = Join-Path -Path $script:CommandDirectory -ChildPath 'echo arguments.cmd'
        [IO.File]::WriteAllText(
            $script:BatchPath,
            "@echo off`r`nsetlocal DisableDelayedExpansion`r`nset `"PSWINUTIL_VALUE=[%~1]`"`r`nset PSWINUTIL_VALUE`r`n",
            [Text.Encoding]::ASCII
        )
        $script:BatPath = Join-Path -Path $script:CommandDirectory -ChildPath 'echo arguments.bat'
        Copy-Item -LiteralPath $script:BatchPath -Destination $script:BatPath
        $script:TwoArgumentPath = Join-Path -Path $script:CommandDirectory -ChildPath 'echo two arguments.cmd'
        [IO.File]::WriteAllText(
            $script:TwoArgumentPath,
            "@echo off`r`nsetlocal DisableDelayedExpansion`r`nset `"FIRST=[%~1]`"`r`nset `"SECOND=[%~2]`"`r`nset FIRST`r`nset SECOND`r`n",
            [Text.Encoding]::ASCII
        )
        $script:ProcessScriptPath = Join-Path -Path $script:CommandDirectory -ChildPath 'echo-arguments.ps1'
        [IO.File]::WriteAllText(
            $script:ProcessScriptPath,
            "[Console]::WriteLine('VALUE=' + `$args[0])`n",
            [Text.Encoding]::ASCII
        )
        $script:ExitScriptPath = Join-Path -Path $script:CommandDirectory -ChildPath 'report-exit.ps1'
        [IO.File]::WriteAllText(
            $script:ExitScriptPath,
            "[Console]::Out.WriteLine('stdout-result')`n[Console]::Error.WriteLine('stderr-result')`nexit 7`n",
            [Text.Encoding]::ASCII
        )
    }

    It 'passes a process argument unchanged and returns captured output' -ForEach @(
        @{ Value = '' }
        @{ Value = 'two words' }
        @{ Value = 'say"hello' }
        @{ Value = 'C:\folder\' }
        @{ Value = 'C:\path with spaces\' }
        @{ Value = "two`twords" }
    ) {
        $result = Invoke-WUExternalCommand -Command 'powershell.exe' -ArgumentList @(
            '-NoProfile', '-File', $script:ProcessScriptPath, $Value
        ) -CaptureOutput

        $result | Should -BeOfType ([PSWinUtil.ExternalCommandResult])
        $result.Succeeded | Should -BeTrue
        $result.ExitCode | Should -Be 0
        $result.StandardOutput.TrimEnd() | Should -Be "VALUE=$Value"
        $result.StandardError | Should -Be ''
    }

    It 'passes a batch argument unchanged through cmd.exe' -ForEach @(
        @{ Value = '' }
        @{ Value = 'two words' }
        @{ Value = 'a&b' }
        @{ Value = 'a|b' }
        @{ Value = 'a>b' }
        @{ Value = 'a(b)' }
        @{ Value = 'a^b' }
        @{ Value = 'C:\folder' }
        @{ Value = 'C:\path with spaces' }
    ) {
        $result = Invoke-WUExternalCommand -Command $script:BatchPath -ArgumentList @($Value) -CaptureOutput

        $result.Succeeded | Should -BeTrue
        $result.StandardOutput.TrimEnd() | Should -Be "PSWINUTIL_VALUE=[$Value]"
        $result.StandardError | Should -Be ''
    }

    It 'rejects batch arguments that cmd.exe would reinterpret' -ForEach @(
        @{ Value = 'a%b' }
        @{ Value = 'a!b' }
        @{ Value = 'say"hello' }
        @{ Value = 'x" & echo INJECTED & rem "' }
        @{ Value = 'C:\folder\' }
        @{ Value = 'C:\path with spaces\' }
        @{ Value = "two`twords" }
    ) {
        { Invoke-WUExternalCommand -Command $script:BatchPath -ArgumentList @($Value) -CaptureOutput } | Should -Throw
    }

    It 'runs a batch file without arguments' {
        $result = Invoke-WUExternalCommand -Command $script:BatchPath -CaptureOutput

        $result.Succeeded | Should -BeTrue
        $result.StandardOutput.TrimEnd() | Should -Be 'PSWINUTIL_VALUE=[]'
    }

    It 'runs a .bat file with an argument' {
        $result = Invoke-WUExternalCommand -Command $script:BatPath -ArgumentList @('one value') -CaptureOutput

        $result.Succeeded | Should -BeTrue
        $result.StandardOutput.TrimEnd() | Should -Be 'PSWINUTIL_VALUE=[one value]'
    }

    It 'runs a batch command found on PATH with distinct argument values' {
        $previousPath = $env:PATH
        try {
            $env:PATH = "$script:CommandDirectory;$previousPath"
            $result = Invoke-WUExternalCommand -Command 'echo two arguments.cmd' -ArgumentList @(
                'one value', 'a&b'
            ) -CaptureOutput

            $result.Succeeded | Should -BeTrue
            $result.StandardOutput.TrimEnd() -split '\r?\n' | Should -Be @('FIRST=[one value]', 'SECOND=[a&b]')
        } finally {
            $env:PATH = $previousPath
        }
    }

    It 'reports a nonzero exit and separate output streams' {
        $result = Invoke-WUExternalCommand -Command 'powershell.exe' -ArgumentList @(
            '-NoProfile', '-File', $script:ExitScriptPath
        ) -CaptureOutput

        $result.Succeeded | Should -BeFalse
        $result.ExitCode | Should -Be 7
        $result.StandardOutput.TrimEnd() | Should -Be 'stdout-result'
        $result.StandardError.TrimEnd() | Should -Be 'stderr-result'

        $debugResult = $result.ToDebugString() | ConvertFrom-Json
        $debugResult.exit_code | Should -Be 7
        $debugResult.message | Should -Match '^stderr-result\r?\nstdout-result\r?\n$'
    }

    It 'treats a selected exit code as success without changing the actual exit code' {
        $result = Invoke-WUExternalCommand -Command 'powershell.exe' -ArgumentList @(
            '-NoProfile', '-File', $script:ExitScriptPath
        ) -CaptureOutput -ContinueExitCodes 7

        $result.Succeeded | Should -BeTrue
        $result.ExitCode | Should -Be 7
    }

    It 'does not capture output unless requested' {
        $result = Invoke-WUExternalCommand -Command 'powershell.exe' -ArgumentList @(
            '-NoProfile', '-File', $script:ExitScriptPath
        )

        $result.Succeeded | Should -BeFalse
        $result.StandardOutput | Should -BeNullOrEmpty
        $result.StandardError | Should -BeNullOrEmpty
    }
}
