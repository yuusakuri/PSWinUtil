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
2. Runs `dev.ps1 verify` and checks the built manifest version.
3. Creates the tag on the merged commit.
4. Builds `PSWinUtil-<version>.zip` and records its build provenance attestation.
5. Publishes `output/PSWinUtil` to PowerShell Gallery with `Publish-PSResource`.
6. Waits until the Gallery exposes the new version.
7. Publishes the GitHub Release with generated notes and the ZIP artifact.

Release runs are serialized with the `release` concurrency group. A rerun accepts an existing tag, Gallery version, or GitHub Release only when the completed publication state is consistent with the same release commit.

## Supply chain

Workflows request `contents: read` by default and raise permissions only in the publishing job. Every action is pinned to a full commit SHA with its version in a trailing comment, so Dependabot and Renovate can still propose updates.
