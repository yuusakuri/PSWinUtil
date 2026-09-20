BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')
}

Describe 'Invoke-WUNativeCommand' {
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
        $script:FailBatchPath = Join-Path -Path $script:CommandDirectory -ChildPath 'fail command.cmd'
        [IO.File]::WriteAllText($script:FailBatchPath, "@echo off`r`nexit /b 9`r`n", [Text.Encoding]::ASCII)
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
        $result = Invoke-WUNativeCommand -Command 'powershell.exe' -ArgumentList @(
            '-NoProfile', '-File', $script:ProcessScriptPath, $Value
        ) -CaptureOutput

        $result | Should -BeOfType ([PSWinUtil.NativeCommandResult])
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
        $result = Invoke-WUNativeCommand -Command $script:BatchPath -ArgumentList @($Value) -CaptureOutput

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
        { Invoke-WUNativeCommand -Command $script:BatchPath -ArgumentList @($Value) -CaptureOutput } | Should -Throw
    }

    It 'runs a batch file without arguments' {
        $result = Invoke-WUNativeCommand -Command $script:BatchPath -CaptureOutput

        $result.Succeeded | Should -BeTrue
        $result.StandardOutput.TrimEnd() | Should -Be 'PSWINUTIL_VALUE=[]'
    }

    It 'runs a .bat file with an argument' {
        $result = Invoke-WUNativeCommand -Command $script:BatPath -ArgumentList @('one value') -CaptureOutput

        $result.Succeeded | Should -BeTrue
        $result.StandardOutput.TrimEnd() | Should -Be 'PSWINUTIL_VALUE=[one value]'
    }

    It 'runs a batch command found on PATH with distinct argument values' {
        $previousPath = $env:PATH
        try {
            $env:PATH = "$script:CommandDirectory;$previousPath"
            $result = Invoke-WUNativeCommand -Command 'echo two arguments.cmd' -ArgumentList @(
                'one value', 'a&b'
            ) -CaptureOutput

            $result.Succeeded | Should -BeTrue
            $result.StandardOutput.TrimEnd() -split '\r?\n' | Should -Be @('FIRST=[one value]', 'SECOND=[a&b]')
        } finally {
            $env:PATH = $previousPath
        }
    }

    It 'returns a failed result when the error is ignored' {
        $result = Invoke-WUNativeCommand -Command 'powershell.exe' -ArgumentList @(
            '-NoProfile', '-File', $script:ExitScriptPath
        ) -CaptureOutput -ErrorAction Ignore -ErrorVariable ignoredErrors

        $result.Succeeded | Should -BeFalse
        $result.ExitCode | Should -Be 7
        $ignoredErrors | Should -BeNullOrEmpty
        $result.StandardOutput.TrimEnd() | Should -Be 'stdout-result'
        $result.StandardError.TrimEnd() | Should -Be 'stderr-result'

        $debugResult = $result.ToDebugString() | ConvertFrom-Json
        $debugResult.exit_code | Should -Be 7
        $debugResult.message | Should -Match '^stderr-result\r?\nstdout-result\r?\n$'
    }

    It 'writes a structured error when error handling continues' {
        $result = Invoke-WUNativeCommand -Command 'powershell.exe' -ArgumentList @(
            '-NoProfile', '-File', $script:ExitScriptPath
        ) -CaptureOutput -ErrorAction Continue -ErrorVariable commandError 2>$null

        $result.Succeeded | Should -BeFalse
        $commandError | Should -HaveCount 1
        $errorText = $commandError[0].Exception.Message
        $errorText | Should -Match '^Command failed: '
        $diagnostic = $errorText.Substring('Command failed: '.Length) | ConvertFrom-Json
        $diagnostic.command | Should -BeExactly 'powershell.exe'
        $diagnostic.exit_code | Should -Be 7
        $diagnostic.message | Should -Match 'stderr-result'
    }

    It 'stops on failure when the caller requests terminating errors' {
        {
            Invoke-WUNativeCommand -Command 'powershell.exe' -ArgumentList @(
                '-NoProfile', '-File', $script:ExitScriptPath
            ) -CaptureOutput -ErrorAction Stop
        } | Should -Throw '*Command failed:*'
    }

    It 'reports a failing batch command with its exit code' {
        $result = Invoke-WUNativeCommand -Command $script:FailBatchPath -ErrorAction Continue -ErrorVariable commandError 2>$null

        $result.Succeeded | Should -BeFalse
        $diagnostic = $commandError[0].Exception.Message.Substring('Command failed: '.Length) | ConvertFrom-Json
        $diagnostic.command | Should -BeExactly $script:FailBatchPath
        $diagnostic.exit_code | Should -Be 9
    }

    It 'treats a selected exit code as success without changing the actual exit code' {
        $result = Invoke-WUNativeCommand -Command 'powershell.exe' -ArgumentList @(
            '-NoProfile', '-File', $script:ExitScriptPath
        ) -CaptureOutput -ContinueExitCodes 7

        $result.Succeeded | Should -BeTrue
        $result.ExitCode | Should -Be 7
    }

    It 'does not capture output unless requested' {
        $result = Invoke-WUNativeCommand -Command 'powershell.exe' -ArgumentList @(
            '-NoProfile', '-File', $script:ExitScriptPath
        ) -ErrorAction Ignore

        $result.Succeeded | Should -BeFalse
        $result.StandardOutput | Should -BeNullOrEmpty
        $result.StandardError | Should -BeNullOrEmpty
    }

    It 'evaluates ShouldProcess with the command and arguments immediately before execution' {
        $result = Invoke-WUNativeCommand -Command 'powershell.exe' -ArgumentList @(
            '-NoProfile', '-File', $script:ExitScriptPath
        ) -CaptureOutput -WhatIf 2>&1 | Out-String

        $result | Should -BeNullOrEmpty
    }
}
