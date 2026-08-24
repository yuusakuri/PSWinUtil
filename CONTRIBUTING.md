# Contributing to PSWinUtil

Thank you for contributing to PSWinUtil. This guide explains how to prepare the development environment, verify a change, and submit a pull request.

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

Follow the [Git guidelines](https://github.com/yuusakuri/dev-rules/blob/main/guidelines/core/git-guidelines.md) for branch names, commit messages, verification, review, and merging. This repository uses `master` as its default branch, so create a focused branch from the latest `master` branch.

```powershell
git switch master
git pull --ff-only
git switch -c 'fix/describe-the-change'
```

Keep each pull request limited to one related change. Add or update tests whenever observable behavior changes.

A pull request description must explain the problem and the resulting behavior, identify related issues, and list the verification commands that passed.

## Development commands

`dev.ps1` provides the same verification entry points locally and in CI. Running it without a command displays its usage.

| Command | Result |
| --- | --- |
| `.\dev.ps1 format` | Formats PowerShell source files with the repository settings. |
| `.\dev.ps1 analyze` | Runs PSScriptAnalyzer with the repository settings. |
| `.\dev.ps1 build` | Builds the PowerShell module and its C# assemblies into `output/`. |
| `.\dev.ps1 test unit` | Builds the module and runs unit tests. |
| `.\dev.ps1 test integration` | Builds the module and runs Windows integration tests. |
| `.\dev.ps1 test contract` | Builds the module and runs distribution and manifest contract tests. |
| `.\dev.ps1 test all` | Builds the module and runs unit, integration, and contract tests. |
| `.\dev.ps1 ci` | Checks formatting, performs static analysis, builds the distribution, validates it, and runs every test suite. |

Run the complete verification before submitting a pull request:

```powershell
powershell.exe -ExecutionPolicy Bypass -File '.\dev.ps1' ci
```

## Code conventions

Follow the [Windows PowerShell module development guidelines](https://github.com/yuusakuri/dev-rules/blob/main/guidelines/implementation/windows-powershell-module-guidelines.md).
