# Releasing PSWinUtil

A maintainer selects the version locally and a release pull request carries it into `master`. Approving and merging that pull request is the only manual step in the publication.

## One-time setup

1. Create a scoped PowerShell Gallery API key that can publish new versions of the `PSWinUtil` package. PowerShell Gallery has no OpenID Connect publishing, so an API key is the only supported publishing credential.
2. Create a GitHub Environment named `powershell-gallery`.
3. Add the API key to that Environment as a secret named `PSGALLERY_API_KEY`.
4. Optionally configure required reviewers on the Environment so publication needs a second approval.
5. Ensure GitHub Actions is allowed to create pull requests, tags, and releases with `GITHUB_TOKEN`.

Install the GitHub CLI and sign in with `gh auth login` before preparing a release. Never store the API key in the repository or pass it as a workflow input.

## Prepare a release

Run these commands on an up-to-date `master` with a clean working tree:

```powershell
git switch master
git pull --ff-only
.\dev.ps1 bump 1.2.3
git diff
.\dev.ps1 release
```

`bump` writes the version to `src/PSWinUtil/PSWinUtil.psd1` and changes nothing else. It rejects a version that is not a greater `major.minor.patch` version than the current one.

`release` reads the version from the manifest. It refuses to continue when another tracked file changed, when the remote already has the `v1.2.3` tag, or when the remote already has the `release/1.2.3` branch. It then commits the manifest, pushes `release/1.2.3`, and opens the release pull request. `-WhatIf` reports those steps without performing them.

## Publication

Merging the release pull request starts the `Release` workflow. The workflow:

1. Checks the release branch, merged commit, source `ModuleVersion`, and `v<version>` tag identity.
2. Runs `dev.ps1 verify`.
3. Builds `PSWinUtil-<version>.zip` and records its build provenance attestation.
4. Creates the tag on the merged commit, publishes `output/PSWinUtil` to PowerShell Gallery, waits until the Gallery exposes the version, and publishes the GitHub Release.

Release runs are serialized with the `release` concurrency group. Steps 3 and 4 skip whatever is already published for the same release commit, so a rerun completes an interrupted release instead of repeating it.

## Running the release steps locally

The workflow runs `dev.ps1` commands that also work on a developer machine, so a release can be rehearsed before it is trusted, or completed by hand when GitHub Actions is unavailable:

```powershell
.\dev.ps1 release-identity 'release/1.2.3'
.\dev.ps1 release-state <merge-commit>
.\dev.ps1 build
.\dev.ps1 release-pack
.\dev.ps1 release-publish <merge-commit> -WhatIf
```

`release-identity` and `release-state` only read, so they are safe to run at any time. `release-publish` reports every tag, Gallery, and GitHub Release action under `-WhatIf` without performing it, and reads the Gallery key from the `PSGALLERY_API_KEY` environment variable rather than a parameter.

Prefer the workflow for real releases. A local `release-publish` produces no build provenance attestation, because provenance is only meaningful when a trusted builder records it, and it bypasses the `powershell-gallery` Environment and any reviewers configured on it.

## Supply chain

Workflows request `contents: read` by default and raise permissions only in the publishing job. Every action is pinned to a full commit SHA with its version in a trailing comment, so Dependabot and Renovate can still propose updates.
