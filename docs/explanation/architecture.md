# Architecture

PSWinUtil is built into a self-contained module under `output/PSWinUtil`. Tests import that distribution, so they verify the files users receive. ModuleBuilder and the .NET SDK run during the build; importing the distribution requires neither tool.

## Source module

The source manifest, `src/PSWinUtil/PSWinUtil.psd1`, defines the module metadata. It declares Windows PowerShell 5.1 Desktop compatibility and the native assembly required at import time.

The source directory contains the functions, runtime data, and module initialization code:

- `src/PSWinUtil/Public/` contains exported commands.
- `src/PSWinUtil/Private/` contains implementation helpers.
- `src/PSWinUtil/data/` contains registry-setting data used at runtime.
- `src/PSWinUtil/ModuleSuffix.ps1` runs after the function definitions and removes the built-in command proxies when the PowerShell edition is not Desktop.

Each function is defined in one file whose name matches the function name. `src/PSWinUtil/build.psd1` specifies how ModuleBuilder combines these files and copies runtime data.

Public commands include comment-based help, and state-changing commands use PowerShell's `ShouldProcess` contract.

## Native interoperability

`src/PSWinUtil.Native/` is a .NET project that contains the Windows Local Security Authority interoperability used by automatic logon commands. The build produces `PSWinUtil.Native.dll`; users do not compile C# when importing PSWinUtil.

The source manifest lists the DLL in `RequiredAssemblies`, so PowerShell loads it before the generated script module.

## Build and distribution

`dev.ps1 build` creates the distribution and the assemblies used by tests:

1. ModuleBuilder combines the public, private, and module-suffix PowerShell sources into `output/PSWinUtil/PSWinUtil.psm1` and generates an explicit export list in the distribution manifest.
2. The .NET SDK builds `PSWinUtil.Native.dll`, which is copied to `output/PSWinUtil/lib/`.
3. The .NET SDK builds `PSWinUtil.TestSupport.dll` for `net472` and `netstandard2.0`, placing each assembly under `output/TestSupport/<framework>/` for use by tests.

Runtime data is copied beside the generated module. Source files, test projects, development settings, and intermediate build output are excluded from the distribution.

Edit module code in `src/` and test code in `tests/`. Running `dev.ps1 build` regenerates `output/PSWinUtil` and `output/TestSupport`, so edits to those output directories do not survive the next build.

## Windows and external applications

Public commands delegate operations to Windows APIs or external applications:

- The registry and environment APIs for Windows settings, environment variables, startup entries, and keyboard mappings.
- Windows native APIs for protected automatic-logon secrets.
- File and path APIs for UTF-8 text, path resolution, and PowerShell syntax inspection.
- HTTP and process boundaries for downloads, package managers, SDKs, OpenSSH, Java, and Node.js.

The module has no third-party PowerShell module dependency at import time. Commands that integrate with an external executable validate or install that dependency as described by their help; importing unrelated commands does not trigger installation.

The module also exports Desktop-only proxies for `Add-Content`, `Get-Content`, `Set-Content`, `Out-File`, and `Invoke-WebRequest`. These preserve the built-in command parameters while changing the documented encoding or progress behavior. Use a module-qualified command such as `Microsoft.PowerShell.Management\Get-Content` when the built-in behavior is required explicitly.

## Tests against the built module

All test suites import the generated manifest from `output/PSWinUtil`:

- Unit tests isolate command behavior and internal logic with mocks or test doubles.
- Integration tests exercise Windows APIs, the registry, files, processes, and external components.
- Contract tests validate the manifest, distribution contents, native assembly, clean-process import, exported commands, and comment-based help.

`dev.ps1 ci` checks source layout and encoding, formatting, static analysis, the build, distribution contracts, and all test suites in the same order used by GitHub Actions.
