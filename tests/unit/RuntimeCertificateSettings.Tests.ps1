BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')
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

    It 'sets the certificate in every selected scope' {
        Set-WUNodeExtraCaCertificate -Path '.\AdditionalRootCA.pem' -Scope Process, User

        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            @($Scope).Count -eq 2 -and
            $Scope[0] -eq 'Process' -and
            $Scope[1] -eq 'User'
        }
    }
}

Describe 'Set-WUJavaExtraCaCertificate' {
    BeforeEach {
        Mock -CommandName ConvertTo-WUFullPath -ModuleName PSWinUtil -MockWith {
            'C:\Certificates\extra-ca-certs.crt'
        }
        Mock -CommandName Assert-WUPathProperty -ModuleName PSWinUtil
        Mock -CommandName Assert-WUCommand -ModuleName PSWinUtil
        Mock -CommandName New-Item -ModuleName PSWinUtil
        Mock -CommandName Copy-Item -ModuleName PSWinUtil
        Mock -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil
        Mock -CommandName keytool -ModuleName PSWinUtil -MockWith { $global:LASTEXITCODE = 0 }
    }

    It 'copies cacerts, imports the CRT, and sets the user trust store option' {
        Set-WUJavaExtraCaCertificate -LiteralPath 'C:\Certificates\extra-ca-certs.crt' -JavaHome 'C:\Java\jdk-21'

        Should -Invoke -CommandName Assert-WUCommand -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'keytool'
        }
        Should -Invoke -CommandName New-Item -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Path -eq "$env:USERPROFILE\.certs\java" -and $ItemType -eq 'Directory' -and $Force
        }
        Should -Invoke -CommandName Copy-Item -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $LiteralPath -eq 'C:\Java\jdk-21\lib\security\cacerts' -and
            $Destination -eq "$env:USERPROFILE\.certs\java\cacerts" -and
            $Force
        }
        Should -Invoke -CommandName keytool -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $args -contains '-import' -and
            $args -contains '-trustcacerts' -and
            $args -contains '-alias' -and
            $args -contains 'extra_cert' -and
            $args -contains 'C:\Certificates\extra-ca-certs.crt'
        }
        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'JAVA_TOOL_OPTIONS' -and
            $Value -eq "-Djavax.net.ssl.trustStore=$env:USERPROFILE\.certs\java\cacerts" -and
            $Scope -eq 'User'
        }
    }

    It 'uses JAVA_HOME by default' {
        $oldJavaHome = $env:JAVA_HOME
        try {
            $env:JAVA_HOME = 'C:\Java\jdk-21'
            Set-WUJavaExtraCaCertificate -LiteralPath 'C:\Certificates\extra-ca-certs.crt'

            Should -Invoke -CommandName Copy-Item -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
                $LiteralPath -eq 'C:\Java\jdk-21\lib\security\cacerts'
            }
        } finally {
            $env:JAVA_HOME = $oldJavaHome
        }
    }

    It 'does not change files or environment when WhatIf is used' {
        Set-WUJavaExtraCaCertificate -LiteralPath 'C:\Certificates\extra-ca-certs.crt' -JavaHome 'C:\Java\jdk-21' -WhatIf

        Should -Invoke -CommandName New-Item -ModuleName PSWinUtil -Times 0 -Exactly
        Should -Invoke -CommandName Copy-Item -ModuleName PSWinUtil -Times 0 -Exactly
        Should -Invoke -CommandName keytool -ModuleName PSWinUtil -Times 0 -Exactly
        Should -Invoke -CommandName Set-WUEnvironmentVariable -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'requires JavaHome when JAVA_HOME is not set' {
        $oldJavaHome = $env:JAVA_HOME
        try {
            Remove-Item Env:JAVA_HOME -ErrorAction SilentlyContinue
            { Set-WUJavaExtraCaCertificate -LiteralPath 'C:\Certificates\extra-ca-certs.crt' } |
                Should -Throw '*JAVA_HOME*'
        } finally {
            if ($null -eq $oldJavaHome) {
                Remove-Item Env:JAVA_HOME -ErrorAction SilentlyContinue
            } else {
                $env:JAVA_HOME = $oldJavaHome
            }
        }
    }
}
