function Test-WUTcpPort {
    <#
    .SYNOPSIS
    Tests whether local TCP ports can be bound.

    .DESCRIPTION
    Attempts to bind an exclusive TCP socket to the specified local address and each specified local port. Returns one Boolean value for each port in input order.

    .PARAMETER LocalAddress
    Specifies the local IPv4 or IPv6 address to bind.

    .PARAMETER Port
    Specifies one or more local TCP ports from 1 through 65535. Accepts pipeline input.

    .EXAMPLE
    Test-WUTcpPort -LocalAddress ([System.Net.IPAddress]::Loopback) -Port 8080, 8443

    Returns whether each requested local TCP port can be bound.

    .INPUTS
    System.Int32

    .OUTPUTS
    System.Boolean
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Net.IPAddress]$LocalAddress,

        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(1, 65535)]
        [int[]]$Port
    )

    process {
        foreach ($candidatePort in $Port) {
            $socket = $null
            $canBind = $true
            try {
                $socket = [System.Net.Sockets.Socket]::new(
                    $LocalAddress.AddressFamily,
                    [System.Net.Sockets.SocketType]::Stream,
                    [System.Net.Sockets.ProtocolType]::Tcp
                )
                $socket.ExclusiveAddressUse = $true
                if ($LocalAddress.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetworkV6) {
                    $socket.DualMode = $false
                }
                $socket.Bind([System.Net.IPEndPoint]::new($LocalAddress, $candidatePort))
            } catch [System.Net.Sockets.SocketException] {
                $canBind = $false
            } finally {
                if ($null -ne $socket) {
                    $socket.Dispose()
                }
            }

            $canBind
        }
    }
}
