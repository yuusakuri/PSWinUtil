BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')
}

Describe 'ExternalCommandResult.ToDebugString' {
    It 'returns exit code and stderr before stdout as JSON' {
        $result = [PSWinUtil.ExternalCommandResult]::new(
            $false, 7, 'stdout "quoted"', "stderr`n"
        )

        $debugResult = $result.ToDebugString() | ConvertFrom-Json

        ($debugResult.PSObject.Properties.Name -join ',') |
            Should -BeExactly 'exit_code,message'
        $debugResult.exit_code | Should -Be 7
        $debugResult.message | Should -BeExactly "stderr`nstdout `"quoted`""
    }

    It 'returns an empty message when no output was captured' {
        $result = [PSWinUtil.ExternalCommandResult]::new($false, 3, $null, $null)

        $debugResult = $result.ToDebugString() | ConvertFrom-Json

        $debugResult.exit_code | Should -Be 3
        $debugResult.message | Should -BeExactly ''
    }
}
