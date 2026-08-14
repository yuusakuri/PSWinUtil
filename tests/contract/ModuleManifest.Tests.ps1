BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $script:ManifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
}

Describe 'Built module manifest' {
    It 'is valid' {
        { Test-ModuleManifest -Path $script:ManifestPath -ErrorAction Stop } | Should -Not -Throw
    }

    It 'targets Windows PowerShell 5.1 Desktop' {
        $manifest = Import-PowerShellDataFile -Path $script:ManifestPath

        $manifest.PowerShellVersion | Should -Be '5.1'
        $manifest.CompatiblePSEditions | Should -Contain 'Desktop'
    }

    It 'has no runtime module dependency' {
        $manifest = Import-PowerShellDataFile -Path $script:ManifestPath

        @($manifest.RequiredModules).Count | Should -Be 0
    }
}

Describe 'Public command help' {
    BeforeAll {
        Import-Module -Name $script:ManifestPath -Force -ErrorAction Stop
        $script:PublicFunctionNames = @(
            (Get-Module -Name 'PSWinUtil' -ErrorAction Stop).ExportedFunctions.Keys
        )
    }

    It 'is complete for every exported function' {
        $commonParameterNames = @(
            'Verbose'
            'Debug'
            'ErrorAction'
            'WarningAction'
            'InformationAction'
            'ErrorVariable'
            'WarningVariable'
            'InformationVariable'
            'OutVariable'
            'OutBuffer'
            'PipelineVariable'
            'WhatIf'
            'Confirm'
        )
        foreach ($functionName in $script:PublicFunctionNames) {
            $help = Get-Help -Name $functionName -Full

            $help.Synopsis | Should -Not -BeNullOrEmpty
            @($help.Description).Count | Should -BeGreaterThan 0
            @($help.Examples.Example).Count | Should -BeGreaterThan 0

            $command = Get-Command -Name $functionName -Module 'PSWinUtil'
            foreach ($parameterName in $command.Parameters.Keys) {
                if ($parameterName -in $commonParameterNames) {
                    continue
                }

                $parameterHelp = @(
                    $help.Parameters.Parameter |
                        Where-Object { $_.Name -eq $parameterName }
                )
                $parameterHelp.Count | Should -Be 1
                $parameterHelp[0].Description | Should -Not -BeNullOrEmpty
            }
        }
    }
}
