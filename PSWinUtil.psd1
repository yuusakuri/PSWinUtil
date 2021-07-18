#
# モジュール 'PSWinUtil' のモジュール マニフェスト
#
# 生成者: yuusakuri
#
# 生成日: 2020/03/29
#

@{

    # このマニフェストに関連付けられているスクリプト モジュール ファイルまたはバイナリ モジュール ファイル。
    RootModule        = 'PSWinUtil.psm1'

    # このモジュールのバージョン番号です。
    ModuleVersion     = '1.6.3'

    # サポートされている PSEditions
    # CompatiblePSEditions = @()

    # このモジュールを一意に識別するために使用される ID
    GUID              = '85b4b33d-dfb6-4614-acd0-09673a5ce649'

    # このモジュールの作成者
    Author            = 'yuusakuri'

    # このモジュールの会社またはベンダー
    CompanyName       = ''

    # このモジュールの著作権情報
    Copyright         = 'yuusakuri'

    # このモジュールの機能の説明
    Description       = @'
PSWinUtil is a PowerShell module for Windows users. Dependencies are automatically installed by Scoop and Chocolatey and NuGet. It contains the following functions.

- Set Windows by rewriting the registry
- Add environment variables from PowerShell script file or object.
- Add the specified paths to the path environment variable.
- Determines if the path properties match. This function is useful for testing if the specified path is a file system and if the extensions match.
- Search for file or folder paths in rapidly by using Everything. Useful for finding executable files.
- Get whether the computer is Desktop, Tablet, or Server from ChassisTypes.
- Get information about installed NuGet packages in the NuGet packages installation directory.
- Get link targets of shortcut (.lnk) files.
- Get properties about media files such as video files, audio files, and image files.
- Load assemblies from NuGet packages, including its dependencies. It is possible to automatically install the required packages.
- Change the display settings.
- Create SSH key using ssh-keygen.
- Test if a version is in the allowed range.
'@

    # このモジュールに必要な Windows PowerShell エンジンの最小バージョン
    PowerShellVersion = '5.1'

    # このモジュールに必要な Windows PowerShell ホストの名前
    # PowerShellHostName = ''

    # このモジュールに必要な Windows PowerShell ホストの最小バージョン
    # PowerShellHostVersion = ''

    # このモジュールに必要な Microsoft .NET Framework の最小バージョン。 この前提条件は、PowerShell Desktop エディションについてのみ有効です。
    # DotNetFrameworkVersion = ''

    # このモジュールに必要な共通言語ランタイム (CLR) の最小バージョン。 この前提条件は、PowerShell Desktop エディションについてのみ有効です。
    # CLRVersion = ''

    # このモジュールに必要なプロセッサ アーキテクチャ (なし、X86、Amd64)
    # ProcessorArchitecture = ''

    # このモジュールをインポートする前にグローバル環境にインポートされている必要があるモジュール
    # RequiredModules = @()

    # このモジュールをインポートする前に読み込まれている必要があるアセンブリ
    # RequiredAssemblies = @()

    # このモジュールをインポートする前に呼び出し元の環境で実行されるスクリプト ファイル (.ps1)。
    # ScriptsToProcess = @()

    # このモジュールをインポートするときに読み込まれる型ファイル (.ps1xml)
    # TypesToProcess = @()

    # このモジュールをインポートするときに読み込まれる書式ファイル (.ps1xml)
    # FormatsToProcess = @()

    # RootModule/ModuleToProcess に指定されているモジュールの入れ子になったモジュールとしてインポートするモジュール
    # NestedModules = @()

    # このモジュールからエクスポートする関数です。最適なパフォーマンスを得るには、ワイルドカードを使用せず、エクスポートする関数がない場合は、エントリを削除しないで空の配列を使用してください。
    FunctionsToExport = @(
        'Add-WUEnvironmentVariableFromFile',
        'Add-WUPathEnvironmentVariable',
        'Assert-WUPathProperty',
        'Assert-WUPSScript',
        'Convert-WUString',
        'ConvertTo-WUFullPath',
        'ConvertTo-WUNuspec',
        'Edit-WUSshKey',
        'Find-WUPath',
        'Get-WUChassisType',
        'Get-WUInstalledNuGetPackage',
        'Get-WULnkTarget',
        'Get-WUMediaProperty',
        'Get-WUMonitor',
        'Get-WURandomString',
        'Get-WUUriWithoutQuery',
        'Import-WUNuGetPackageAssembly',
        'Install-WUApp',
        'Invoke-WUDownload',
        'Join-WUUri',
        'New-WUSshKey',
        'Remove-WUPathEnvironmentVariable',
        'Set-WUMonitor',
        'Start-WUDevcontainer',
        'Start-WUScriptAsAdmin',
        'Test-WUPathProperty',
        'Test-WUPSScript',
        'Test-WUVersion',
        'Disable-WUAdvertisingId',
        'Disable-WUAppLaunchTracking',
        'Disable-WUAppSuggestions',
        'Disable-WUCortana',
        'Disable-WUDarkMode',
        'Disable-WUEdgeFirstRunExperience',
        'Disable-WUFileHistory',
        'Disable-WUGameDvr',
        'Disable-WULockScreen',
        'Disable-WULockWorkstation',
        'Disable-WULongPaths',
        'Disable-WURequireSignInOnWakeup',
        'Disable-WUSaveZoneInformation',
        'Disable-WUSmartScreen',
        'Disable-WUSystemSounds',
        'Disable-WUUac',
        'Disable-WUWebSearchInStartMenu',
        'Disable-WUWebsiteAccessToLanguageList',
        'Disable-WUWindowsHello',
        'Disable-WUWindowsMediaPlayerFirstUseDialogBoxes',
        'Disable-WUWindowsSecurityAllNotifications',
        'Disable-WUWindowsSecurityNonCriticalNotifications',
        'Disable-WUWindowsUpdateAutoRestart',
        'Disable-WUWindowsUpdateNotifications',
        'Disable-WUWindowsUpdateTrayIcon',
        'Enable-WUAdvertisingId',
        'Enable-WUAppLaunchTracking',
        'Enable-WUAppSuggestions',
        'Enable-WUCortana',
        'Enable-WUDarkMode',
        'Enable-WUEdgeFirstRunExperience',
        'Enable-WUFileHistory',
        'Enable-WUGameDvr',
        'Enable-WULockScreen',
        'Enable-WULockWorkstation',
        'Enable-WULongPaths',
        'Enable-WURequireSignInOnWakeup',
        'Enable-WUSaveZoneInformation',
        'Enable-WUSmartScreen',
        'Enable-WUSystemSounds',
        'Enable-WUUac',
        'Enable-WUWebSearchInStartMenu',
        'Enable-WUWebsiteAccessToLanguageList',
        'Enable-WUWindowsHello',
        'Enable-WUWindowsMediaPlayerFirstUseDialogBoxes',
        'Enable-WUWindowsSecurityAllNotifications',
        'Enable-WUWindowsSecurityNonCriticalNotifications',
        'Enable-WUWindowsUpdateAutoRestart',
        'Enable-WUWindowsUpdateNotifications',
        'Enable-WUWindowsUpdateTrayIcon',
        'Register-WUStartup',
        'Set-WUCapsLockToControl',
        'Set-WUDesktopIconSize',
        'Set-WUPS1Action',
        'Set-WUScalingBehavior',
        'Set-WUSearchBoxTaskbarMode',
        'Set-WUWindowsAutoLogin'
    )

    # このモジュールからエクスポートするコマンドレットです。最適なパフォーマンスを得るには、ワイルドカードを使用せず、エクスポートするコマンドレットがない場合は、エントリを削除しないで空の配列を使用してください。
    CmdletsToExport   = @()

    # このモジュールからエクスポートする変数
    VariablesToExport = ''

    # このモジュールからエクスポートするエイリアスです。最適なパフォーマンスを得るには、ワイルドカードを使用せず、エクスポートするエイリアスがない場合は、エントリを削除しないで空の配列を使用してください。
    AliasesToExport   = '*'

    # このモジュールからエクスポートする DSC リソース
    # DscResourcesToExport = @()

    # このモジュールに同梱されているすべてのモジュールのリスト
    # ModuleList = @()

    # このモジュールに同梱されているすべてのファイルのリスト
    # FileList = @()

    # RootModule/ModuleToProcess に指定されているモジュールに渡すプライベート データ。これには、PowerShell で使用される追加のモジュール メタデータを含む PSData ハッシュテーブルが含まれる場合もあります。
    PrivateData       = @{

        PSData = @{

            # このモジュールに適用されているタグ。オンライン ギャラリーでモジュールを検出する際に役立ちます。
            Tags       = @(
                'Windows'
            )

            # このモジュールのライセンスの URL。
            LicenseUri = 'https://github.com/yuusakuri/PSWinUtil/blob/master/LICENSE'

            # このプロジェクトのメイン Web サイトの URL。
            ProjectUri = 'https://github.com/yuusakuri/PSWinUtil'

            # このモジュールを表すアイコンの URL。
            # IconUri = ''

            # このモジュールの ReleaseNotes
            # ReleaseNotes = ''

        } # PSData ハッシュテーブル終了

    } # PrivateData ハッシュテーブル終了

    # このモジュールの HelpInfo URI
    # HelpInfoURI = ''

    # このモジュールからエクスポートされたコマンドの既定のプレフィックス。既定のプレフィックスをオーバーライドする場合は、Import-Module -Prefix を使用します。
    # DefaultCommandPrefix = 'u'

}
