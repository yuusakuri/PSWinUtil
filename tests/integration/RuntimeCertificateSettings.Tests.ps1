BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')
}

Describe 'Runtime certificate environment integration' {
    BeforeEach {
        $script:SavedNode = [Environment]::GetEnvironmentVariable('NODE_EXTRA_CA_CERTS', 'Process')
        $script:SavedJava = [Environment]::GetEnvironmentVariable('JAVA_TOOL_OPTIONS', 'Process')
        $env:NODE_EXTRA_CA_CERTS = 'original'
        $script:CertificatePath = Join-Path $TestDrive 'root[1].pem'
        [IO.File]::WriteAllText($script:CertificatePath, 'test certificate bundle')
    }

    AfterEach {
        [Environment]::SetEnvironmentVariable('NODE_EXTRA_CA_CERTS', $script:SavedNode, 'Process')
        [Environment]::SetEnvironmentVariable('JAVA_TOOL_OPTIONS', $script:SavedJava, 'Process')
    }

    It 'sets the literal certificate path without interpreting brackets' {
        Set-WUNodeExtraCaCertificate -LiteralPath $script:CertificatePath -Scope Process
        $env:NODE_EXTRA_CA_CERTS | Should -Be $script:CertificatePath
    }

    It 'resolves a wildcard to a single certificate' {
        Set-WUNodeExtraCaCertificate -Path (Join-Path $TestDrive '*.pem') -Scope Process
        $env:NODE_EXTRA_CA_CERTS | Should -Be $script:CertificatePath
    }

    It 'rejects ambiguous certificate paths and preserves the environment' {
        [IO.File]::WriteAllText((Join-Path $TestDrive 'second.pem'), 'second')
        { Set-WUNodeExtraCaCertificate -Path (Join-Path $TestDrive '*.pem') -Scope Process } | Should -Throw
        $env:NODE_EXTRA_CA_CERTS | Should -Be 'original'
    }

    It 'rejects a missing certificate and preserves the environment' {
        { Set-WUNodeExtraCaCertificate -LiteralPath (Join-Path $TestDrive 'missing.pem') -Scope Process } | Should -Throw
        $env:NODE_EXTRA_CA_CERTS | Should -Be 'original'
    }

    It 'previews certificate and trust store settings without changing their values' {
        $env:JAVA_TOOL_OPTIONS = '-Xmx2g'
        Set-WUNodeExtraCaCertificate -LiteralPath $script:CertificatePath -Scope Process -WhatIf
        $env:NODE_EXTRA_CA_CERTS | Should -Be 'original'
        $env:JAVA_TOOL_OPTIONS | Should -Be '-Xmx2g'
    }

}
