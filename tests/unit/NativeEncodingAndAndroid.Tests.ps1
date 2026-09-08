BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')
}

Describe 'Set-WUNativeCommandEncoding' {
    BeforeEach {
        $script:SavedInputEncoding = [Console]::InputEncoding
        $script:SavedOutputEncoding = [Console]::OutputEncoding
        $script:SavedPipelineEncoding = $global:OutputEncoding
    }

    AfterEach {
        [Console]::InputEncoding = $script:SavedInputEncoding
        [Console]::OutputEncoding = $script:SavedOutputEncoding
        $global:OutputEncoding = $script:SavedPipelineEncoding
    }

    It 'sets all native command encodings to UTF-8' {
        Set-WUNativeCommandEncoding

        [Console]::InputEncoding.WebName | Should -Be 'utf-8'
        [Console]::OutputEncoding.WebName | Should -Be 'utf-8'
        $global:OutputEncoding.WebName | Should -Be 'utf-8'
        [Console]::OutputEncoding.GetPreamble().Length | Should -Be 0
    }

    It 'does not change encoding with WhatIf' {
        $ascii = [Text.Encoding]::ASCII
        [Console]::InputEncoding = $ascii
        [Console]::OutputEncoding = $ascii
        $global:OutputEncoding = $ascii

        Set-WUNativeCommandEncoding -WhatIf

        [Console]::InputEncoding.WebName | Should -Be 'us-ascii'
        [Console]::OutputEncoding.WebName | Should -Be 'us-ascii'
        $global:OutputEncoding.WebName | Should -Be 'us-ascii'
    }
}

Describe 'ConvertTo-WUNativeCommandArgument' {
    It 'preserves an empty argument in Windows PowerShell' {
        ConvertTo-WUNativeCommandArgument -Argument '' | Should -Be '""'
    }

    It 'returns nonempty arguments unchanged' {
        $arguments = @('plain', 'two words', 'say"hello')

        $result = @($arguments | ConvertTo-WUNativeCommandArgument)

        $result | Should -HaveCount 3
        for ($index = 0; $index -lt $arguments.Count; $index++) {
            $result[$index] | Should -Be $arguments[$index]
        }
    }
}

Describe 'ConvertTo-WUPSStringLiteral' {
    It 'uses single quotation marks by default' {
        ConvertTo-WUPSStringLiteral -InputObject 'plain text' |
            Should -Be "'plain text'"
    }

    It 'doubles embedded single quotation marks' {
        ConvertTo-WUPSStringLiteral -InputObject "It's ready" |
            Should -Be "'It''s ready'"
    }

    It 'represents an empty single-quoted string' {
        ConvertTo-WUPSStringLiteral -InputObject '' |
            Should -Be "''"
    }

    It 'escapes a double-quoted string without changing its value' {
        $value = '$HOME "quoted" ` $(Get-Item .)'
        $expectedLiteral = '"' + '`$HOME `"quoted`" `` `$(Get-Item .)' + '"'

        $literal = ConvertTo-WUPSStringLiteral -InputObject $value -QuoteType Double

        $literal | Should -Be $expectedLiteral
        & ([scriptblock]::Create($literal)) | Should -Be $value
    }

    It 'represents an empty double-quoted string' {
        ConvertTo-WUPSStringLiteral -InputObject '' -QuoteType Double |
            Should -Be '""'
    }

    It 'converts an input array in order' {
        $values = @('first value', '', "third'value")

        $result = @(ConvertTo-WUPSStringLiteral -InputObject $values)

        $result | Should -HaveCount 3
        $result[0] | Should -Be "'first value'"
        $result[1] | Should -Be "''"
        $result[2] | Should -Be "'third''value'"
    }

    It 'accepts strings from the pipeline' {
        $values = @('first', 'second')

        $result = @($values | ConvertTo-WUPSStringLiteral)

        $result | Should -HaveCount 2
        $result[0] | Should -Be "'first'"
        $result[1] | Should -Be "'second'"
    }
}

