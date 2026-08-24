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
            'C:\Certificates\AdditionalRootCA.crt'
        }

        Set-WUNodeExtraCaCertificate -CertificatePath '.\AdditionalRootCA.crt'

        Should -Invoke -CommandName ConvertTo-WUFullPath -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Path -eq '.\AdditionalRootCA.crt'
        }
        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'NODE_EXTRA_CA_CERTS' -and
            $Value -eq 'C:\Certificates\AdditionalRootCA.crt' -and
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
        Set-WUNodeExtraCaCertificate -CertificatePath '.\AdditionalRootCA.crt' -WhatIf

        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $WhatIf -eq $true
        }
    }
}

Describe 'Enable-WUJavaWindowsRootTrustStore' {
    BeforeEach {
        Mock -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil
    }

    It 'sets the Windows ROOT trust store option for the current user' {
        Enable-WUJavaWindowsRootTrustStore

        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'JAVA_TOOL_OPTIONS' -and
            $Value -eq '-Djavax.net.ssl.trustStoreType=WINDOWS-ROOT' -and
            $Scope -eq 'User'
        }
    }

    It 'forwards WhatIf to the environment variable command' {
        Enable-WUJavaWindowsRootTrustStore -WhatIf

        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $WhatIf -eq $true
        }
    }
}
