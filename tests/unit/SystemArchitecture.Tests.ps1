BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')

    $script:Module = Get-Module -Name 'PSWinUtil' -ErrorAction Stop
}

Describe 'Get-SystemArchitecture' {
    It 'returns Arm64 when the environment reports Arm64' {
        $originalArchitecture = $env:PROCESSOR_ARCHITECTURE
        $originalArchitectureW6432 = $env:PROCESSOR_ARCHITEW6432
        try {
            $env:PROCESSOR_ARCHITECTURE = 'ARM64'
            $env:PROCESSOR_ARCHITEW6432 = $null

            Get-SystemArchitecture | Should -Be ([System.Runtime.InteropServices.Architecture]::Arm64)
        } finally {
            $env:PROCESSOR_ARCHITECTURE = $originalArchitecture
            $env:PROCESSOR_ARCHITEW6432 = $originalArchitectureW6432
        }
    }

    It 'returns the current operating system architecture' {
        $expectedArchitecture = if ([System.Environment]::Is64BitOperatingSystem) {
            [System.Runtime.InteropServices.Architecture]::X64
        } else {
            [System.Runtime.InteropServices.Architecture]::X86
        }

        Get-SystemArchitecture | Should -Be $expectedArchitecture
    }
}

Describe 'Format-FlutterSystemArchitectureString' {
    It 'formats supported system architectures for Flutter' {
        & $script:Module {
            Format-FlutterSystemArchitectureString -Architecture ([System.Runtime.InteropServices.Architecture]::X64)
        } | Should -Be 'x64'

        & $script:Module {
            Format-FlutterSystemArchitectureString -Architecture ([System.Runtime.InteropServices.Architecture]::Arm64)
        } | Should -Be 'arm64'
    }

    It 'rejects an unsupported system architecture' {
        {
            & $script:Module {
                Format-FlutterSystemArchitectureString -Architecture ([System.Runtime.InteropServices.Architecture]::X86)
            }
        } | Should -Throw "*does not support*"
    }
}
