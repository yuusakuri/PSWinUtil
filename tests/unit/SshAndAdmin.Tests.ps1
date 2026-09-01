Describe 'New-WUSshKey' {
    BeforeEach {
        InModuleScope -ModuleName PSWinUtil {
            function script:Invoke-WUTestSshKeygen {
                $script:CapturedSshArguments = @($args)
                $fileIndex = [array]::IndexOf([object[]]$args, '-f') + 1
                $keyPath = [string]$args[$fileIndex]
                [System.IO.File]::WriteAllText($keyPath, 'private key')
                [System.IO.File]::WriteAllText("$keyPath.pub", 'public key')
                $global:LASTEXITCODE = 0
            }
            Set-Alias -Name 'ssh-keygen.exe' -Value 'Invoke-WUTestSshKeygen' -Scope Script
        }
    }

    It 'does not create a key with WhatIf' {
        $keyPath = Join-Path -Path $TestDrive -ChildPath 'new-key'

        New-WUSshKey -Path $keyPath -Type ed25519 -WhatIf

        Test-Path -LiteralPath $keyPath | Should -BeFalse
    }

    It 'requires Force when a key file exists' {
        $keyPath = Join-Path -Path $TestDrive -ChildPath 'existing-key'
        [System.IO.File]::WriteAllText($keyPath, 'key')

        { New-WUSshKey -Path $keyPath -WhatIf } | Should -Throw '*Use Force*'
    }

    It 'passes the selected arguments to ssh-keygen' {
        $keyPath = Join-Path -Path $TestDrive -ChildPath 'generated-key'

        $result = New-WUSshKey -Path $keyPath -Type rsa -Bits 3072 -Comment 'test comment' -Passphrase 'test passphrase'
        $capturedArguments = InModuleScope -ModuleName PSWinUtil { $script:CapturedSshArguments }

        $result.FullName | Should -Be $keyPath
        $capturedArguments -join '|' | Should -Be "-q|-t|rsa|-b|3072|-C|test comment|-N|test passphrase|-f|$keyPath"
    }

    It 'preserves empty comment and passphrase arguments' {
        $keyPath = Join-Path -Path $TestDrive -ChildPath 'empty-arguments-key'

        $null = New-WUSshKey -Path $keyPath
        $capturedArguments = InModuleScope -ModuleName PSWinUtil { $script:CapturedSshArguments }
        $expectedArguments = '-q|-t|rsa|-C|""|-N|""|-f|{0}' -f $keyPath

        $capturedArguments -join '|' | Should -Be $expectedArguments
    }

    It 'reports ssh-keygen failures' {
        InModuleScope -ModuleName PSWinUtil {
            function script:Invoke-WUTestSshKeygen {
                'failure details'
                $global:LASTEXITCODE = 7
            }
        }
        $keyPath = Join-Path -Path $TestDrive -ChildPath 'failed-key'

        { New-WUSshKey -Path $keyPath } |
            Should -Throw '*exit code 7*failure details*'
    }
}

