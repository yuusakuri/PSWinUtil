# Architecture

PSWinUtil separates its PowerShell source, compiled native interoperability, and built distribution. Development commands build and verify the distribution used by module consumers.

## Source and distribution

`src/PSWinUtil/Public/` contains public commands and their comment-based help. `src/PSWinUtil/Private/` contains internal functions that support those commands.

ModuleBuilder combines the source into the distribution under `output/PSWinUtil`. The distribution contains the module manifest, script module, compiled assembly, and runtime data. Module code is maintained in `src/`, and `dev.ps1 build` generates the distribution.

The command reference is generated from the built module's exported commands and help. `dev.ps1 docs` writes that reference; `dev.ps1 verify` checks that the committed reference matches the current build.

## Native interoperability

`src/PSWinUtil.Native/` provides compiled interoperability with Windows APIs. PowerShell commands use this assembly for operations that require native access. The module manifest declares the assembly required when loading the distribution.

## Windows and external applications

Public commands configure Windows or invoke external applications. Some public commands configure PowerShell session behavior in addition to Windows and external applications. These behaviors are implemented through the module's public commands and are verified against the built distribution.

Each public command's help describes its inputs, outputs, and behavior.

## Tests against the built distribution

Tests import the generated manifest from `output/PSWinUtil`:

- Unit tests isolate command behavior and internal logic with mocks or test doubles.
- Integration tests exercise Windows APIs, files, processes, and external components. The `Online` tag identifies integration tests that access an internet service.
- Contract tests validate the distribution, manifest, assembly loading, public parameter conventions, and public command help.

`dev.ps1 verify` runs the repository checks, builds the distribution, checks the generated command reference, and runs tests without the `Online` tag. GitHub Actions uses the same command. `dev.ps1 test-online-integration` explicitly runs integration tests tagged `Online`.
