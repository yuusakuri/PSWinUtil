# Contributing to PSWinUtil

Test PSWinUtil before submitting a pull request. After cloning the repository, you can build and test it by running development commands from its root in Windows PowerShell 5.1.

## Development environment

Development and verification require:

- Windows PowerShell 5.1 with the `Desktop` edition.
- Git.
- .NET SDK 8.0 or later.

Integration tests exercise machine-level Windows configuration. Use a disposable environment and an elevated Windows PowerShell session when running them.

## Setup

Clone the repository and install the pinned development modules for the current user. `install.ps1` installs the versions declared in `build.requirements.psd1` from PowerShell Gallery:

```powershell
git clone https://github.com/yuusakuri/PSWinUtil.git
Set-Location -Path '.\PSWinUtil'
powershell.exe -ExecutionPolicy Bypass -File '.\install.ps1'
```

## Development workflow

Follow the [Git guidelines](https://github.com/yuusakuri/dev-rules/blob/main/guidelines/development/git-guidelines.md) for branch names, commits, pull requests, reviews, and merging.

This repository uses `master` as its default branch. Create a focused branch from the latest `master` branch.

```powershell
git switch master
git pull --ff-only
git switch -c 'fix/describe-the-change'
```

## Source files

Implement exported commands in `src/PSWinUtil/Public/` and internal functions in `src/PSWinUtil/Private/`, with one function per file. Put tests in `tests/unit/`, `tests/integration/`, or `tests/contract/` according to the behavior they verify. The [architecture explanation](docs/explanation/architecture.md) describes the build output and each test suite.

## Development commands

`dev.ps1` provides the same verification entry points locally and in CI. Running it without a command displays its usage.

| Command | Result |
| --- | --- |
| `.\dev.ps1 format` | Formats PowerShell source files with the repository settings. |
| `.\dev.ps1 analyze` | Runs PSScriptAnalyzer with the repository settings. |
| `.\dev.ps1 lint` | Checks formatting and runs static analysis. |
| `.\dev.ps1 build` | Builds the PowerShell module, native assembly, and test-support assemblies into `output/`. |
| `.\dev.ps1 import` | Imports the previously built module into the current Windows PowerShell session. |
| `.\dev.ps1 docs` | Builds the module and generates the command reference from its exports and help. |
| `.\dev.ps1 docs check` | Builds the module and compares the command reference with its exports and help. |
| `.\dev.ps1 test unit` | Builds the module and runs unit tests. |
| `.\dev.ps1 test integration` | Builds the module and runs Windows integration tests. |
| `.\dev.ps1 test contract` | Builds the module and runs distribution and manifest contract tests. |
| `.\dev.ps1 test all` | Builds the module and runs all test suites. |
| `.\dev.ps1 verify` | Checks source, formatting, analysis, build output, import, the command reference, and all test suites. |
| `.\dev.ps1 ci` | Runs the same verification as `verify`. |

Version preparation and publication commands are described in [Releasing](RELEASING.md).

Build the current source and import the generated module:

```powershell
.\dev.ps1 build
.\dev.ps1 import
Get-Command -Module 'PSWinUtil'
```

## Code and documentation conventions

Follow the [Windows PowerShell module development guidelines](https://github.com/yuusakuri/dev-rules/blob/main/guidelines/implementation/windows-powershell-module-guidelines.md).

After changing an exported command or its synopsis, regenerate and commit the command reference:

```powershell
.\dev.ps1 docs
```

`docs/reference/commands.md` contains the exported command names and their help summaries. `dev.ps1 verify` checks that this file matches the current build.

## Verification

Run the complete repository verification before submitting a pull request:

```powershell
powershell.exe -ExecutionPolicy Bypass -File '.\dev.ps1' verify
```

## Pull requests

Push the branch and open a pull request into `master`, then complete every section of the [pull request template](.github/PULL_REQUEST_TEMPLATE.md).
