BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $manifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
    Import-Module -Name $manifestPath -Force -ErrorAction Stop
}

Describe 'Local TCP port binding integration' {
    It 'rejects port zero because it requests dynamic port allocation' {
        InModuleScope -ModuleName PSWinUtil {
            { Test-WUTcpPort -LocalAddress ([System.Net.IPAddress]::Loopback) -Port 0 } |
                Should -Throw
        }
    }

    It 'returns true for a port after its listener is released' {
        $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
        $listener.Start()
        $availablePort = $listener.LocalEndpoint.Port
        $listener.Stop()

        InModuleScope -ModuleName PSWinUtil -Parameters @{ Port = $availablePort } {
            Test-WUTcpPort -LocalAddress ([System.Net.IPAddress]::Loopback) -Port $Port | Should -BeTrue
        }
    }

    It 'returns false while a real listener holds the requested port' {
        $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
        try {
            $listener.Start()
            $listeningPort = $listener.LocalEndpoint.Port

            InModuleScope -ModuleName PSWinUtil -Parameters @{ Port = $listeningPort } {
                Test-WUTcpPort -LocalAddress ([System.Net.IPAddress]::Loopback) -Port $Port | Should -BeFalse
            }
        } finally {
            $listener.Stop()
        }
    }

    It 'tests an IPv6 loopback endpoint independently' -Skip:(-not [System.Net.Sockets.Socket]::OSSupportsIPv6) {
        $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::IPv6Loopback, 0)
        try {
            $listener.Server.DualMode = $false
            $listener.Start()
            $listeningPort = $listener.LocalEndpoint.Port

            InModuleScope -ModuleName PSWinUtil -Parameters @{ Port = $listeningPort } {
                Test-WUTcpPort -LocalAddress ([System.Net.IPAddress]::IPv6Loopback) -Port $Port |
                    Should -BeFalse
                Test-WUTcpPort -LocalAddress ([System.Net.IPAddress]::Loopback) -Port $Port |
                    Should -BeTrue
            }
        } finally {
            $listener.Stop()
        }
    }
}
