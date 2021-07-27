function Start-WUDevcontainer {
    <#
        .SYNOPSIS
        Launch .devcontainer project with Visual Studio Code Remote - Containers.

        .DESCRIPTION
        Specify the project folder where .devcontainer is located and start it with Visual Studio Code Remote - Containers.

        .EXAMPLE
        PS C:\>Start-WUDevcontainer -HostPath "C:\ProjectFolder"

        Open `C:\ProjectFolder` with Visual Studio Code Remote - Containers based `C:\ProjectFolder\.devcontainer\devcontainer.json`.

        .EXAMPLE
        PS C:\>Start-WUDevcontainer -HostPath "C:\ProjectFolder" -WorkspacePath "/var/www"

        This example is the above example with the WorkspacePath specified. Opens the specified location (/var/www) in the container as a Workspace folder.
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param (
        # Specify one path of the project folder where the .devcontainer folder is located.
        [Parameter(Mandatory,
            Position = 0,
            ValueFromPipelineByPropertyName)]
        [Alias('ProjectPath')]
        [ValidateNotNullOrEmpty()]
        [string]
        $HostPath,

        # Specify the default path that VS Code should open when connecting to the container (which is often the path to a volume mount where the source code can be found in the container).
        #
        # If the value of this parameter is empty, the value of "WorkspacePath" in the devcontainer.json is set. If the value of this parameter and the value of "WorkspacePath" in the devcontainer.json are empty, "/" is set.
        [string]
        $WorkspacePath
    )

    begin {
        Set-StrictMode -Version 'Latest'

        if (!(Get-Command 'code')) {
            return
        }
    }

    process {
        if (!(Assert-WUPathProperty -LiteralPath $HostPath -PSProvider FileSystem -PathType Container)) {
            return
        }

        $HostPath = $psCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($HostPath)

        $devcontainerJsonPath = Join-Path $HostPath ".devcontainer/devcontainer.json"
        if (!(Test-Path -LiteralPath $devcontainerJsonPath -PathType Leaf)) {
            Write-Error "Cannot find file path '$devcontainerJsonPath' because it does not exist."
            return
        }

        if (!$WorkspacePath) {
            $WorkspacePath = Get-Content -LiteralPath $devcontainerJsonPath |
            ConvertFrom-Json |
            Where-Object { $_ | Get-Member -MemberType Properties | Where-Object { $_.Name -eq 'workspaceFolder' } } |
            Select-Object -ExpandProperty workspaceFolder -ErrorAction Ignore

            if (!$WorkspacePath) {
                $WorkspacePath = '/'
            }
        }

        # encode host path
        # https://github.com/microsoft/vscode-remote-release/issues/2133
        $encodedHostPath = ''
        $HostPath.ToCharArray() | ForEach-Object { $encodedHostPath = '{0}{1:x}' -f $encodedHostPath, [int]$_ }

        $cmd = 'code --folder-uri "vscode-remote://dev-container+{0}{1}"' -f `
            $encodedHostPath, `
            $WorkspacePath

        if ($PSCmdlet.ShouldProcess($cmd, "Execute")) {
            $result = ''
            $result = (Invoke-Expression $cmd | ForEach-Object ToString) -join [System.Environment]::NewLine
            Write-Debug ('Command: {0}' -f $cmd)
            Write-Verbose $result
        }
    }
}
