# Command reference

This page groups the commands exported by the current source build. Use PowerShell's comment-based help for the authoritative parameter sets, input and output types, side effects, and examples:

```powershell
Get-Help -Name '<CommandName>' -Full
```

Run `Get-Command -Module 'PSWinUtil'` against the built module to inspect the exact export list for a revision.

## Environment and PATH

| Command | Purpose |
| --- | --- |
| `Add-WUPathEnvironmentVariable` | Add paths to a `PATH` environment variable. |
| `Get-WUEnvironmentVariable` | Get environment variable values from Process, User, or Machine scope. |
| `Remove-WUEnvironmentVariable` | Remove an environment variable. |
| `Remove-WUPathEnvironmentVariable` | Remove paths from a `PATH` environment variable. |
| `Set-WUEnvironmentVariable` | Set one or more environment variables. |
| `Update-WUProcessEnvironment` | Refresh the current process environment from persistent scopes. |

## Registry and Windows settings

| Command | Purpose |
| --- | --- |
| `Get-WURegistryProperty` | Get a registry property. |
| `Get-WURegistrySetting` | Get a catalogued Windows registry setting state. |
| `Remove-WURegistryProperty` | Remove a registry property. |
| `Set-WUAdvertisingIdMode` | Set the advertising ID mode. |
| `Set-WUJapaneseImeHalfWidthInput` | Set Microsoft IME space, number, and alphabet input to half width. |
| `Set-WUJapaneseKeyboardLayout` | Set the physical layout used with the Japanese Microsoft IME. |
| `Set-WURegistryProperty` | Set a registry property. |
| `Set-WUTaskbarAlignment` | Set the Windows 11 taskbar alignment. |
| `Set-WUTaskbarSearchMode` | Set the Windows 11 taskbar search mode. |
| `Set-WUWindowsUpdateNotificationLevel` | Set the Windows Update notification level. |

The following paired commands enable or disable a specific Windows setting:

| Enable | Disable | Setting |
| --- | --- | --- |
| `Enable-WUAppLaunchTracking` | `Disable-WUAppLaunchTracking` | Application launch tracking. |
| `Enable-WUAppSuggestions` | `Disable-WUAppSuggestions` | Application suggestions. |
| `Enable-WUClassicContextMenu` | `Disable-WUClassicContextMenu` | Classic Windows 11 Explorer context menu. |
| `Enable-WUDarkMode` | `Disable-WUDarkMode` | Dark mode. |
| `Enable-WUDeviceSetupSuggestions` | `Disable-WUDeviceSetupSuggestions` | Device setup suggestions. |
| `Enable-WUEdgeFirstRunExperience` | `Disable-WUEdgeFirstRunExperience` | Microsoft Edge first-run experience. |
| `Enable-WUFileHistory` | `Disable-WUFileHistory` | File History. |
| `Enable-WULockScreen` | `Disable-WULockScreen` | Lock screen. |
| `Enable-WULockWorkstation` | `Disable-WULockWorkstation` | Workstation locking. |
| `Enable-WULongPaths` | `Disable-WULongPaths` | Long Windows paths. |
| `Enable-WURequireSignInOnWakeup` | `Disable-WURequireSignInOnWakeup` | Sign-in after wakeup. |
| `Enable-WUSaveZoneInformation` | `Disable-WUSaveZoneInformation` | Download zone information. |
| `Enable-WUSmartScreenInShell` | `Disable-WUSmartScreenInShell` | SmartScreen in the Windows shell. |
| `Enable-WUUac` | `Disable-WUUac` | User Account Control. |
| `Enable-WUWebsiteAccessToLanguageList` | `Disable-WUWebsiteAccessToLanguageList` | Website access to the language list. |
| `Enable-WUWidgets` | `Disable-WUWidgets` | Windows widgets. |
| `Enable-WUWindowsHelloForBusiness` | `Disable-WUWindowsHelloForBusiness` | Windows Hello for Business. |
| `Enable-WUWindowsMediaPlayerFirstUseDialogBoxes` | `Disable-WUWindowsMediaPlayerFirstUseDialogBoxes` | Windows Media Player first-use dialog boxes. |
| `Enable-WUWindowsSecurityAllNotifications` | `Disable-WUWindowsSecurityAllNotifications` | All Windows Security notifications. |
| `Enable-WUWindowsSecurityNonCriticalNotifications` | `Disable-WUWindowsSecurityNonCriticalNotifications` | Non-critical Windows Security notifications. |

