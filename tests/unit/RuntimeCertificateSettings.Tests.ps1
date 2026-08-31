BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $manifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
    Import-Module -Name $manifestPath -Force -ErrorAction Stop
}

Describe 'Set-WUNodeExtraCaCertificate' {
    BeforeEach {
        Mock -CommandName Resolve-WUPathFromParameterSet -ModuleName PSWinUtil -MockWith {
            '.\AdditionalRootCA.pem'
        }
        Mock -CommandName ConvertTo-WUFullPath -ModuleName PSWinUtil -MockWith {
            'C:\Certificates\AdditionalRootCA.pem'
        }
        Mock -CommandName Assert-WUPathProperty -ModuleName PSWinUtil
        Mock -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil
    }

    It 'resolves and validates Path before setting the certificate' {
        Set-WUNodeExtraCaCertificate -Path '.\AdditionalRootCA.pem'

        Should -Invoke -CommandName Resolve-WUPathFromParameterSet -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $ParameterSetName -eq 'Path' -and
            $Path -contains '.\AdditionalRootCA.pem' -and
            $DenyMultiplePaths
        }
        Should -Invoke -CommandName ConvertTo-WUFullPath -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Path -eq '.\AdditionalRootCA.pem'
        }
        Should -Invoke -CommandName Assert-WUPathProperty -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $LiteralPath -eq 'C:\Certificates\AdditionalRootCA.pem' -and $Leaf
        }
        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'NODE_EXTRA_CA_CERTS' -and
            $Value -eq 'C:\Certificates\AdditionalRootCA.pem' -and
            $Scope -eq 'User'
        }
    }

    It 'resolves LiteralPath without wildcard interpretation' {
        Set-WUNodeExtraCaCertificate -LiteralPath '.\AdditionalRoot[1].pem'

        Should -Invoke -CommandName Resolve-WUPathFromParameterSet -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $ParameterSetName -eq 'LiteralPath' -and
            $LiteralPath -contains '.\AdditionalRoot[1].pem' -and
            $DenyMultiplePaths
        }
    }

    It 'requires Path or LiteralPath' {
        { Set-WUNodeExtraCaCertificate } | Should -Throw

        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'rejects a Path that resolves to multiple files' {
        Mock -CommandName Resolve-WUPathFromParameterSet -ModuleName PSWinUtil -MockWith {
            throw [System.ArgumentException]::new('Path resolved to more than one result')
        }

        {
            Set-WUNodeExtraCaCertificate -Path 'C:\Certificates\*.pem'
        } | Should -Throw '*more than one result*'

        Should -Invoke -CommandName ConvertTo-WUFullPath -ModuleName PSWinUtil -Times 0 -Exactly
        Should -Invoke -CommandName Assert-WUPathProperty -ModuleName PSWinUtil -Times 0 -Exactly
        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'forwards WhatIf to the environment variable command' {
        Set-WUNodeExtraCaCertificate -Path '.\AdditionalRootCA.pem' -WhatIf

        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $WhatIf -eq $true
        }
    }

    It 'forwards Confirm to the environment variable command' {
        Set-WUNodeExtraCaCertificate -Path '.\AdditionalRootCA.pem' -Confirm:$false

        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Confirm -eq $false
        }
    }

    It 'sets the certificate in every selected scope' {
        Set-WUNodeExtraCaCertificate -Path '.\AdditionalRootCA.pem' -Scope Process, User

        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            @($Scope).Count -eq 2 -and
            $Scope[0] -eq 'Process' -and
            $Scope[1] -eq 'User'
        }
    }
}

