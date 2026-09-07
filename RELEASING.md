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

Run this on an up-to-date `master` with a clean working tree:

```powershell
git switch master
git pull --ff-only
.\dev.ps1 bump 1.2.3
```

`bump` rejects a version that is not a greater `major.minor.patch` version than the current one, a version whose tag or release branch already exists on the remote, and a working tree with uncommitted tracked changes. It then writes the version to `src/PSWinUtil/PSWinUtil.psd1`, commits it on `release/1.2.3`, pushes the branch, and opens the release pull request. `-WhatIf` reports those steps without performing them.

## Publication

Merging the release pull request starts the `Release` workflow, which runs `dev.ps1 verify` and then `dev.ps1 release <merge-commit> -Branch <release-branch>`. That command:

1. Checks that the checkout is the merged release commit, has no tracked changes or untracked source files, and belongs to the freshly fetched `origin/master`.
2. Reads the manifest from that commit, resolves the version and tag from the release branch, and rejects a version that does not match or that is older than an existing tag.
3. Reads which of the remote tag, the Gallery version, and the GitHub Release already exist. It stops if a service cannot be queried, a publication is inconsistent, or the GitHub Release is still a draft.
4. Packs `PSWinUtil-<version>.zip`, creates the tag on the merged commit, publishes to PowerShell Gallery, waits until the Gallery exposes the version, and publishes the GitHub Release.

The workflow then records a build provenance attestation for the archive it published. Release runs are serialized with the `release` concurrency group, and every publication step skips what is already present for the same release commit, so a rerun completes an interrupted release instead of repeating it. If pushing the tag fails, a rerun pushes the matching local tag before continuing to Gallery publication.

## Running the release locally

Both commands run on a developer machine, so a release can be rehearsed before it is trusted, or completed by hand when GitHub Actions is unavailable:

```powershell
.\dev.ps1 bump 1.2.3 -WhatIf
.\dev.ps1 release <merge-commit> -Branch 'release/1.2.3' -WhatIf
```

Run `.\dev.ps1 verify` on the release commit before publishing locally. `release` reads the Gallery key from the `PSGALLERY_API_KEY` environment variable rather than a parameter. Its checks run before `-WhatIf` decides anything, so a rehearsal still reports a version mismatch or an inconsistent publication state. A rehearsal requires no Gallery key and creates no archive, tag, or publication. A real publication checks the key before creating its archive or tag.

Prefer the workflow for real releases. A local `release` produces no build provenance attestation, because provenance is only meaningful when a trusted builder records it, and it bypasses the `powershell-gallery` Environment and any reviewers configured on it.

## Supply chain

Workflows request `contents: read` by default and raise permissions only in the publishing job. Every action is pinned to a full commit SHA with its version in a trailing comment, so Dependabot and Renovate can still propose updates.
