function Add-WUPathEnvironmentVariable {
    <#
    .SYNOPSIS
    Adds paths to the PATH environment variable.

    .DESCRIPTION
    Adds paths to one or more Process, User, or Machine PATH values. Empty PATH items are removed when the value is read. Existing item text and order are preserved. Duplicate checks trim whitespace, expand environment variables for the selected scope, normalize fully qualified paths, ignore a trailing backslash, and ignore character case.

    .PARAMETER Path
    Specifies one or more paths to add. The paths do not need to exist.

    .PARAMETER Scope
    Specifies one or more of Process, User, and Machine. The default value is Process.

    .PARAMETER Prepend
    Adds the new paths before the existing PATH items. By default, new paths are added after existing items.

    .EXAMPLE
    Add-WUPathEnvironmentVariable -Path 'C:\Tools', 'C:\Apps\bin' -Scope User

    Adds two paths to the end of the current user PATH.

    .EXAMPLE
    Add-WUPathEnvironmentVariable -Path 'C:\Required\bin' -Scope Process -Prepend

    Adds a path to the start of the current process PATH.

    .EXAMPLE
    Add-WUPathEnvironmentVariable -Path 'C:\Tools' -Scope Process, User

    Adds C:\Tools to the current process and current user PATH values.

    .INPUTS
    System.String

    .OUTPUTS
    None
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSShouldProcess',
        '',
        Justification = 'Set-WUEnvironmentVariable evaluates ShouldProcess for the delegated change.'
    )]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ -not [string]::IsNullOrWhiteSpace($_) })]
        [string[]]$Path,

        [Parameter()]
        [ValidateSet('Process', 'User', 'Machine')]
        [string[]]$Scope = 'Process',

        [Parameter()]
        [switch]$Prepend
    )

    begin {
        $paths = @()
        $shouldProcessParameters = Select-WUBoundParameter -BoundParameters $PSBoundParameters -Name 'WhatIf', 'Confirm'
    }

    process {
        $paths += $Path
    }

    end {
        foreach ($targetScope in $Scope) {
            $currentValue = Get-WUEnvironmentVariable -Name 'Path' -Scope $targetScope -NoExpand
            $existingPaths = @(Split-WUPathEnvironmentVariable -Value $currentValue)
            $newPaths = @()

            foreach ($inputPath in $paths) {
                $trimmedPath = $inputPath.Trim()
                $isDuplicate = $false
                foreach ($existingPath in @($existingPaths + $newPaths)) {
                    if (Compare-WUPath -ReferencePath $existingPath -DifferencePath $trimmedPath -Scope $targetScope) {
                        $isDuplicate = $true
                        break
                    }
                }

                if (-not $isDuplicate) {
                    $newPaths += $trimmedPath
                }
            }

            if ($newPaths.Count -eq 0) {
                continue
            }

            $updatedPaths = @($existingPaths + $newPaths)
            if ($Prepend) {
                $updatedPaths = @($newPaths + $existingPaths)
            }
            $updatedValue = Join-WUPathEnvironmentVariable -Path $updatedPaths

            $setParameters = @{
                Name = 'Path'
                Value = $updatedValue
                Scope = $targetScope
            }
            Set-WUEnvironmentVariable @setParameters @shouldProcessParameters
        }
    }
}