Describe 'Set-WUJavaWindowsRootTrustStore' {
    BeforeEach {
        Mock -CommandName Get-WUEnvironmentVariable -ModuleName PSWinUtil
        Mock -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil
    }

    It 'sets only the Windows ROOT trust store type for the current user' {
        Set-WUJavaWindowsRootTrustStore

        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'JAVA_TOOL_OPTIONS' -and
            $Value -eq '-Djavax.net.ssl.trustStoreType=Windows-ROOT' -and
            $Value -notmatch 'trustStore=NONE' -and
            $Scope -eq 'User'
        }
    }

    It 'forwards WhatIf to the environment variable command' {
        Set-WUJavaWindowsRootTrustStore -WhatIf

        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $WhatIf -eq $true
        }
    }

    It 'forwards Confirm to the environment variable command' {
        Set-WUJavaWindowsRootTrustStore -Confirm:$false

        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Confirm -eq $false
        }
    }

    It 'preserves unrelated Java tool options' {
        Mock -CommandName Get-WUEnvironmentVariable -ModuleName PSWinUtil -MockWith {
            '-Xmx2g -Dfile.encoding=UTF-8'
        }

        Set-WUJavaWindowsRootTrustStore

        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Value -eq '-Xmx2g -Dfile.encoding=UTF-8 -Djavax.net.ssl.trustStoreType=Windows-ROOT'
        }
    }

    It 'removes an existing trust store path and replaces the trust store type' {
        Mock -CommandName Get-WUEnvironmentVariable -ModuleName PSWinUtil -MockWith {
            '-Xmx2g -Djavax.net.ssl.trustStore=custom.jks -Djavax.net.ssl.trustStoreType=JKS'
        }

        Set-WUJavaWindowsRootTrustStore

        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Value -eq '-Xmx2g -Djavax.net.ssl.trustStoreType=Windows-ROOT'
        }
    }

    It 'removes a quoted trust store path that contains spaces' {
        Mock -CommandName Get-WUEnvironmentVariable -ModuleName PSWinUtil -MockWith {
            '-Xmx2g -Djavax.net.ssl.trustStore="C:\Program Files\Java\custom.jks" -Dfile.encoding=UTF-8'
        }

        Set-WUJavaWindowsRootTrustStore

        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Value -eq '-Xmx2g -Dfile.encoding=UTF-8 -Djavax.net.ssl.trustStoreType=Windows-ROOT'
        }
    }

    It 'removes a trust store option without case differences' {
        Mock -CommandName Get-WUEnvironmentVariable -ModuleName PSWinUtil -MockWith {
            '-Djavax.net.ssl.truststore=NONE -Xmx2g'
        }

        Set-WUJavaWindowsRootTrustStore

        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Value -eq '-Xmx2g -Djavax.net.ssl.trustStoreType=Windows-ROOT'
        }
    }

    It 'replaces trust store type option casing consistently' -TestCases @(
        @{ ExistingOption = '-Djavax.net.ssl.trustStoreType=WINDOWS-ROOT' }
        @{ ExistingOption = '-Djavax.net.ssl.truststoretype=Windows-ROOT' }
    ) {
        param($ExistingOption)

        $script:ExistingTrustStoreTypeOption = $ExistingOption
        Mock -CommandName Get-WUEnvironmentVariable -ModuleName PSWinUtil -MockWith {
            $script:ExistingTrustStoreTypeOption
        }

        Set-WUJavaWindowsRootTrustStore

        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Value -eq '-Djavax.net.ssl.trustStoreType=Windows-ROOT'
        }
    }

    It 'collapses multiple trust store type options to one Windows ROOT option' {
        Mock -CommandName Get-WUEnvironmentVariable -ModuleName PSWinUtil -MockWith {
            '-Djavax.net.ssl.trustStoreType=JKS -Xmx2g -Djavax.net.ssl.trustStoreType=PKCS12'
        }

        Set-WUJavaWindowsRootTrustStore

        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Value -eq '-Xmx2g -Djavax.net.ssl.trustStoreType=Windows-ROOT'
        }
    }

    It 'reads and sets Java tool options independently in every selected scope' {
        Mock -CommandName Get-WUEnvironmentVariable -ModuleName PSWinUtil -MockWith {
            if ($Scope -eq 'Process') {
                '-Xms512m'
            } else {
                '-Djavax.net.ssl.trustStoreType=JKS'
            }
        }

        Set-WUJavaWindowsRootTrustStore -Scope Process, User

        Should -Invoke -CommandName Get-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'JAVA_TOOL_OPTIONS' -and $Scope -eq 'Process'
        }
        Should -Invoke -CommandName Get-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'JAVA_TOOL_OPTIONS' -and $Scope -eq 'User'
        }
        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Scope -eq 'Process' -and
            $Value -eq '-Xms512m -Djavax.net.ssl.trustStoreType=Windows-ROOT'
        }
        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Scope -eq 'User' -and
            $Value -eq '-Djavax.net.ssl.trustStoreType=Windows-ROOT'
        }
    }
}
