BeforeAll {
    $repositoryRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    Add-Type -AssemblyName System.Net.Http
    Add-Type -LiteralPath (Join-Path $repositoryRoot 'output/TestSupport/net472/PSWinUtil.TestSupport.dll')
}

Describe 'Loopback HTTP range contract' {
    It 'rejects a 64-bit out-of-range offset without stopping the server' {
        $server = [PSWinUtil.Tests.LoopbackHttpServer]::new([byte[]]@(1, 2, 3))
        $client = [Net.Http.HttpClient]::new()
        try {
            $client.DefaultRequestHeaders.Range = [Net.Http.Headers.RangeHeaderValue]::new(2147483648L, $null)
            $response = $client.GetAsync($server.BaseUri).GetAwaiter().GetResult()
            try {
                [int]$response.StatusCode | Should -Be 416
            } finally {
                $response.Dispose()
            }
            $client.DefaultRequestHeaders.Range = $null
            $response = $client.GetAsync($server.BaseUri).GetAwaiter().GetResult()
            try {
                [int]$response.StatusCode | Should -Be 200
                $response.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult() | Should -Be ([byte[]]@(1, 2, 3))
            } finally {
                $response.Dispose()
            }
        } finally {
            $client.Dispose()
            $server.Dispose()
        }
    }
}
