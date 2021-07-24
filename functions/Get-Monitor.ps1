function Get-WUMonitor {
    <#
        .SYNOPSIS
        Get Monitor details.

        .DESCRIPTION
        Get the following monitor information:
            deviceName
            monitorHandle
            displayModes
            resolution
            verticalResolution
            horizontalResolution
            leftTop
            rightBottom
            active
            disconnected
            primary
            colors
            frequency
            orientation
            maximumResolution
            maximumVerticalResolution
            maximumHorizontalResolution
            adapter
            deviceId
            deviceKey
            monitorId
            monitorKey
            monitorString
            monitorName
            monitorSerialNumber

        .OUTPUTS
        System.Management.Automation.PSCustomObject

        .EXAMPLE
        PS C:\>Get-WUMonitor

        Get details of all monitors.

        .LINK
        Set-WUMonitor
    #>

    [CmdletBinding()]
    param (
    )

    <# Other ways to get monitor information
        Get-CimInstance -ClassName Win32_VideoController
        Get-CimInstance -ClassName Win32_PnPEntity | Where-Object Service -eq Monitor
        Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorBasicDisplayParams
        MonitorInfoView.exe /sxml $xmlPath
    #>

    function Get-WUMonitorFromMultiMonitorTool {
        <#
            .SYNOPSIS
            Get Monitor details from MonitorTool.

            .DESCRIPTION
            Get the following monitor information:
                resolution
                leftTop
                rightBottom
                active
                disconnected
                primary
                colors
                frequency
                orientation
                maximumResolution
                name
                adapter
                deviceId
                deviceKey
                monitorId
                monitorKey
                monitorString
                monitorName
                monitorSerialNumber

            .OUTPUTS
            System.Management.Automation.PSCustomObject

            .EXAMPLE
            PS C:\>Get-WUMonitorFromMultiMonitorTool
        #>

        [CmdletBinding()]
        param (
        )

        try {
            $tempFilePath = ''
            $tempFilePath = New-TemporaryFile |
            Rename-Item -NewName { $_ -replace 'tmp$', 'xml' } -PassThru |
            Select-Object -ExpandProperty FullName
            if (!$tempFilePath) {
                return
            }

            Start-Process 'MultiMonitorTool.exe' -ArgumentList ('/sxml "{0}"' -f ($tempFilePath | Convert-WUString -Type EscapeForPowerShellDoubleQuotation)) -Wait -NoNewWindow

            try {
                $monitorXml = Select-Xml -LiteralPath $tempFilePath -XPath 'monitors_list/item' -ErrorAction Stop | Select-Object -ExpandProperty Node
            }
            catch {
                Write-Verbose $_
                Write-Error "Failed to get monitor information from 'MultiMonitorTool'." -ErrorAction $ErrorActionPreference
                return
            }

            foreach ($aMonitorXml in $monitorXml) {
                $monitor = New-Object -TypeName psobject

                $aMonitorXml.ChildNodes |
                Where-Object { !($_.Name -eq '#whitespace') } |
                ForEach-Object {
                    $name = Convert-WUString -String $_.Name -Type 'LowerCamelCase'

                    $monitor | Add-Member -MemberType NoteProperty -Name $name -Value $_.'#text'
                }

                $monitor
            }
        }
        finally {
            $tempFilePath |
            Where-Object { $_ } |
            Where-Object { Test-Path -LiteralPath $_ } |
            Remove-Item -LiteralPath { $_ } -Force
        }
    }

    function Get-WUMonitorFromSharpDX {
        <#
            .SYNOPSIS
            Get Monitor details from SharpDX.

            .DESCRIPTION
            Get the following monitor information:
                deviceName
                monitorHandle
                displayModes

            .OUTPUTS
            System.Management.Automation.PSCustomObject

            .EXAMPLE
            PS C:\>Get-WUMonitorFromSharpDX
        #>

        [CmdletBinding()]
        param (
        )

        # [How to get supported display modes using SharpDX](https://discussiongenerator.com/2012/11/04/how-to-get-supported-display-modes-using-sharpdx/)

        Import-WUNuGetPackageAssembly -Install -PackageID SharpDX.DXGI

        $dxgiFactory = New-Object 'SharpDX.DXGI.Factory1'

        foreach ($dxgiAdapter in $dxgiFactory.Adapters) {
            foreach ($aOutput in $dxgiAdapter.Outputs) {
                [PSCustomObject]@{
                    deviceName    = $aOutput.Description.DeviceName
                    monitorHandle = $aOutput.Description.MonitorHandle
                    displayModes  = [System.Enum]::GetValues([SharpDX.DXGI.Format]) |
                    ForEach-Object {
                        $aFormat = $_

                        $displayModes = $aOutput.GetDisplayModeList(
                            [SharpDX.DXGI.Format]$aFormat,
                            [SharpDX.DXGI.DisplayModeEnumerationFlags]::Interlaced -band [SharpDX.DXGI.DisplayModeEnumerationFlags]::Scaling
                        )

                        foreach ($aDisplayMode in $displayModes) {
                            if ($aDisplayMode.Scaling -eq [SharpDX.DXGI.DisplayModeScaling]::Unspecified) {
                                [PSCustomObject]@{
                                    displayWidth   = $aDisplayMode.Width
                                    displayHeight  = $aDisplayMode.Height
                                    displayRefresh = $aDisplayMode.RefreshRate
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    $monitorsFromMultiMonitorTool = Get-WUMonitorFromMultiMonitorTool
    if (!$monitorsFromMultiMonitorTool) {
        return
    }
    $monitorsFromSharpDX = Get-WUMonitorFromSharpDX
    if (!$monitorsFromSharpDX) {
        return
    }

    foreach ($aMmonitorFromMultiMonitorTool in $monitorsFromMultiMonitorTool) {
        $monitor = New-Object -TypeName psobject
        $aMonitorFromSharpDX = $monitorsFromSharpDX | Where-Object { $_.deviceName -eq $aMmonitorFromMultiMonitorTool.name }

        foreach ($aMonitorFromSharpDXProperty in $aMonitorFromSharpDX.psobject.Properties) {
            $monitor | Add-Member -MemberType NoteProperty -Name $aMonitorFromSharpDXProperty.name -Value $aMonitorFromSharpDXProperty.Value
        }
        foreach ($aMmonitorFromMultiMonitorToolProperty in $aMmonitorFromMultiMonitorTool.psobject.Properties) {
            switch ($aMmonitorFromMultiMonitorToolProperty.name) {
                'name' {
                    break
                }
                'resolution' {
                    $monitor | Add-Member -MemberType NoteProperty -Name $aMmonitorFromMultiMonitorToolProperty.name -Value $aMmonitorFromMultiMonitorToolProperty.Value
                    $monitor | Add-Member -MemberType NoteProperty -Name 'verticalResolution' -Value ($aMmonitorFromMultiMonitorToolProperty.Value -replace ' X .+')
                    $monitor | Add-Member -MemberType NoteProperty -Name 'horizontalResolution' -Value ($aMmonitorFromMultiMonitorToolProperty.Value -replace '.+ X ')
                    break
                }
                'maximumResolution' {
                    $monitor | Add-Member -MemberType NoteProperty -Name $aMmonitorFromMultiMonitorToolProperty.name -Value $aMmonitorFromMultiMonitorToolProperty.Value
                    $monitor | Add-Member -MemberType NoteProperty -Name 'maximumVerticalResolution' -Value ($aMmonitorFromMultiMonitorToolProperty.Value -replace ' X .+')
                    $monitor | Add-Member -MemberType NoteProperty -Name 'maximumHorizontalResolution' -Value ($aMmonitorFromMultiMonitorToolProperty.Value -replace '.+ X ')
                    break
                }
                Default {
                    $monitor | Add-Member -MemberType NoteProperty -Name $aMmonitorFromMultiMonitorToolProperty.name -Value $aMmonitorFromMultiMonitorToolProperty.Value
                }
            }
        }

        $monitor
    }
}
