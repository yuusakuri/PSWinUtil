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

Follow the [testing guidelines](https://github.com/yuusakuri/dev-rules/blob/main/guidelines/software/testing-guidelines.md).

Tests import the generated manifest from `output/PSWinUtil`. The suites are located in `tests/unit/`, `tests/integration/`, and `tests/contract/`. Contract tests also validate the distribution, manifest, assembly loading, public parameter conventions, and public command help.

`dev.ps1 verify` checks the source, formatting, analysis, build output, import, command reference, and tests that do not require external network access. Integration tests requiring external services carry the `Network` tag and run with `dev.ps1 test-network-integration`; loopback HTTP and TCP tests run in normal verification.

Machine environment and PATH tests require administrator privileges. Autologon and keyboard layout tests retain their explicit opt-in environment variables. Skipped tests are reported separately from passed tests.
