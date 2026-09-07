BeforeAll {
    $repositoryRoot = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $script:ManifestPath = Join-Path -Path $repositoryRoot -ChildPath 'output/PSWinUtil/PSWinUtil.psd1'
    $script:Manifest = Import-PowerShellDataFile -Path $script:ManifestPath
    Import-Module -Name $script:ManifestPath -Force -ErrorAction Stop
    $script:Module = Get-Module -Name 'PSWinUtil' -ErrorAction Stop
}

Describe 'Built module manifest' {
    It 'is valid' {
        { Test-ModuleManifest -Path $script:ManifestPath -ErrorAction Stop } | Should -Not -Throw
    }

    It 'targets Windows PowerShell 5.1 Desktop' {
        $script:Manifest.PowerShellVersion | Should -Be '5.1'
        $script:Manifest.CompatiblePSEditions | Should -Contain 'Desktop'
    }

    It 'has no runtime module dependency' {
        @($script:Manifest.RequiredModules).Count | Should -Be 0
    }

    It 'exports content command overrides only in Windows PowerShell' {
        $exportedCommands = @($script:Module.ExportedFunctions.Keys)

        foreach ($commandName in @(
                'Get-Content'
                'Set-Content'
                'Add-Content'
                'Out-File'
                'Invoke-WebRequest'
            )) {
            if ($PSVersionTable.PSEdition -eq 'Desktop') {
                $exportedCommands | Should -Contain $commandName
            } else {
                $exportedCommands | Should -Not -Contain $commandName
                (Get-Command -Name $commandName).ModuleName | Should -Not -Be 'PSWinUtil'
            }
        }
    }

    It 'exports an override state command pair for every overridden command' {
        $exportedCommands = @($script:Module.ExportedFunctions.Keys)

        foreach ($commandName in @(
                'Get-Content'
                'Set-Content'
                'Add-Content'
                'Out-File'
                'Invoke-WebRequest'
            )) {
            $overrideNoun = $commandName -replace '-', ''
            foreach ($stateCommandName in @(
                    "Enable-WU${overrideNoun}Override"
                    "Disable-WU${overrideNoun}Override"
                )) {
                if ($PSVersionTable.PSEdition -eq 'Desktop') {
                    $exportedCommands | Should -Contain $stateCommandName
                } else {
                    $exportedCommands | Should -Not -Contain $stateCommandName
                }
            }
        }
    }

    It 'accepts multiple Scope values in every scoped public command' {
        $scopedCommands = @(
            $script:Module.ExportedFunctions.Values |
                Where-Object { $_.Parameters.ContainsKey('Scope') }
        )

        foreach ($command in $scopedCommands) {
            $command.Parameters.Scope.ParameterType |
                Should -Be ([string[]]) -Because "$($command.Name) must accept multiple scopes"
        }
    }

    It 'uses consistent wildcard and literal parameters for file selectors' {
        $fileSelectorCommands = @(
            $script:Module.ExportedFunctions.Values |
                Where-Object {
                    $_.Parameters.ContainsKey('Path') -and
                    $_.Parameters.Path.Attributes.TypeId -contains
                    [System.Management.Automation.SupportsWildcardsAttribute]
                }
        )

        foreach ($command in $fileSelectorCommands) {
            $command.Parameters.Keys | Should -Contain 'Path'
            $command.Parameters.Keys | Should -Contain 'LiteralPath'
            $command.Parameters.Path.ParameterType |
                Should -Be $command.Parameters.LiteralPath.ParameterType
            $wildcardAttributes = @(
                $command.Parameters.Path.Attributes |
                    Where-Object {
                        $_ -is [System.Management.Automation.SupportsWildcardsAttribute]
                    }
            )
            $wildcardAttributes | Should -HaveCount 1
            $command.Parameters.LiteralPath.Aliases | Should -Contain 'PSPath'
            $command.Parameters.LiteralPath.Aliases | Should -Contain 'LP'
        }
    }
}

Describe 'Public command help' {
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
            'ProgressAction'
            'WhatIf'
            'Confirm'
        )
        foreach ($functionName in $script:Module.ExportedFunctions.Keys) {
            $help = Get-Help -Name "PSWinUtil\$functionName" -Full

            $help.Synopsis | Should -Not -BeNullOrEmpty
            @($help.Description).Count | Should -BeGreaterThan 0
            $examplesProperty = @(
                $help.PSObject.Properties |
                    Where-Object { $_.Name -ieq 'Examples' }
            )
            if ($examplesProperty.Count -ne 1) {
                throw "Public command help does not contain Examples: $functionName"
            }
            $exampleProperty = @(
                $examplesProperty[0].Value.PSObject.Properties |
                    Where-Object { $_.Name -ieq 'Example' }
            )
            $exampleCount = 0
            if ($exampleProperty.Count -eq 1) {
                $exampleCount = @($exampleProperty[0].Value).Count
            }
            $exampleCount | Should -BeGreaterThan 0

            $command = Get-Command -Name $functionName -Module 'PSWinUtil'
            foreach ($parameterName in $command.Parameters.Keys) {
                if ($command.Parameters[$parameterName].IsDynamic) {
                    continue
                }
                if ($parameterName -in $commonParameterNames) {
                    continue
                }

                $parameterHelp = @(
                    $help.Parameters.Parameter |
                        Where-Object { $_.Name -eq $parameterName }
                )
                $parameterHelp.Count | Should -Be 1 -Because "$functionName must document $parameterName"
                $parameterHelp[0].Description | Should -Not -BeNullOrEmpty
            }
        }
    }
}
