BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $manifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
    Import-Module -Name $manifestPath -Force -ErrorAction Stop
    $script:Module = Get-Module -Name 'PSWinUtil' -ErrorAction Stop

    Add-Type -AssemblyName 'System.Net.Http' -ErrorAction Stop
    if ($null -eq ('PSWinUtil.Tests.StaticHttpMessageHandler' -as [type])) {
        $typeDefinition = @'
namespace PSWinUtil.Tests
{
    using System;
    using System.Net;
    using System.Net.Http;
    using System.Threading;
    using System.Threading.Tasks;

    public sealed class StaticHttpMessageHandler : HttpMessageHandler
    {
        private readonly byte[] body;
        private readonly HttpStatusCode statusCode;

        public StaticHttpMessageHandler(byte[] body, HttpStatusCode statusCode)
        {
            this.body = body;
            this.statusCode = statusCode;
        }

        public Uri RequestUri { get; private set; }

        protected override Task<HttpResponseMessage> SendAsync(
            HttpRequestMessage request,
            CancellationToken cancellationToken)
        {
            this.RequestUri = request.RequestUri;
            var response = new HttpResponseMessage(this.statusCode);
            response.Content = new ByteArrayContent(this.body);
            return Task.FromResult(response);
        }
    }
}
'@
        if ($PSVersionTable.PSEdition -eq 'Desktop') {
            Add-Type `
                -TypeDefinition $typeDefinition `
                -ReferencedAssemblies 'System.Net.Http.dll'
        } else {
            Add-Type -TypeDefinition $typeDefinition
        }
    }
}

Describe 'Invoke-WUHttpFileDownload' {
    BeforeEach {
        $script:ResponseBody = [System.Text.Encoding]::UTF8.GetBytes('download body')
        $script:Handler = [PSWinUtil.Tests.StaticHttpMessageHandler]::new(
            $script:ResponseBody,
            [System.Net.HttpStatusCode]::OK
        )
        $script:Client = [System.Net.Http.HttpClient]::new($script:Handler)
        & $script:Module {
            param($Client)

            $script:WUHttpClient = $Client
        } $script:Client
    }

    AfterEach {
        & $script:Module {
            $script:WUHttpClient = $null
        }
        $script:Client.Dispose()
    }

    It 'downloads a response body without a browser' {
        $path = Join-Path -Path $TestDrive -ChildPath 'package.zip'

        $result = & $script:Module {
            param($Path)

            Invoke-WUHttpFileDownload `
                -Uri 'https://example.com/package.zip' `
                -Path $Path `
                -TimeoutSeconds 30
        } $path

        $result | Should -Be ([System.IO.Path]::GetFullPath($path))
        [System.IO.File]::ReadAllBytes($path) | Should -Be $script:ResponseBody
        $script:Handler.RequestUri.AbsoluteUri | Should -Be 'https://example.com/package.zip'
    }

    It 'removes an incomplete file after an HTTP error' {
        $script:Client.Dispose()
        $script:Handler = [PSWinUtil.Tests.StaticHttpMessageHandler]::new(
            [byte[]]@(),
            [System.Net.HttpStatusCode]::BadGateway
        )
        $script:Client = [System.Net.Http.HttpClient]::new($script:Handler)
        & $script:Module {
            param($Client)

            $script:WUHttpClient = $Client
        } $script:Client
        $path = Join-Path -Path $TestDrive -ChildPath 'failed.zip'

        {
            & $script:Module {
                param($Path)

                Invoke-WUHttpFileDownload `
                    -Uri 'https://example.com/failed.zip' `
                    -Path $Path `
                    -TimeoutSeconds 30
            } $path
        } | Should -Throw

        Test-Path -LiteralPath $path | Should -BeFalse
    }

    It 'does not replace an existing target' {
        $path = Join-Path -Path $TestDrive -ChildPath 'existing.zip'
        [System.IO.File]::WriteAllText($path, 'existing')

        {
            & $script:Module {
                param($Path)

                Invoke-WUHttpFileDownload `
                    -Uri 'https://example.com/package.zip' `
                    -Path $Path `
                    -TimeoutSeconds 30
            } $path
        } | Should -Throw '*already exists*'

        [System.IO.File]::ReadAllText($path) | Should -Be 'existing'
        $script:Handler.RequestUri | Should -BeNullOrEmpty
    }
}
