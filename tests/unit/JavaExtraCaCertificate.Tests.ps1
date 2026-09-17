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

Describe 'Java extra certificate environment selection' {
    BeforeEach {
        $script:SavedJavaHome = $env:JAVA_HOME
        $script:SavedUserProfile = $env:USERPROFILE
        $script:SavedJavaOptions = $env:JAVA_TOOL_OPTIONS
        $env:JAVA_HOME = Join-Path $TestDrive 'jdk'
        $env:USERPROFILE = Join-Path $TestDrive 'profile'
        $script:DefaultCacerts = Join-Path $env:JAVA_HOME 'lib/security/cacerts'
        $script:Cacerts = Join-Path $env:USERPROFILE '.certs/java/cacerts'
        $script:Certificate = Join-Path $TestDrive 'extra.crt'
        New-Item -Path (Split-Path $script:DefaultCacerts) -ItemType Directory -Force | Out-Null
        [IO.File]::WriteAllText($script:DefaultCacerts, 'default Java roots')
        [IO.File]::WriteAllText($script:Certificate, 'extra certificate')
        $env:JAVA_TOOL_OPTIONS = 'original options'
        Mock -CommandName keytool -ModuleName PSWinUtil -MockWith {
            $script:KeytoolArguments = @($args)
            $global:LASTEXITCODE = 0
        }
    }

    AfterEach {
        $env:JAVA_HOME = $script:SavedJavaHome
        $env:USERPROFILE = $script:SavedUserProfile
        $env:JAVA_TOOL_OPTIONS = $script:SavedJavaOptions
    }

    It 'copies the JAVA_HOME trust store and configures the selected process scope' {
        Set-WUJavaExtraCaCertificate -LiteralPath $script:Certificate -Scope Process

        [IO.File]::ReadAllText($script:Cacerts) | Should -Be 'default Java roots'
        $script:KeytoolArguments | Should -Contain $script:Certificate
        $script:KeytoolArguments | Should -Contain $script:Cacerts
        $env:JAVA_TOOL_OPTIONS | Should -Be "-Djavax.net.ssl.trustStore=$script:Cacerts"
    }

    It 'requires JAVA_HOME without accepting a duplicate Java installation path' {
        $env:JAVA_HOME = $null

        { Set-WUJavaExtraCaCertificate -LiteralPath $script:Certificate -Scope Process } | Should -Throw '*JAVA_HOME*'

        $env:JAVA_TOOL_OPTIONS | Should -Be 'original options'
        Should -Invoke -CommandName keytool -ModuleName PSWinUtil -Times 0 -Exactly
    }
}
