# Contributing to PSWinUtil

Build and test PSWinUtil from source before submitting a pull request. Run the commands below from the repository root in Windows PowerShell 5.1.

## Development environment

Development and verification require:

- Windows PowerShell 5.1 with the `Desktop` edition.
- Git.
- .NET SDK 8.0 or later.

Integration tests exercise Windows and machine-level configuration. Run them in a disposable environment from an elevated Windows PowerShell session.

## Setup

Clone the repository and enter its directory:

```powershell
git clone https://github.com/yuusakuri/PSWinUtil.git
Set-Location -Path '.\PSWinUtil'
```

Install the pinned development modules for the current user:

```powershell
powershell.exe -ExecutionPolicy Bypass -File '.\install.ps1'
```

The script installs the versions declared in `build.requirements.psd1` from PowerShell Gallery.

## Development workflow

Follow the project [Git guidelines](https://github.com/yuusakuri/dev-rules/blob/main/guidelines/core/git-guidelines.md). This repository uses `master` as its default branch, so create one focused [Conventional Branch](https://conventional-branch.github.io/) from the latest `master` branch:

```powershell
git switch master
git pull --ff-only
git switch -c 'fix/describe-the-change'
```

Use [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) with a title of at most 50 characters. Do not add an AI-agent prefix to the branch name.

Add or update tests whenever observable behavior changes. Keep the pull request limited to one related change.

## Source files

Implement exported commands in `src/PSWinUtil/Public/` and internal functions in `src/PSWinUtil/Private/`, with one function per file. Put tests in `tests/unit/`, `tests/integration/`, or `tests/contract/` according to the behavior they verify. The [architecture explanation](docs/explanation/architecture.md) describes the build output and each test suite.

## Development commands

`dev.ps1` provides the same verification entry points locally and in CI. Running it without a command displays its usage.

| Command | Result |
| --- | --- |
| `.\dev.ps1 format` | Formats PowerShell source files with the repository settings. |
| `.\dev.ps1 analyze` | Runs PSScriptAnalyzer with the repository settings. |
| `.\dev.ps1 build` | Builds the PowerShell module, native assembly, and test-support assemblies into `output/`. |
| `.\dev.ps1 import` | Imports the previously built module into the current Windows PowerShell session. |
| `.\dev.ps1 test unit` | Builds the module and runs unit tests. |
| `.\dev.ps1 test integration` | Builds the module and runs Windows integration tests. |
| `.\dev.ps1 test contract` | Builds the module and runs distribution and manifest contract tests. |
| `.\dev.ps1 test all` | Builds the module and runs all test suites. |
| `.\dev.ps1 ci` | Checks source, formatting, analysis, build output, import, and all test suites. |

Build the current source and import the generated module:

```powershell
.\dev.ps1 build
.\dev.ps1 import
Get-Command -Module 'PSWinUtil'
```

## Code and documentation conventions

Follow the [Windows PowerShell module development guidelines](https://github.com/yuusakuri/dev-rules/blob/main/guidelines/implementation/windows-powershell-module-guidelines.md).

PowerShell source files use ASCII characters, UTF-8 without a byte-order mark (BOM), and LF line endings. `dev.ps1` validates the source files before building or testing.

Public functions require comment-based help with `.SYNOPSIS`, `.DESCRIPTION`, documentation for every public parameter, and at least one `.EXAMPLE`. Add `.INPUTS` and `.OUTPUTS` when applicable. Contract tests verify these requirements against the built module.

Documentation has distinct roles:

- Keep `README.md` focused on the project purpose, requirements, installation, and a minimal example.
- Put guided learning in `docs/tutorials/`.
- Put task-oriented instructions in `docs/how-to/` when needed.
- Put factual command or configuration material in `docs/reference/`.
- Put design background in `docs/explanation/`.

Write examples against the built module and prefer `-WhatIf` when demonstrating state-changing commands.

## Verification

Run the complete repository verification before submitting a pull request:

```powershell
powershell.exe -ExecutionPolicy Bypass -File '.\dev.ps1' ci
```

Warnings from formatting, analysis, builds, or tests must be resolved before merge.

## Pull requests

Push the branch and open a pull request into `master`. Use the [pull request template](.github/PULL_REQUEST_TEMPLATE.md):

- `Description`: Explain why the change is needed and what it changes.
- `Related issue`: Reference an issue with `Closes #123`, or write `None`.
- `Verification`: Record verification commands and results, including any checks that could not be run and why.

At least one approval is required. Merge with squash after all required checks pass.
