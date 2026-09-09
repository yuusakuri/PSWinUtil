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
        Set-WUNodeExtraCaCertificate -LiteralPath $script:CertificatePath -Scope Process -Confirm:$false
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
        Set-WUJavaWindowsRootTrustStore -Scope Process -WhatIf
        $env:NODE_EXTRA_CA_CERTS | Should -Be 'original'
        $env:JAVA_TOOL_OPTIONS | Should -Be '-Xmx2g'
    }

    It 'replaces trust store options while preserving <Existing>' -TestCases @(
        @{ Existing = ''; Expected = '-Djavax.net.ssl.trustStoreType=Windows-ROOT' }
        @{ Existing = '-Xmx2g -Dfile.encoding=UTF-8'; Expected = '-Xmx2g -Dfile.encoding=UTF-8 -Djavax.net.ssl.trustStoreType=Windows-ROOT' }
        @{ Existing = '-Xmx2g -Djavax.net.ssl.trustStore=custom.jks -Djavax.net.ssl.trustStoreType=JKS'; Expected = '-Xmx2g -Djavax.net.ssl.trustStoreType=Windows-ROOT' }
        @{ Existing = '-Xmx2g -Djavax.net.ssl.trustStore="C:\Program Files\Java\custom.jks"'; Expected = '-Xmx2g -Djavax.net.ssl.trustStoreType=Windows-ROOT' }
        @{ Existing = '-Djavax.net.ssl.truststore=NONE -Xmx2g'; Expected = '-Xmx2g -Djavax.net.ssl.trustStoreType=Windows-ROOT' }
        @{ Existing = '-Djavax.net.ssl.trustStoreType=WINDOWS-ROOT'; Expected = '-Djavax.net.ssl.trustStoreType=Windows-ROOT' }
        @{ Existing = '-Djavax.net.ssl.truststoretype=Windows-ROOT'; Expected = '-Djavax.net.ssl.trustStoreType=Windows-ROOT' }
        @{ Existing = '-Djavax.net.ssl.trustStoreType=JKS -Xmx2g -Djavax.net.ssl.trustStoreType=PKCS12'; Expected = '-Xmx2g -Djavax.net.ssl.trustStoreType=Windows-ROOT' }
    ) {
        param($Existing, $Expected)
        $env:JAVA_TOOL_OPTIONS = $Existing
        Set-WUJavaWindowsRootTrustStore -Scope Process -Confirm:$false
        $env:JAVA_TOOL_OPTIONS | Should -Be $Expected
        Set-WUJavaWindowsRootTrustStore -Scope Process
        $env:JAVA_TOOL_OPTIONS | Should -Be $Expected
    }
}
