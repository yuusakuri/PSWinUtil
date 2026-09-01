# Releasing PSWinUtil

PSWinUtil releases start with a version selected by a maintainer. Repository changes are reviewed in a release pull request before any package is published.

## One-time setup

1. Create a scoped PowerShell Gallery API key that can publish new versions of the `PSWinUtil` package.
2. Create a GitHub Environment named `powershell-gallery`.
3. Add the API key to that Environment as a secret named `PSGALLERY_API_KEY`.
4. Optionally configure required reviewers on the Environment so publication requires approval.
5. Ensure GitHub Actions is allowed to create branches, pull requests, tags, and releases with `GITHUB_TOKEN`.

Never store the PowerShell Gallery API key in the repository or pass it as a workflow input.

## Prepare a release

1. Open the `Prepare release` workflow in GitHub Actions.
2. Select **Run workflow** on `master`.
3. Enter the complete stable version in `major.minor.patch` format, such as `2.1.0`.
4. Review the generated `release/<version>` pull request and its checks.
5. Merge the pull request into `master`.

The preparation workflow rejects a version that is not greater than the current `ModuleVersion`, an existing release branch, or an existing `v<version>` tag. It updates only `src/PSWinUtil/PSWinUtil.psd1` and runs `dev.ps1 verify` before creating the pull request.

Pull requests created with `GITHUB_TOKEN` can require a maintainer to approve their workflow runs. The preparation workflow runs the same verification before creating the pull request, but required pull-request checks should still be approved and reviewed before merge.

## Publication

Merging a valid `release/<version>` pull request starts the `Release` workflow. The workflow:

1. Checks the release branch, merged commit, source `ModuleVersion`, and `v<version>` tag identity.
2. Runs `dev.ps1 verify` and checks the built manifest version.
3. Creates the tag on the merged commit.
4. Builds `PSWinUtil-<version>.zip`.
5. Publishes `output/PSWinUtil` to PowerShell Gallery.
6. Waits until the Gallery exposes the new version.
7. Publishes the GitHub Release with generated notes and the ZIP artifact.

Release runs are serialized with the `release` concurrency group. A rerun accepts an existing tag, Gallery version, or GitHub Release only when the completed publication state is consistent with the same release commit.
