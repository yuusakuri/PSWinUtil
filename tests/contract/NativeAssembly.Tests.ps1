BeforeAll {
    $script:RepositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $script:OutputModuleDirectory = Join-Path -Path $script:RepositoryRoot -ChildPath 'output/PSWinUtil'
    $script:ManifestPath = Join-Path -Path $script:OutputModuleDirectory -ChildPath 'PSWinUtil.psd1'
    $nativeAssemblyPathParameters = @{
        Path = $script:OutputModuleDirectory
        ChildPath = 'lib/PSWinUtil.Native.dll'
    }
    $script:NativeAssemblyPath = Join-Path @nativeAssemblyPathParameters
}

Describe 'C# source layout' {
    It 'keeps type definitions out of the PowerShell sources' {
        $searchDirectories = @(
            (Join-Path -Path $script:RepositoryRoot -ChildPath 'src/PSWinUtil')
            (Join-Path -Path $script:RepositoryRoot -ChildPath 'tests')
        )
        $inlineTypePattern = 'Add-Type[^\r\n]*-Type' + 'Definition'
        $inlineTypeFilePaths = @(
            foreach ($searchDirectory in $searchDirectories) {
                Get-ChildItem -LiteralPath $searchDirectory -Filter '*.ps1' -File -Recurse |
                    Where-Object {
                        [System.IO.File]::ReadAllText($_.FullName) -match $inlineTypePattern
                    } |
                    Select-Object -ExpandProperty FullName
            }
        )

        $inlineTypeFilePaths | Should -BeNullOrEmpty
    }

    It 'builds every C# type from a project file' {
        $nativeProjectPathParameters = @{
            Path = $script:RepositoryRoot
            ChildPath = 'src/PSWinUtil.Native/PSWinUtil.Native.csproj'
        }
        $nativeProjectPath = Join-Path @nativeProjectPathParameters
        $fakeHttpServerProjectPathParameters = @{
            Path = $script:RepositoryRoot
            ChildPath = 'tests/PSWinUtil.FakeHttpServer/PSWinUtil.FakeHttpServer.csproj'
        }
        $fakeHttpServerProjectPath = Join-Path @fakeHttpServerProjectPathParameters

        foreach ($projectPath in @($nativeProjectPath, $fakeHttpServerProjectPath)) {
            Test-Path -LiteralPath $projectPath -PathType Leaf |
                Should -BeTrue -Because "$projectPath must exist"
        }
    }
}

Describe 'Native assembly distribution' {
    It 'ships the native assembly inside the module' {
        Test-Path -LiteralPath $script:NativeAssemblyPath -PathType Leaf | Should -BeTrue
    }

    It 'loads the native assembly through the built manifest' {
        $manifest = Import-PowerShellDataFile -Path $script:ManifestPath

        @($manifest.RequiredAssemblies) | Should -Contain 'lib/PSWinUtil.Native.dll'
    }

    It 'exposes the interop types after the module is imported' {
        Import-Module -Name $script:ManifestPath -Force -ErrorAction Stop

        $typeNames = @(
            'PSWinUtil.NativeMethods.LsaPolicy'
            'PSWinUtil.NativeMethods.LsaUnicodeString'
            'PSWinUtil.NativeMethods.LsaObjectAttributes'
        )
        foreach ($typeName in $typeNames) {
            $typeName -as [type] | Should -Not -BeNullOrEmpty -Because "$typeName must be loaded"
        }
    }

    It 'loads the native assembly from the module directory' {
        Import-Module -Name $script:ManifestPath -Force -ErrorAction Stop

        $loadedAssembly = [PSWinUtil.NativeMethods.LsaPolicy].Assembly
        $expectedLocation = [System.IO.Path]::GetFullPath($script:NativeAssemblyPath)

        $loadedAssembly.GetName().Name | Should -Be 'PSWinUtil.Native'
        $loadedAssembly.Location | Should -Be $expectedLocation
    }
}

Describe 'HTTP fake server assembly distribution' {
    It 'builds the HTTP fake server assembly for both PowerShell editions' {
        foreach ($targetFramework in @('net472', 'netstandard2.0')) {
            $fakeHttpServerAssemblyPathParameters = @{
                Path = $script:RepositoryRoot
                ChildPath = "output/FakeHttpServer/$targetFramework/PSWinUtil.FakeHttpServer.dll"
            }
            $fakeHttpServerAssemblyPath = Join-Path @fakeHttpServerAssemblyPathParameters

            Test-Path -LiteralPath $fakeHttpServerAssemblyPath -PathType Leaf |
                Should -BeTrue -Because "$fakeHttpServerAssemblyPath must exist"
        }
    }
}