Describe 'Android virtual devices' {
    BeforeEach {
        InModuleScope -ModuleName PSWinUtil {
            $script:TestAndroidAvds = @('Pixel_API_35', 'Tablet_API_35')
            $script:TestAndroidExitCode = 0
            $script:CapturedAndroidArguments = @()
            $script:TestAdbDevices = @('List of devices attached', '')
            $script:TestAdbExitCode = 0
            $script:TestAndroidEvents = [System.Collections.Generic.List[string]]::new()

            function script:emulator.exe {
                $script:CapturedAndroidArguments = @($args)
                $global:LASTEXITCODE = $script:TestAndroidExitCode
                $script:TestAndroidAvds
            }

            function script:adb.exe {
                $script:TestAndroidEvents.Add(($args -join ' '))
                $global:LASTEXITCODE = $script:TestAdbExitCode
                $script:TestAdbDevices
            }
        }
        Mock -CommandName Get-Command -ModuleName PSWinUtil -MockWith {
            if ($Name -eq 'adb.exe') {
                [pscustomobject]@{ Name = 'adb.exe' }
            } else {
                [pscustomobject]@{ Name = 'emulator.exe' }
            }
        }
        Mock -CommandName Start-Process -ModuleName PSWinUtil -MockWith {
            InModuleScope -ModuleName PSWinUtil -Parameters @{ LaunchArguments = $ArgumentList } {
                $script:TestAndroidEvents.Add("start $($LaunchArguments -join ' ')")
            }
            Get-Process -Id $PID
        }
        Mock -CommandName Start-Sleep -ModuleName PSWinUtil
        Mock -CommandName Stop-Process -ModuleName PSWinUtil
        Mock -CommandName Wait-WUAndroidEmulator -ModuleName PSWinUtil
        Mock -CommandName Test-WUTcpPort -ModuleName PSWinUtil -MockWith {
            foreach ($candidatePort in $Port) {
                $true
            }
        }
    }

    It 'lists every local Android virtual device without starting a process' {
        $names = @(Get-WUAndroidEmulator)

        $names | Should -HaveCount 2
        $names[0] | Should -BeExactly 'Pixel_API_35'
        $names[1] | Should -BeExactly 'Tablet_API_35'
        InModuleScope -ModuleName PSWinUtil {
            $script:CapturedAndroidArguments | Should -HaveCount 1
            $script:CapturedAndroidArguments[0] | Should -BeExactly '-list-avds'
        }
        Should -Invoke -CommandName Start-Process -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'returns no names when no virtual devices are registered' {
        InModuleScope -ModuleName PSWinUtil {
            $script:TestAndroidAvds = @()
        }

        @(Get-WUAndroidEmulator) | Should -HaveCount 0
    }

    It 'trims names and ignores blank lines' {
        InModuleScope -ModuleName PSWinUtil {
            $script:TestAndroidAvds = @('', '  Pixel_API_35  ', ' ', 'Tablet_API_35', '')
        }

        $names = @(Get-WUAndroidEmulator)

        $names | Should -HaveCount 2
        $names[0] | Should -BeExactly 'Pixel_API_35'
        $names[1] | Should -BeExactly 'Tablet_API_35'
    }

    It 'requires emulator.exe on PATH when listing devices' {
        Mock -CommandName Get-Command -ModuleName PSWinUtil

        { Get-WUAndroidEmulator } | Should -Throw '*not found on PATH*'
    }

    It 'reports a list command failure without returning device names' {
        InModuleScope -ModuleName PSWinUtil {
            $script:TestAndroidExitCode = 1
            $script:TestAndroidAvds = @('Pixel_API_35', 'list error')
        }
        $names = @()

        { $names += Get-WUAndroidEmulator } | Should -Throw '*exit code 1*list error*'
        $names | Should -HaveCount 0
    }

    It 'requires emulator.exe on PATH' {
        Mock -CommandName Get-Command -ModuleName PSWinUtil

        { Start-WUAndroidEmulator } | Should -Throw '*not found on PATH*'
    }

    It 'reports a list command failure' {
        InModuleScope -ModuleName PSWinUtil {
            $script:TestAndroidExitCode = 1
            $script:TestAndroidAvds = @('list error')
        }

        { Start-WUAndroidEmulator } | Should -Throw '*exit code 1*'
        Should -Invoke -CommandName Start-Process -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'requires at least one Android virtual device' {
        InModuleScope -ModuleName PSWinUtil {
            $script:TestAndroidAvds = @()
        }

        { Start-WUAndroidEmulator } | Should -Throw '*No Android virtual device*'
    }

    It 'starts every Android virtual device by default' {
        $processes = @(Start-WUAndroidEmulator)

        $processes | Should -HaveCount 2
        foreach ($process in $processes) {
            $process | Should -BeOfType ([System.Diagnostics.Process])
        }
        Should -Invoke -CommandName Start-Process -ModuleName PSWinUtil -Times 2 -Exactly
        Should -Invoke -CommandName Start-Process -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $FilePath -eq 'emulator.exe' -and
            ($ArgumentList -join ' ') -eq '-avd "Pixel_API_35" -port 5554' -and
            $PassThru
        }
        Should -Invoke -CommandName Start-Process -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $FilePath -eq 'emulator.exe' -and
            ($ArgumentList -join ' ') -eq '-avd "Tablet_API_35" -port 5556' -and
            $PassThru
        }
        InModuleScope -ModuleName PSWinUtil {
            ($script:TestAndroidEvents -join ';') | Should -BeExactly (
                'devices;start -avd "Pixel_API_35" -port 5554;' +
                'start -avd "Tablet_API_35" -port 5556'
            )
        }
        Should -Invoke -CommandName Wait-WUAndroidEmulator -ModuleName PSWinUtil -Times 1 -Exactly
    }

    It 'starts the selected Android virtual device' {
        Start-WUAndroidEmulator -Name 'Tablet_API_35'

        Should -Invoke -CommandName Start-Process -ModuleName PSWinUtil -Times 1 -Exactly
        Should -Invoke -CommandName Start-Process -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            ($ArgumentList -join ' ') -eq '-avd "Tablet_API_35" -port 5554'
        }
    }

    It 'rejects an unknown Android virtual device name' {
        { Start-WUAndroidEmulator -Name 'Missing_API' } | Should -Throw '*was not found*'

        Should -Invoke -CommandName Start-Process -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'rejects an unknown Name with an explicit Port before checking port availability' {
        { Start-WUAndroidEmulator -Name 'Missing_AVD' -Port 5554 } | Should -Throw '*was not found*'

        Should -Invoke -CommandName Start-Process -ModuleName PSWinUtil -Times 0 -Exactly
        Should -Invoke -CommandName Test-WUTcpPort -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'quotes valid AVD names that contain spaces and parentheses' {
        InModuleScope -ModuleName PSWinUtil {
            $script:TestAndroidAvds = @('Example Device (API 35)')
        }

        Start-WUAndroidEmulator -Name 'Example Device (API 35)' -NoWait

        Should -Invoke -CommandName Start-Process -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            ($ArgumentList -join ' ') -eq '-avd "Example Device (API 35)" -port 5554'
        }
    }

    It 'does not start a process with WhatIf' {
        Start-WUAndroidEmulator -WhatIf

        Should -Invoke -CommandName Start-Process -ModuleName PSWinUtil -Times 0 -Exactly
        InModuleScope -ModuleName PSWinUtil {
            $script:TestAndroidEvents | Should -HaveCount 0
        }
    }

    It 'returns the first emulator port as an integer when adb reports no emulators' {
        $port = Get-WUAndroidEmulatorPort

        $port | Should -BeOfType ([int])
        $port | Should -Be 5554
    }

    It 'ignores non-emulator devices and skips occupied ports regardless of device state' {
        InModuleScope -ModuleName PSWinUtil {
            $script:TestAdbDevices = @(
                'List of devices attached'
                'emulator-5554 device'
                "emulator-5556`toffline"
                'emulator-5558 unauthorized'
                'emulator-5560x device'
                'phone-emulator-5560 device'
                '127.0.0.1:5560 device'
                '* daemon started successfully'
            )
        }

        Get-WUAndroidEmulatorPort | Should -Be 5560
    }

    It 'uses the first gap instead of the port after the highest occupied port' {
        InModuleScope -ModuleName PSWinUtil {
            $script:TestAdbDevices = @('emulator-5554 device', 'emulator-5558 device')
        }

        Get-WUAndroidEmulatorPort | Should -Be 5556
    }

    It 'ignores adb serials outside the supported even console port range' {
        InModuleScope -ModuleName PSWinUtil {
            $script:TestAdbDevices = @(
                'emulator-5552 device'
                'emulator-5555 device'
                'emulator-5684 device'
                'emulator-99999 device'
                'emulator-999999999999999999999999 device'
                'emulator-5554 device'
            )

            @(Get-WUAndroidEmulatorUnavailablePort) | Should -Be @(5554)
        }
    }

    It 'excludes a console port when <Address> port <UnavailablePort> cannot be bound' -ForEach @(
        @{ Address = [System.Net.IPAddress]::Loopback; UnavailablePort = 5554 }
        @{ Address = [System.Net.IPAddress]::Loopback; UnavailablePort = 5555 }
        @{ Address = [System.Net.IPAddress]::IPv6Loopback; UnavailablePort = 5554 }
        @{ Address = [System.Net.IPAddress]::IPv6Loopback; UnavailablePort = 5555 }
    ) {
        Mock -CommandName Test-WUTcpPort -ModuleName PSWinUtil -MockWith {
            foreach ($candidatePort in $Port) {
                -not ($LocalAddress.Equals($Address) -and $candidatePort -eq $UnavailablePort)
            }
        }

        Get-WUAndroidEmulatorPort | Should -Be 5556
        { Start-WUAndroidEmulator -Name 'Pixel_API_35' -Port 5554 } | Should -Throw '*console port 5554 is unavailable*'
        Should -Invoke -CommandName Start-Process -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'does not assign the highest console port when its adjacent adb port cannot be bound' {
        Mock -CommandName Test-WUTcpPort -ModuleName PSWinUtil -MockWith {
            foreach ($candidatePort in $Port) {
                -not ($LocalAddress.Equals([System.Net.IPAddress]::IPv6Loopback) -and $candidatePort -eq 5683)
            }
        }

        InModuleScope -ModuleName PSWinUtil {
            @(Get-WUAndroidEmulatorUnavailablePort) | Should -Be @(5682)
        }
    }

    It 'can select the last supported console port' {
        InModuleScope -ModuleName PSWinUtil {
            $script:TestAdbDevices = @(for ($port = 5554; $port -lt 5682; $port += 2) {
                    "emulator-$port device"
                })
        }

        Get-WUAndroidEmulatorPort | Should -Be 5682
    }

    It 'reports exhaustion without starting a process' {
        InModuleScope -ModuleName PSWinUtil {
            $script:TestAdbDevices = @(for ($port = 5554; $port -le 5682; $port += 2) {
                    "emulator-$port device"
                })
        }

        { Get-WUAndroidEmulatorPort } | Should -Throw '*Only 0 Android emulator console ports*'
        { Start-WUAndroidEmulator } | Should -Throw '*Only 0 Android emulator console ports*'
        Should -Invoke -CommandName Start-Process -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'requires adb.exe for port selection and startup even with NoWait' {
        Mock -CommandName Get-Command -ModuleName PSWinUtil -ParameterFilter { $Name -eq 'adb.exe' }

        { Get-WUAndroidEmulatorPort } | Should -Throw '*adb.exe was not found on PATH*'
        { Start-WUAndroidEmulator -NoWait } | Should -Throw '*adb.exe was not found on PATH*'
        Should -Invoke -CommandName Start-Process -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'reports adb devices failures without allocating a port or starting a process' {
        InModuleScope -ModuleName PSWinUtil {
            $script:TestAdbExitCode = 1
            $script:TestAdbDevices = @('cannot connect to daemon')
        }

        { Get-WUAndroidEmulatorPort } | Should -Throw '*exit code 1*cannot connect to daemon*'
        { Start-WUAndroidEmulator -Name 'Pixel_API_35' -Port 5554 } | Should -Throw '*exit code 1*'
        Should -Invoke -CommandName Start-Process -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'starts on an explicit port and waits for its exact serial' {
        $process = Start-WUAndroidEmulator -Name 'Tablet_API_35' -Port 5682

        $process | Should -BeOfType ([System.Diagnostics.Process])
        Should -Invoke -CommandName Start-Process -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            ($ArgumentList -join ' ') -eq '-avd "Tablet_API_35" -port 5682'
        }
        Should -Invoke -CommandName Wait-WUAndroidEmulator -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            @($Emulator.Serial).Count -eq 1 -and $Emulator[0].Serial -eq 'emulator-5682'
        }
    }

    It 'rejects invalid console port <Port>' -ForEach @(
        @{ Port = 5553 }
        @{ Port = 5555 }
        @{ Port = 5683 }
        @{ Port = 0 }
    ) {
        { Start-WUAndroidEmulator -Name 'Pixel_API_35' -Port $Port } | Should -Throw

        Should -Invoke -CommandName Start-Process -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'requires Name with Port even when there is only one local AVD' {
        InModuleScope -ModuleName PSWinUtil {
            $script:TestAndroidAvds = @('Pixel_API_35')
        }

        { Start-WUAndroidEmulator -Port 5554 } | Should -Throw '*Port requires exactly one Name*'
        Should -Invoke -CommandName Start-Process -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'requires exactly one Name when Port is specified' {
        { Start-WUAndroidEmulator -Name 'Pixel_API_35', 'Tablet_API_35' -Port 5554 } |
            Should -Throw '*Port requires exactly one Name*'

        Should -Invoke -CommandName Start-Process -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'starts an arbitrary subset of virtual devices in the requested order' {
        InModuleScope -ModuleName PSWinUtil {
            $script:TestAndroidAvds = @('Phone_API_35', 'Tablet_API_35', 'Watch_API_35')
        }

        $processes = @(Start-WUAndroidEmulator -Name 'Watch_API_35', 'Phone_API_35' -NoWait)

        $processes | Should -HaveCount 2
        InModuleScope -ModuleName PSWinUtil {
            @($script:TestAndroidEvents) | Should -Be @(
                'devices'
                'start -avd "Watch_API_35" -port 5554'
                'start -avd "Phone_API_35" -port 5556'
            )
        }
    }

    It 'rejects a duplicate Name before checking port availability' {
        { Start-WUAndroidEmulator -Name 'Pixel_API_35', 'Pixel_API_35' -NoWait } |
            Should -Throw '*only once*'

        Should -Invoke -CommandName Test-WUTcpPort -ModuleName PSWinUtil -Times 0 -Exactly
        Should -Invoke -CommandName Start-Process -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'rejects a specified port already reported as <State>' -ForEach @(
        @{ State = 'device' }
        @{ State = 'offline' }
        @{ State = 'unauthorized' }
    ) {
        InModuleScope -ModuleName PSWinUtil -Parameters @{ DeviceState = $State } {
            $script:TestAdbDevices = @("emulator-5554 $DeviceState")
        }

        { Start-WUAndroidEmulator -Name 'Pixel_API_35' -Port 5554 } | Should -Throw '*console port 5554 is unavailable*'
        Should -Invoke -CommandName Start-Process -ModuleName PSWinUtil -Times 0 -Exactly
        Should -Invoke -CommandName Start-Sleep -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'automatically skips ports already reported by adb' {
        InModuleScope -ModuleName PSWinUtil {
            $script:TestAdbDevices = @('emulator-5554 offline', 'emulator-5556 device')
        }

        Start-WUAndroidEmulator -Name 'Pixel_API_35'

        Should -Invoke -CommandName Start-Process -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            ($ArgumentList -join ' ') -eq '-avd "Pixel_API_35" -port 5558'
        }
    }

    It 'assigns distinct ports to all AVDs with NoWait before adb registers them' {
        $processes = @(Start-WUAndroidEmulator -NoWait)

        $processes | Should -HaveCount 2
        InModuleScope -ModuleName PSWinUtil {
            ($script:TestAndroidEvents -join ';') | Should -BeExactly (
                'devices;start -avd "Pixel_API_35" -port 5554;' +
                'start -avd "Tablet_API_35" -port 5556'
            )
        }
        Should -Invoke -CommandName Start-Sleep -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'does not wait for a named device with NoWait' {
        Start-WUAndroidEmulator -Name 'Pixel_API_35' -Port 5556 -NoWait

        InModuleScope -ModuleName PSWinUtil {
            ($script:TestAndroidEvents -join ';') | Should -BeExactly 'devices;start -avd "Pixel_API_35" -port 5556'
        }
    }

    It 'handles native adb devices stderr under Windows PowerShell ErrorAction Stop' -Skip:($PSVersionTable.PSEdition -ne 'Desktop') {
        $script:TestAdbCommandPath = Join-Path -Path $TestDrive -ChildPath 'adb.cmd'
        $commandText = @'
@echo off
if "%~1"=="devices" (
    echo * daemon started successfully 1>&2
    echo List of devices attached
    echo emulator-5554 offline
    exit /b 0
)
echo unexpected adb command 1>&2
exit /b 1
'@
        [IO.File]::WriteAllText($script:TestAdbCommandPath, $commandText.Replace("`n", "`r`n"), [Text.Encoding]::ASCII)
        InModuleScope -ModuleName PSWinUtil -Parameters @{ CommandPath = $script:TestAdbCommandPath } {
            $script:TestNativeAdbPath = $CommandPath
            function script:adb.exe {
                & $script:TestNativeAdbPath @args
            }
        }

        Get-WUAndroidEmulatorPort -ErrorAction Stop | Should -Be 5556
    }

    It 'keeps every launched emulator running when adb waiting fails' {
        Mock -CommandName Wait-WUAndroidEmulator -ModuleName PSWinUtil -MockWith {
            throw 'Timed out waiting for emulator-5554.'
        }

        { Start-WUAndroidEmulator } | Should -Throw '*Timed out*emulator-5554*'

        Should -Invoke -CommandName Start-Process -ModuleName PSWinUtil -Times 2 -Exactly
        Should -Invoke -CommandName Stop-Process -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'keeps an earlier emulator running when a later launch fails' {
        InModuleScope -ModuleName PSWinUtil {
            $script:TestLaunchAttempt = 0
        }
        Mock -CommandName Start-Process -ModuleName PSWinUtil -MockWith {
            InModuleScope -ModuleName PSWinUtil {
                $script:TestLaunchAttempt++
                if ($script:TestLaunchAttempt -eq 2) {
                    throw 'process launch failure'
                }
                Get-Process -Id $PID
            }
        }

        { Start-WUAndroidEmulator } | Should -Throw '*process launch failure*'

        Should -Invoke -CommandName Stop-Process -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'collects port availability once when selecting three ports' {
        InModuleScope -ModuleName PSWinUtil {
            $script:TestAdbDevices = @('emulator-5556 offline')
        }

        @(Get-WUAndroidEmulatorPort -Count 3) | Should -Be @(5554, 5558, 5560)

        Should -Invoke -CommandName Test-WUTcpPort -ModuleName PSWinUtil -Times 2 -Exactly -ParameterFilter {
            ($Port -join ',') -eq ((5554..5683) -join ',')
        }
        Should -Invoke -CommandName Test-WUTcpPort -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $LocalAddress.Equals([System.Net.IPAddress]::Loopback)
        }
        Should -Invoke -CommandName Test-WUTcpPort -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $LocalAddress.Equals([System.Net.IPAddress]::IPv6Loopback)
        }
        InModuleScope -ModuleName PSWinUtil {
            @($script:TestAndroidEvents) | Should -Be @('devices')
        }
    }

    It 'maps and deduplicates adb and TCP port pairs' {
        InModuleScope -ModuleName PSWinUtil {
            $script:TestAdbDevices = @('emulator-5554 device', 'emulator-5554 offline')
        }
        Mock -CommandName Test-WUTcpPort -ModuleName PSWinUtil -MockWith {
            foreach ($candidatePort in $Port) {
                $candidatePort -notin 5554, 5555, 5556, 5557
            }
        }

        InModuleScope -ModuleName PSWinUtil {
            @(Get-WUAndroidEmulatorUnavailablePort) | Should -Be @(5554, 5556)
        }
        Should -Invoke -CommandName Test-WUTcpPort -ModuleName PSWinUtil -Times 2 -Exactly
    }

    It 'returns ordered Boolean results for a port array' {
        InModuleScope -ModuleName PSWinUtil {
            $script:TestAdbDevices = @('emulator-5554 offline')
        }
        Mock -CommandName Test-WUTcpPort -ModuleName PSWinUtil -MockWith {
            foreach ($candidatePort in $Port) {
                $candidatePort -ne 5559
            }
        }

        $results = @(Test-WUAndroidEmulatorPort -Port 5556, 5554, 5558, 5556)

        $results | Should -Be @($true, $false, $false, $true)
        foreach ($result in $results) {
            $result | Should -BeOfType ([bool])
        }
        Should -Invoke -CommandName Test-WUTcpPort -ModuleName PSWinUtil -Times 2 -Exactly
    }

    It 'uses one availability observation for all pipeline inputs' {
        InModuleScope -ModuleName PSWinUtil {
            $script:TestAdbDevices = @('emulator-5554 device')
        }

        @(5554, 5556, 5558 | Test-WUAndroidEmulatorPort) | Should -Be @($false, $true, $true)

        Should -Invoke -CommandName Test-WUTcpPort -ModuleName PSWinUtil -Times 2 -Exactly
        InModuleScope -ModuleName PSWinUtil {
            @($script:TestAndroidEvents) | Should -Be @('devices')
        }
    }

    It 'rejects invalid ports inside a direct input array' -ForEach @(
        @{ InvalidPort = 5553 }
        @{ InvalidPort = 5555 }
        @{ InvalidPort = 5683 }
    ) {
        { Test-WUAndroidEmulatorPort -Port 5554, $InvalidPort } | Should -Throw

        Should -Invoke -CommandName Test-WUTcpPort -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'rejects an invalid pipeline port' {
        { 5555 | Test-WUAndroidEmulatorPort -ErrorAction Stop } | Should -Throw
    }

    It 'selects one or several distinct ports in ascending order' {
        InModuleScope -ModuleName PSWinUtil {
            Select-WUAndroidEmulatorPort -UnavailablePort 5554, 5558 | Should -Be 5556
            @(Select-WUAndroidEmulatorPort -UnavailablePort 5554, 5558 -Count 3) | Should -Be @(5556, 5560, 5562)
            @(Select-WUAndroidEmulatorPort -UnavailablePort 5554 -Count 64) | Should -Be @(5556..5682 | Where-Object { $_ % 2 -eq 0 })
        }
    }

    It 'rejects invalid requested counts before discovering ports' -ForEach @(
        @{ Count = 0 }
        @{ Count = 65 }
    ) {
        { Get-WUAndroidEmulatorPort -Count $Count } | Should -Throw
        InModuleScope -ModuleName PSWinUtil -Parameters @{ RequestedCount = $Count } {
            { Select-WUAndroidEmulatorPort -Count $RequestedCount } | Should -Throw
        }
        Should -Invoke -CommandName Test-WUTcpPort -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'does not return partial ports or start devices when too few ports remain' {
        InModuleScope -ModuleName PSWinUtil {
            $script:TestAdbDevices = @(for ($port = 5556; $port -le 5682; $port += 2) {
                    "emulator-$port device"
                })
        }
        $receivedPorts = [System.Collections.Generic.List[int]]::new()

        { Get-WUAndroidEmulatorPort -Count 2 | ForEach-Object { $receivedPorts.Add($_) } } |
            Should -Throw '*Only 1*but 2 were requested*'
        { Start-WUAndroidEmulator -NoWait } | Should -Throw '*Only 1*but 2 were requested*'

        $receivedPorts | Should -HaveCount 0
        Should -Invoke -CommandName Start-Process -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'launches all three devices once before passing the whole group to the waiter' {
        InModuleScope -ModuleName PSWinUtil {
            $script:TestAndroidAvds = @('Phone_API_35', 'Tablet_API_35', 'Watch_API_35')
        }
        Mock -CommandName Wait-WUAndroidEmulator -ModuleName PSWinUtil -MockWith {
            InModuleScope -ModuleName PSWinUtil {
                @($script:TestAndroidEvents | Where-Object { $_ -like 'start *' }) | Should -HaveCount 3
            }
            @($Emulator.Name) | Should -Be @('Phone_API_35', 'Tablet_API_35', 'Watch_API_35')
            @($Emulator.Port) | Should -Be @(5554, 5556, 5558)
            @($Emulator.Serial) | Should -Be @('emulator-5554', 'emulator-5556', 'emulator-5558')
            $script:WaitedProcesses = @($Emulator.Process)
        }

        $processes = @(Start-WUAndroidEmulator)

        Should -Invoke -CommandName Start-Process -ModuleName PSWinUtil -Times 3 -Exactly
        Should -Invoke -CommandName Wait-WUAndroidEmulator -ModuleName PSWinUtil -Times 1 -Exactly
        Should -Invoke -CommandName Test-WUTcpPort -ModuleName PSWinUtil -Times 2 -Exactly
        $processes | Should -HaveCount 3
        for ($index = 0; $index -lt 3; $index++) {
            $processes[$index] | Should -BeOfType ([System.Diagnostics.Process])
            [object]::ReferenceEquals($processes[$index], $script:WaitedProcesses[$index]) | Should -BeTrue
        }
    }

    It 'does not invoke the waiter with NoWait or WhatIf' {
        Mock -CommandName Wait-WUAndroidEmulator -ModuleName PSWinUtil

        @(Start-WUAndroidEmulator -NoWait) | Should -HaveCount 2
        @(Start-WUAndroidEmulator -WhatIf) | Should -HaveCount 0

        Should -Invoke -CommandName Wait-WUAndroidEmulator -ModuleName PSWinUtil -Times 0 -Exactly
        Should -Invoke -CommandName Start-Process -ModuleName PSWinUtil -Times 2 -Exactly
    }

    It 'completes current AVD names with case-insensitive prefix filtering' {
        InModuleScope -ModuleName PSWinUtil {
            $script:TestAndroidAvds = @('Example_API_35', 'Example_API_35_Copy', 'Pixel_API_35')
        }
        $inputText = 'Start-WUAndroidEmulator -Name EXA'

        $completion = [System.Management.Automation.CommandCompletion]::CompleteInput($inputText, $inputText.Length, $null)

        @($completion.CompletionMatches.ListItemText) | Should -Be @('Example_API_35', 'Example_API_35_Copy')
        @($completion.CompletionMatches.CompletionText) | Should -Be @("'Example_API_35'", "'Example_API_35_Copy'")
        InModuleScope -ModuleName PSWinUtil {
            $script:TestAndroidAvds = @('Example_API_36')
        }

        $completion = [System.Management.Automation.CommandCompletion]::CompleteInput($inputText, $inputText.Length, $null)

        @($completion.CompletionMatches.ListItemText) | Should -Be @('Example_API_36')
        Should -Invoke -CommandName Start-Process -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'returns every AVD name when completing an empty Name' {
        $inputText = 'Start-WUAndroidEmulator -Name '

        $completion = [System.Management.Automation.CommandCompletion]::CompleteInput($inputText, $inputText.Length, $null)

        @($completion.CompletionMatches.ListItemText) | Should -Be @('Pixel_API_35', 'Tablet_API_35')
    }

    It 'does not leak an emulator listing failure from the argument completer' {
        InModuleScope -ModuleName PSWinUtil {
            $script:TestAndroidExitCode = 1
            $script:TestAndroidAvds = @('failed to list devices')
        }
        $inputText = 'Start-WUAndroidEmulator -Name Missing_API_'

        $completion = [System.Management.Automation.CommandCompletion]::CompleteInput($inputText, $inputText.Length, $null)

        @($completion.CompletionMatches) | Should -HaveCount 0
    }
}

Describe 'Wait-WUAndroidEmulator' {
    BeforeEach {
        Mock -CommandName Start-Sleep -ModuleName PSWinUtil
        Mock -CommandName Stop-Process -ModuleName PSWinUtil
    }

    It 'starts every adb waiter before monitoring and does not query boot completion' {
        InModuleScope -ModuleName PSWinUtil {
            $script:TestWaitEvents = [System.Collections.Generic.List[string]]::new()
            $script:TestWaiterId = 200
            $script:TestWaitEmulators = @(
                foreach ($port in 5554, 5556, 5558) {
                    $process = [pscustomobject]@{ Id = $port; HasExited = $false; ExitCode = 0 }
                    $process | Add-Member -MemberType ScriptMethod -Name Refresh -Value {
                        $script:TestWaitEvents.Add("emulator $($this.Id) refresh")
                    }
                    [pscustomobject]@{
                        Serial = "emulator-$port"
                        Process = $process
                    }
                }
            )
        }
        Mock -CommandName Start-Process -ModuleName PSWinUtil -MockWith {
            InModuleScope -ModuleName PSWinUtil -Parameters @{ WaitArguments = $ArgumentList } {
                $script:TestWaitEvents.Add("start $($WaitArguments -join ' ')")
                $script:TestWaiterId++
                $process = [pscustomobject]@{
                    Id = $script:TestWaiterId
                    HasExited = $true
                    ExitCode = 0
                }
                $process | Add-Member -MemberType ScriptMethod -Name Refresh -Value {
                    $script:TestWaitEvents.Add("waiter $($this.Id) refresh")
                }
                $process | Add-Member -MemberType ScriptMethod -Name WaitForExit -Value {}
                $process
            }
        }

        InModuleScope -ModuleName PSWinUtil {
            Wait-WUAndroidEmulator -Emulator $script:TestWaitEmulators -TimeoutSeconds 30

            @($script:TestWaitEvents)[0..2] | Should -Be @(
                'start -s emulator-5554 wait-for-device'
                'start -s emulator-5556 wait-for-device'
                'start -s emulator-5558 wait-for-device'
            )
        }
        Should -Invoke -CommandName Start-Process -ModuleName PSWinUtil -Times 3 -Exactly -ParameterFilter {
            $FilePath -eq 'adb.exe' -and
            $ArgumentList.Count -eq 3 -and
            $ArgumentList[0] -eq '-s' -and
            $ArgumentList[2] -eq 'wait-for-device' -and
            $PassThru -and
            $NoNewWindow
        }
        Should -Invoke -CommandName Start-Process -ModuleName PSWinUtil -Times 0 -Exactly -ParameterFilter {
            $ArgumentList -contains 'getprop' -or $ArgumentList -contains 'sys.boot_completed'
        }
        Should -Invoke -CommandName Stop-Process -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'reports an emulator process that exits without stopping the emulator or adb waiter' {
        InModuleScope -ModuleName PSWinUtil {
            $script:TestExitedEmulator = [pscustomobject]@{ Id = 101; HasExited = $true; ExitCode = 7 }
            $script:TestExitedEmulator | Add-Member -MemberType ScriptMethod -Name Refresh -Value {}
            $script:TestRunningWaiter = [pscustomobject]@{
                Id = 201
                HasExited = $false
                ExitCode = 0
                WaitConfirmed = $false
            }
            $script:TestRunningWaiter | Add-Member -MemberType ScriptMethod -Name Refresh -Value {}
            $script:TestRunningWaiter | Add-Member -MemberType ScriptMethod -Name WaitForExit -Value {
                $this.HasExited = $true
                $this.WaitConfirmed = $true
            }
        }
        Mock -CommandName Start-Process -ModuleName PSWinUtil -MockWith {
            InModuleScope -ModuleName PSWinUtil { $script:TestRunningWaiter }
        }

        InModuleScope -ModuleName PSWinUtil {
            $emulator = [pscustomobject]@{
                Serial = 'emulator-5554'
                Process = $script:TestExitedEmulator
            }
            { Wait-WUAndroidEmulator -Emulator $emulator -TimeoutSeconds 30 } |
                Should -Throw '*emulator-5554 exited*exit code 7*'
            $script:TestRunningWaiter.WaitConfirmed | Should -BeFalse
        }
        Should -Invoke -CommandName Stop-Process -ModuleName PSWinUtil -Times 0 -Exactly
    }

    It 'stops and joins only unfinished adb waiters when the group times out' {
        InModuleScope -ModuleName PSWinUtil {
            $script:TestAliveEmulators = @(
                foreach ($port in 5554, 5556) {
                    $process = [pscustomobject]@{ Id = $port; HasExited = $false; ExitCode = 0 }
                    $process | Add-Member -MemberType ScriptMethod -Name Refresh -Value {}
                    [pscustomobject]@{ Serial = "emulator-$port"; Process = $process }
                }
            )
            $script:TestCompletedWaiter = [pscustomobject]@{ Id = 201; HasExited = $true; ExitCode = 0 }
            $script:TestCompletedWaiter | Add-Member -MemberType ScriptMethod -Name Refresh -Value {}
            $script:TestCompletedWaiter | Add-Member -MemberType ScriptMethod -Name WaitForExit -Value {}
            $script:TestPendingWaiter = [pscustomobject]@{
                Id = 202
                HasExited = $false
                ExitCode = 0
                WaitConfirmed = $false
            }
            $script:TestPendingWaiter | Add-Member -MemberType ScriptMethod -Name Refresh -Value {}
            $script:TestPendingWaiter | Add-Member -MemberType ScriptMethod -Name WaitForExit -Value {
                $this.HasExited = $true
                $this.WaitConfirmed = $true
            }
            $script:TestWaiterQueue = [System.Collections.Queue]::new()
            $script:TestWaiterQueue.Enqueue($script:TestCompletedWaiter)
            $script:TestWaiterQueue.Enqueue($script:TestPendingWaiter)
        }
        Mock -CommandName Start-Process -ModuleName PSWinUtil -MockWith {
            InModuleScope -ModuleName PSWinUtil { $script:TestWaiterQueue.Dequeue() }
        }
        Mock -CommandName Start-Sleep -ModuleName PSWinUtil -MockWith {
            [System.Threading.Thread]::Sleep(1100)
        }

        InModuleScope -ModuleName PSWinUtil {
            { Wait-WUAndroidEmulator -Emulator $script:TestAliveEmulators -TimeoutSeconds 1 } |
                Should -Throw '*after 1 seconds*emulator-5556*'
            $script:TestPendingWaiter.WaitConfirmed | Should -BeTrue
        }
        Should -Invoke -CommandName Stop-Process -ModuleName PSWinUtil -Times 1 -Exactly -ParameterFilter {
            $Id -eq 202 -and $Force
        }
        Should -Invoke -CommandName Stop-Process -ModuleName PSWinUtil -Times 0 -Exactly -ParameterFilter {
            $Id -in 5554, 5556, 201
        }
    }
}

Describe 'Get-WUAndroidCommandLineToolsUrl' {
    It 'returns the Windows package URL from the official page' {
        Mock -CommandName Invoke-WebRequest -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{
                Content = 'commandlinetools-win-123456_latest.zip commandlinetools-win-123456_latest.zip'
            }
        }

        Get-WUAndroidCommandLineToolsUrl |
            Should -Be 'https://dl.google.com/android/repository/commandlinetools-win-123456_latest.zip'
    }

    It 'reports an HTTP request failure' {
        Mock -CommandName Invoke-WebRequest -ModuleName PSWinUtil -MockWith {
            throw 'network failure'
        }

        { Get-WUAndroidCommandLineToolsUrl } | Should -Throw '*network failure*'
    }

    It 'reports a missing Windows package name' {
        Mock -CommandName Invoke-WebRequest -ModuleName PSWinUtil -MockWith {
            [pscustomobject]@{ Content = 'No Windows package is present.' }
        }

        { Get-WUAndroidCommandLineToolsUrl } | Should -Throw '*package was not found*'
    }
}
