BeforeAll {
    . (Join-Path -Path $PSScriptRoot -ChildPath '../UnitTestBootstrap.ps1')
}

Describe 'Flutter release metadata contract' -Tag Online {
    It 'resolves a published <Channel> Windows SDK archive' -TestCases @(
        @{ Channel = 'stable' }
        @{ Channel = 'beta' }
    ) {
        param($Channel)
        $uri = [uri](Get-WUFlutterSdkUrl -Channel $Channel -Architecture x64)
        $uri.Scheme | Should -Be 'https'
        $uri.Host | Should -Be 'storage.googleapis.com'
        $uri.AbsolutePath | Should -Match ("/flutter_infra_release/releases/$Channel/windows/.+\.zip$")
        $response = Microsoft.PowerShell.Utility\Invoke-WebRequest -Uri $uri -Method Head -UseBasicParsing
        $response.StatusCode | Should -Be 200
        [long]$response.Headers['Content-Length'] | Should -BeGreaterThan 0
    }
}