Many Windows settings require elevation, a sign-out, a restart, or a supported Windows version. Read the command's full help before applying it and use `-WhatIf` to preview changes.

## Startup, sign-in, keyboard, and security

| Command | Purpose |
| --- | --- |
| `Disable-WUWindowsAutoLogon` | Disable Windows automatic logon. |
| `Edit-WUSshKey` | Change an SSH key passphrase or comment. |
| `Enable-WUWindowsAutoLogon` | Enable Windows automatic logon. |
| `Get-WUKeyboardRemapping` | Get Windows keyboard scan code mappings. |
| `Get-WUStartupEntry` | Get Windows startup entries. |
| `Get-WUWindowsAutoLogon` | Get the Windows automatic logon configuration. |
| `New-WUSshKey` | Create an SSH key with Windows OpenSSH. |
| `Register-WUStartupEntry` | Register a Windows startup entry. |
| `Remove-WUKeyboardRemapping` | Remove Windows keyboard scan code mappings. |
| `Set-WUJavaWindowsRootTrustStore` | Configure Java to use the Windows root certificate store. |
| `Set-WUKeyboardRemapping` | Set a Windows keyboard scan code mapping. |
| `Set-WUNodeExtraCaCertificate` | Configure an additional CA certificate for Node.js. |
| `Start-WUPSScriptAsAdmin` | Start a PowerShell script as an administrator. |
| `Unregister-WUStartupEntry` | Unregister a Windows startup entry. |

Enabling automatic logon stores a protected credential through Windows Local Security Authority APIs and changes sign-in registry values. Review the full help and security implications before use.

## Files, paths, scripts, and native commands

| Command | Purpose |
| --- | --- |
| `Add-Content` | Append content with UTF-8 without BOM and LF by default. |
| `Assert-WUPathProperty` | Require PowerShell paths to match selected properties. |
| `Assert-WUPSScript` | Require valid PowerShell script syntax. |
| `ConvertTo-WUFullPath` | Convert file-system paths to fully qualified paths. |
| `ConvertTo-WUNativeCommandArgument` | Convert values for native command arguments. |
| `ConvertTo-WUPSStringLiteral` | Convert strings to PowerShell string literals. |
| `Get-Content` | Get content with UTF-8 as the default file encoding. |
| `Get-WUFileTreeWithContent` | Get a file tree with text-file contents. |
| `Out-File` | Send formatted output to UTF-8 without BOM and LF by default. |
| `Resolve-WUPath` | Resolve PowerShell paths with optional single-result enforcement. |
| `Resolve-WUPathFromParameterSet` | Resolve paths selected by a parameter set. |
| `Select-WUBoundParameter` | Select named entries from a bound-parameter dictionary. |
| `Set-Content` | Replace content with UTF-8 without BOM and LF by default. |
| `Set-WUNativeCommandEncoding` | Set native command input and output encoding to UTF-8. |
| `Test-WUPathProperty` | Test PowerShell path properties. |
| `Test-WUPSScript` | Test PowerShell script syntax. |

`Add-Content`, `Get-Content`, `Set-Content`, and `Out-File` are Desktop-only proxies for built-in commands. Module-qualify a built-in command when its original behavior is required explicitly.

## Web, URI, packages, and SDKs

| Command | Purpose |
| --- | --- |
| `Convert-WUUri` | Remove selected components from a URI. |
| `Get-WUAndroidCommandLineToolsUrl` | Get the current Android command-line tools URL for Windows. |
| `Get-WUFlutterSdkUrl` | Get a Flutter SDK download URL for Windows. |
| `Install-WUAndroidCommandLineTools` | Install the current Android command-line tools package. |
| `Install-WUFlutterSdk` | Install the Flutter SDK on Windows. |
| `Install-WUGitHubCli` | Install GitHub CLI with Windows Package Manager. |
| `Install-WUWingetPackage` | Install an exact package with Windows Package Manager. |
| `Invoke-WebRequest` | Send an HTTP or HTTPS request without rendering progress. |
| `Invoke-WUDefaultBrowserDownload` | Download a file with the default browser. |
| `Join-WUUri` | Resolve a relative URI against a base URI. |
| `Start-WUAndroidEmulator` | Start an Android virtual device. |

`Invoke-WebRequest` is a Desktop-only proxy for the built-in command. Use `Microsoft.PowerShell.Utility\Invoke-WebRequest` to request the original command explicitly.

## General utilities

| Command | Purpose |
| --- | --- |
| `New-WURandomString` | Create a cryptographically random string. |