Describe 'Edit-WUSshKey' {
    BeforeEach {
        InModuleScope -ModuleName PSWinUtil {
            function script:Invoke-WUTestSshKeygen {
                $script:CapturedSshArguments = @($args)
                $global:LASTEXITCODE = 0
            }
            Set-Alias -Name 'ssh-keygen.exe' -Value 'Invoke-WUTestSshKeygen' -Scope Script
        }
    }

    It 'does not edit a key with WhatIf' {
        $keyPath = Join-Path -Path $TestDrive -ChildPath 'edit-key'
        [System.IO.File]::WriteAllText($keyPath, 'key')

        Edit-WUSshKey -KeyPath $keyPath -CurrentPassphrase '' -Comment 'new comment' -WhatIf

        [System.IO.File]::ReadAllText($keyPath) | Should -Be 'key'
    }

    It 'uses the comment edit arguments' {
        $keyPath = Join-Path -Path $TestDrive -ChildPath 'comment-key'
        [System.IO.File]::WriteAllText($keyPath, 'key')

        $result = Edit-WUSshKey -KeyPath $keyPath -CurrentPassphrase 'current value' -Comment 'updated value'
        $capturedArguments = InModuleScope -ModuleName PSWinUtil { $script:CapturedSshArguments }

        $result.FullName | Should -Be $keyPath
        $capturedArguments -join '|' | Should -Be "-q|-c|-P|current value|-C|updated value|-f|$keyPath"
    }

    It 'preserves empty passphrase arguments' {
        $keyPath = Join-Path -Path $TestDrive -ChildPath 'empty-passphrase-key'
        [System.IO.File]::WriteAllText($keyPath, 'key')

        $null = Edit-WUSshKey -KeyPath $keyPath -CurrentPassphrase '' -NewPassphrase ''
        $capturedArguments = InModuleScope -ModuleName PSWinUtil { $script:CapturedSshArguments }
        $expectedArguments = '-q|-p|-P|""|-N|""|-f|{0}' -f $keyPath

        $capturedArguments -join '|' | Should -Be $expectedArguments
    }

    It 'preserves an empty comment argument' {
        $keyPath = Join-Path -Path $TestDrive -ChildPath 'empty-comment-key'
        [System.IO.File]::WriteAllText($keyPath, 'key')

        $null = Edit-WUSshKey -KeyPath $keyPath -CurrentPassphrase 'current value' -Comment ''
        $capturedArguments = InModuleScope -ModuleName PSWinUtil { $script:CapturedSshArguments }
        $expectedArguments = '-q|-c|-P|current value|-C|""|-f|{0}' -f $keyPath

        $capturedArguments -join '|' | Should -Be $expectedArguments
    }

    It 'uses LiteralPath without wildcard interpretation' {
        $keyPath = Join-Path -Path $TestDrive -ChildPath 'literal[1]-key'
        [System.IO.File]::WriteAllText($keyPath, 'key')
        $parameters = @{
            LiteralPath = $keyPath
            CurrentPassphrase = ''
            Comment = 'updated value'
        }

        $result = Edit-WUSshKey @parameters

        $result.FullName | Should -Be $keyPath
    }
}

Describe 'Start-WUPSScriptAsAdmin' {
    BeforeEach {
        Mock -CommandName Start-Process -ModuleName PSWinUtil -MockWith {}
    }

    It 'builds an encoded elevated script invocation' {
        $scriptFile = Join-Path -Path $TestDrive -ChildPath "script's.ps1"
        [System.IO.File]::WriteAllText($scriptFile, "param([string]`$Value)`n")

        Start-WUPSScriptAsAdmin -Path $scriptFile -ArgumentList 'value with spaces', "quote'value", ''

        $quotedScriptFile = ConvertTo-WUPSStringLiteral -InputObject $scriptFile
        $expectedCommand = "& $quotedScriptFile 'value with spaces' 'quote''value' ''"

        Should -Invoke -CommandName Start-Process -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $FilePath -eq 'powershell.exe' -and
            $Verb -eq 'RunAs' -and
            $ArgumentList[0] -eq '-NoProfile' -and
            $ArgumentList[1] -eq '-EncodedCommand' -and
            [System.Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($ArgumentList[2])) -eq $expectedCommand
        }
    }

    It 'does not start a process with WhatIf' {
        $scriptFile = Join-Path -Path $TestDrive -ChildPath 'what-if.ps1'
        [System.IO.File]::WriteAllText($scriptFile, "Get-Item -Path .`n")

        Start-WUPSScriptAsAdmin -Path $scriptFile -WhatIf

        Should -Invoke -CommandName Start-Process -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'rejects a non-ps1 file' {
        $scriptFile = Join-Path -Path $TestDrive -ChildPath 'script.txt'
        [System.IO.File]::WriteAllText($scriptFile, 'Get-Item -Path .')

        { Start-WUPSScriptAsAdmin -Path $scriptFile } | Should -Throw '*.ps1 extension*'
    }

    It 'uses LiteralPath without wildcard interpretation' {
        $scriptFile = Join-Path -Path $TestDrive -ChildPath 'script[1].ps1'
        [System.IO.File]::WriteAllText($scriptFile, "Get-Item -Path .`n")

        Start-WUPSScriptAsAdmin -LiteralPath $scriptFile -WhatIf

        Should -Invoke -CommandName Start-Process -ModuleName PSWinUtil -Times 0 -Exactly
    }
}
