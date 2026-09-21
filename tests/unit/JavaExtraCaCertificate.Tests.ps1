BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')
    $script:Module = Get-Module -Name 'PSWinUtil' -ErrorAction Stop
}

Describe 'Set-WUJavaExtraCaCertificate' {
    BeforeEach {
        $script:JavaHome = Join-Path $TestDrive 'jdk'
        $script:CertificatePath = Join-Path $TestDrive 'extra.crt'
        New-Item -Path (Join-Path $script:JavaHome 'lib\security') -ItemType Directory -Force | Out-Null
        [IO.File]::WriteAllText($script:CertificatePath, 'certificate')
        $env:JAVA_HOME = $script:JavaHome
        Mock -CommandName Assert-WUCommand -ModuleName PSWinUtil
        Mock -CommandName Invoke-WUNativeCommand -ModuleName PSWinUtil
        Mock -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil
    }

    It 'imports into JAVA_HOME and configures JAVA_TOOL_OPTIONS in the requested scope' {
        Set-WUJavaExtraCaCertificate -LiteralPath $script:CertificatePath -Scope Process

        Should -Invoke -CommandName Invoke-WUNativeCommand -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Command -eq 'keytool' -and
            $ArgumentList -contains $script:CertificatePath -and
            $ArgumentList -contains (Join-Path $script:JavaHome 'lib\security\cacerts')
        }
        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'JAVA_TOOL_OPTIONS' -and
            $Value -eq "-Djavax.net.ssl.trustStore=$(Join-Path $script:JavaHome 'lib\security\cacerts')" -and
            $Scope -eq 'Process'
        }
    }

    It 'does not invoke keytool or update the environment in preview mode' {
        Set-WUJavaExtraCaCertificate -LiteralPath $script:CertificatePath -Scope Process -WhatIf

        Should -Invoke -CommandName Invoke-WUNativeCommand -ModuleName PSWinUtil -Times 0 -Exactly
        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly
    }
}
