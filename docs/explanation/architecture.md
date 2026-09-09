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

- Unit tests verify calculations, transformations, constraints, and state transitions through public behavior. Use test doubles only for dependencies needed to create otherwise impractical scenarios.
- Integration tests exercise Windows APIs, files, processes, and external components. The `Online` tag identifies integration tests that access an internet service.
- Contract tests validate the distribution, manifest, assembly loading, public parameter conventions, and public command help.

`dev.ps1 verify` runs the repository checks, builds the distribution, checks the generated command reference, and runs tests without the `Online` tag. GitHub Actions uses the same command. `dev.ps1 test-online-integration` explicitly runs integration tests tagged `Online`.

Follow the [testing guidelines](https://github.com/yuusakuri/dev-rules/pull/60).
Prefer observable values, saved bytes, registry values, and environment state over
assertions about calls to internal helpers. Exercise private helpers through public
commands. Tests that touch real files or environment variables belong in integration,
even when they need no network or administrator privileges. Test inputs should cover
meaningfully different valid and invalid groups, boundaries, and prohibited transitions.

The HTTP response integration tests use a loopback TCP server with the real HttpClient
and file system. They cover a new download, accepted and ignored ranges, interrupted
transfers, invalid ranges, failure without progress, and WhatIf. These tests verify the
saved bytes and file handle release; the existing online download tests cover remote
service behavior. Certificate configuration and environment setting file tests verify
the real environment through public commands and restore changed values afterward.

Machine environment and PATH tests require an elevated process and are skipped without
it, like the existing machine registry tests. A successful non-administrator run does
not establish those behaviors. Run the full suite on an elevated disposable Windows
runner before merging; autologon, keyboard layout, and online tests retain their explicit
opt-in requirements. Do not enable destructive tests on a normal workstation simply to
increase a pass count.
