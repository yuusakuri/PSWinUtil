BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $manifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
    Import-Module -Name $manifestPath -Force -ErrorAction Stop
}

Describe 'Set-WUNodeExtraCaCertificate' {
    BeforeEach {
        Mock -CommandName ConvertTo-WUFullPath -ModuleName PSWinUtil -MockWith {
            $Path
        }
        Mock -CommandName Test-Path -ModuleName PSWinUtil -MockWith {
            $true
        }
        Mock -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil
    }

    It 'resolves and sets a specified certificate path' {
        Mock -CommandName ConvertTo-WUFullPath -ModuleName PSWinUtil -MockWith {
            'C:\Certificates\AdditionalRootCA.pem'
        }

        Set-WUNodeExtraCaCertificate -CertificatePath '.\AdditionalRootCA.pem'

        Should -Invoke -CommandName ConvertTo-WUFullPath -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Path -eq '.\AdditionalRootCA.pem'
        }
        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'NODE_EXTRA_CA_CERTS' -and
            $Value -eq 'C:\Certificates\AdditionalRootCA.pem' -and
            $Scope -eq 'User'
        }
    }

    It 'requires a certificate path' {
        { Set-WUNodeExtraCaCertificate } | Should -Throw

        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'rejects a missing certificate file' {
        Mock -CommandName Test-Path -ModuleName PSWinUtil -MockWith {
            $false
        }

        {
            Set-WUNodeExtraCaCertificate -CertificatePath '.\Missing.crt'
        } | Should -Throw '*certificate file was not found*'

        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'forwards WhatIf to the environment variable command' {
        Set-WUNodeExtraCaCertificate -CertificatePath '.\AdditionalRootCA.pem' -WhatIf

        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $WhatIf -eq $true
        }
    }

    It 'sets the environment variable in the selected scope' {
        Set-WUNodeExtraCaCertificate `
            -CertificatePath '.\AdditionalRootCA.pem' `
            -Scope Process

        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Scope -eq 'Process'
        }
    }
}

Describe 'Enable-WUJavaWindowsRootTrustStore' {
    BeforeEach {
        Mock -CommandName Get-WUEnvironmentVariable -ModuleName PSWinUtil
        Mock -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil
    }

    It 'sets the Windows ROOT trust store option for the current user' {
        Enable-WUJavaWindowsRootTrustStore

        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'JAVA_TOOL_OPTIONS' -and
            $Value -eq '-Djavax.net.ssl.trustStore=NONE -Djavax.net.ssl.trustStoreType=Windows-ROOT' -and
            $Scope -eq 'User'
        }
    }

    It 'forwards WhatIf to the environment variable command' {
        Enable-WUJavaWindowsRootTrustStore -WhatIf

        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $WhatIf -eq $true
        }
    }

    It 'preserves unrelated Java tool options' {
        Mock -CommandName Get-WUEnvironmentVariable -ModuleName PSWinUtil -MockWith {
            '-Xmx2g -Dfile.encoding=UTF-8'
        }

        Enable-WUJavaWindowsRootTrustStore

        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Value -eq '-Xmx2g -Dfile.encoding=UTF-8 -Djavax.net.ssl.trustStore=NONE -Djavax.net.ssl.trustStoreType=Windows-ROOT'
        }
    }

    It 'replaces existing trust store options' {
        Mock -CommandName Get-WUEnvironmentVariable -ModuleName PSWinUtil -MockWith {
            '-Xmx2g -Djavax.net.ssl.trustStore=custom.jks -Djavax.net.ssl.trustStoreType=JKS'
        }

        Enable-WUJavaWindowsRootTrustStore

        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Value -eq '-Xmx2g -Djavax.net.ssl.trustStore=NONE -Djavax.net.ssl.trustStoreType=Windows-ROOT'
        }
    }

    It 'does not duplicate existing Windows trust store options' {
        Mock -CommandName Get-WUEnvironmentVariable -ModuleName PSWinUtil -MockWith {
            '-Djavax.net.ssl.trustStore=NONE -Djavax.net.ssl.trustStoreType=Windows-ROOT'
        }

        Enable-WUJavaWindowsRootTrustStore

        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Value -eq '-Djavax.net.ssl.trustStore=NONE -Djavax.net.ssl.trustStoreType=Windows-ROOT'
        }
    }

    It 'reads and sets Java tool options in the selected scope' {
        Enable-WUJavaWindowsRootTrustStore -Scope Machine

        Should -Invoke -CommandName Get-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'JAVA_TOOL_OPTIONS' -and $Scope -eq 'Machine'
        }
        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Scope -eq 'Machine'
        }
    }
}
