function Add-WUPathEnvironmentVariable {
    <#
    .SYNOPSIS
    Adds paths to the PATH environment variable.

    .DESCRIPTION
    Adds paths to the Process, User, or Machine PATH. Empty PATH items are removed when the value is read. Existing item text and order are preserved. Duplicate checks ignore leading and trailing spaces, a trailing backslash, and character case.

    .PARAMETER Path
    Specifies one or more paths to add. The paths do not need to exist.

    .PARAMETER Scope
    Specifies Process, User, or Machine. The default value is Process.

    .PARAMETER Prepend
    Adds the new paths before the existing PATH items. By default, new paths are added after existing items.

    .EXAMPLE
    Add-WUPathEnvironmentVariable -Path 'C:\Tools', 'C:\Apps\bin' -Scope User

    Adds two paths to the end of the current user PATH.

    .EXAMPLE
    Add-WUPathEnvironmentVariable -Path 'C:\Required\bin' -Scope Process -Prepend

    Adds a path to the start of the current process PATH.

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
        [string]$Scope = 'Process',

        [Parameter()]
        [switch]$Prepend
    )

    begin {
        $pathsToAdd = @()
        $shouldProcessParameters = @{}
        foreach ($parameterName in @('WhatIf', 'Confirm')) {
            if ($PSBoundParameters.ContainsKey($parameterName)) {
                $shouldProcessParameters[$parameterName] = $PSBoundParameters[$parameterName]
            }
        }
    }

    process {
        $pathsToAdd += $Path
    }

    end {
        $target = [System.EnvironmentVariableTarget]$Scope
        $currentValue = [System.Environment]::GetEnvironmentVariable('Path', $target)
        $existingPaths = @(Split-WUPathEnvironmentVariable -Value $currentValue)
        $newPaths = @()

        foreach ($pathToAdd in $pathsToAdd) {
            $trimmedPath = $pathToAdd.Trim()
            $isDuplicate = $false
            foreach ($existingPath in @($existingPaths + $newPaths)) {
                if (Compare-WUPath -ReferencePath $existingPath -DifferencePath $trimmedPath) {
                    $isDuplicate = $true
                    break
                }
            }

            if (-not $isDuplicate) {
                $newPaths += $trimmedPath
            }
        }

        if ($newPaths.Count -eq 0) {
            return
        }

        $updatedPaths = @($existingPaths + $newPaths)
        if ($Prepend) {
            $updatedPaths = @($newPaths + $existingPaths)
        }
        $updatedValue = Join-WUPathEnvironmentVariable -Path $updatedPaths

        Set-WUEnvironmentVariable `
            -Name 'Path' `
            -Value $updatedValue `
            -Scope $Scope `
            @shouldProcessParameters
    }
}
