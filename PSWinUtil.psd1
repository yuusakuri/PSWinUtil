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
  ModuleVersion     = '1.2.33'

  # サポートされている PSEditions
  # CompatiblePSEditions = @()

  # このモジュールを一意に識別するために使用される ID
  GUID              = '85b4b33d-dfb6-4614-acd0-09673a5ce649'

  # このモジュールの作成者
  Author            = 'yuusakuri'

  # このモジュールの会社またはベンダー
  CompanyName       = '不明'

  # このモジュールの著作権情報
  Copyright         = '(c) 2020 yuusakuri. All rights reserved.'

  # このモジュールの機能の説明
  Description       = 'PSWinUtil is a PowerShell module for Windows users. Dependencies are automatically installed by Scoop and Chocolatey.'

  # このモジュールに必要な Windows PowerShell エンジンの最小バージョン
  PowerShellVersion = '5.0'

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
    'Add-WUEnvPath',
    'ConvertTo-WUPascalCase',
    'Edit-WUSshKey',
    'Find-WUPath',
    'Get-WUChassisType',
    'Get-WULnkTarget',
    'Get-WUMediaProperty',
    'Get-WUMonitor',
    'Get-WURandomString',
    'Invoke-WUDownload',
    'New-WUSshKey',
    'Optimize-WUPowerShellStartup',
    'Remove-WUEnvPath',
    'Resolve-WUFullPath',
    'Set-WUMonitor',
    'Start-WUScriptAsAdmin',
    'Disable-WUAdvertisingId',
    'Disable-WUAppLaunchTracking',
    'Disable-WUAppSuggestionsInStart',
    'Disable-WUContentDelivery',
    'Disable-WUFileHistory',
    'Disable-WUGameDvr',
    'Disable-WULockScreen',
    'Disable-WULockWorkstation',
    'Disable-WUSaveZoneInformation',
    'Disable-WUSmartScreen',
    'Disable-WUSuggestedContentInSettingsApp',
    'Disable-WUSystemSounds',
    'Disable-WUUac',
    'Disable-WUWebsiteAccessToLanguageList',
    'Disable-WUWindowsHello',
    'Disable-WUWindowsSecurityAllNotifications',
    'Disable-WUWindowsSecurityNonCriticalNotifications',
    'Disable-WUWindowsUpdateAutoRestart',
    'Disable-WUWindowsUpdateNotifications',
    'Enable-WUAdvertisingId',
    'Enable-WUAppLaunchTracking',
    'Enable-WUAppSuggestionsInStart',
    'Enable-WUContentDelivery',
    'Enable-WUFileHistory',
    'Enable-WUGameDvr',
    'Enable-WULockScreen',
    'Enable-WULockWorkstation',
    'Enable-WUSaveZoneInformation',
    'Enable-WUSmartScreen',
    'Enable-WUSuggestedContentInSettingsApp',
    'Enable-WUSystemSounds',
    'Enable-WUUac',
    'Enable-WUWebsiteAccessToLanguageList',
    'Enable-WUWindowsHello',
    'Enable-WUWindowsSecurityAllNotifications',
    'Enable-WUWindowsSecurityNonCriticalNotifications',
    'Enable-WUWindowsUpdateAutoRestart',
    'Enable-WUWindowsUpdateNotifications',
    'Register-WUStartup',
    'Set-WUCapsLockToControl',
    'Set-WUDesktopIconSize',
    'Set-WUPS1Action',
    'Set-WUScalingBehavior',
    'Set-WUWindowsAutoLogin'
  )

  # このモジュールからエクスポートするコマンドレットです。最適なパフォーマンスを得るには、ワイルドカードを使用せず、エクスポートするコマンドレットがない場合は、エントリを削除しないで空の配列を使用してください。
  CmdletsToExport   = @()

  # このモジュールからエクスポートする変数
  VariablesToExport = '*'

  # このモジュールからエクスポートするエイリアスです。最適なパフォーマンスを得るには、ワイルドカードを使用せず、エクスポートするエイリアスがない場合は、エントリを削除しないで空の配列を使用してください。
  AliasesToExport   = @()

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
