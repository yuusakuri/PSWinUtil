BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')
    $script:KeytoolWasPresent = Test-WUCommand -Name 'keytool'
    if (-not $script:KeytoolWasPresent) {
        Set-Item -Path Function:\global:keytool -Value { }
    }
}

AfterAll {
    if (-not $script:KeytoolWasPresent) {
        Remove-Item -Path Function:\global:keytool
    }
}

Describe 'Additional Java certificate trust' {
    BeforeEach {
        $script:SavedJavaHome = $env:JAVA_HOME
        $script:SavedUserProfile = $env:USERPROFILE
        $script:SavedJavaOptions = $env:JAVA_TOOL_OPTIONS
        $env:JAVA_HOME = Join-Path $TestDrive 'jdk'
        $env:USERPROFILE = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $script:DefaultCacerts = Join-Path $env:JAVA_HOME 'lib/security/cacerts'
        $script:Cacerts = Join-Path $env:USERPROFILE '.certs/java/cacerts'
        $script:Certificate = Join-Path $TestDrive 'extra.crt'
        New-Item -Path (Split-Path $script:DefaultCacerts) -ItemType Directory -Force | Out-Null
        [IO.File]::WriteAllText($script:DefaultCacerts, 'default Java roots')
        [IO.File]::WriteAllText($script:Certificate, 'extra certificate')
        $env:JAVA_TOOL_OPTIONS = 'original options'
        Mock -CommandName keytool -ModuleName PSWinUtil -MockWith {
            $arguments = @($args)
            $store = $arguments[[array]::IndexOf($arguments, '-keystore') + 1]
            $certificate = $arguments[[array]::IndexOf($arguments, '-file') + 1]
            [IO.File]::AppendAllText($store, ';' + [IO.File]::ReadAllText($certificate))
            $global:LASTEXITCODE = 0
        }
    }

    AfterEach {
        $env:JAVA_HOME = $script:SavedJavaHome
        $env:USERPROFILE = $script:SavedUserProfile
        $env:JAVA_TOOL_OPTIONS = $script:SavedJavaOptions
    }

    It 'selects a trust store containing default roots and the extra certificate for Java processes' {
        Set-WUJavaExtraCaCertificate -LiteralPath $script:Certificate -Scope Process

        [IO.File]::ReadAllText($script:Cacerts) | Should -Be 'default Java roots;extra certificate'
        [IO.File]::ReadAllText($script:DefaultCacerts) | Should -Be 'default Java roots'
        $env:JAVA_TOOL_OPTIONS | Should -Be "-Djavax.net.ssl.trustStore=$script:Cacerts"
    }

    It 'leaves trust settings and files unchanged when previewing the certificate setup' {

        Set-WUJavaExtraCaCertificate -LiteralPath $script:Certificate -Scope Process -WhatIf

        $env:JAVA_TOOL_OPTIONS | Should -Be 'original options'
        Test-Path -LiteralPath $script:Cacerts | Should -BeFalse
        [IO.File]::ReadAllText($script:DefaultCacerts) | Should -Be 'default Java roots'
    }
}
