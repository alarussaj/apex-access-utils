# Contributing

Thanks for your interest in `apex-access-utils`. This document describes how to set up your local environment, the standards the codebase follows, and the process for submitting changes.

## Development setup

Prerequisites:

- A Salesforce Dev Hub (production or developer edition org with Dev Hub enabled)
- [Salesforce CLI](https://developer.salesforce.com/tools/sfdxcli) (`sf` command)
- Node.js 18+ (for Prettier and lint-staged)
- Git

Clone the repo:

```bash
git clone https://github.com/alarussaj/apex-access-utils.git
cd apex-access-utils
```

Install Node tooling (Husky, lint-staged, Prettier):

```bash
npm install
```

Authenticate your Dev Hub:

```bash
sf org login web --alias DevHub --set-default-dev-hub
```

Create a scratch org and deploy:

```bash
sf org create scratch \
    --definition-file config/project-scratch-def.json \
    --alias AauDev \
    --duration-days 7 \
    --set-default

sf project deploy start --source-dir force-app --target-org AauDev
```

Run the tests:

```bash
sf apex run test --target-org AauDev --tests AccessUtils_Test --result-format human --wait 10
```

## Coding standards

- **Apex**: API version 64.0. Use `inherited sharing` on all production classes unless there's a specific reason not to.
- **ApexDoc**: every public class and method has `@description`, `@param` for each parameter, `@return` for non-void methods, and `@throws` where applicable. Test methods are exempt from `@description` per the PMD `ApexUnitTestClassShouldHaveAsserts` exemption.
- **Test annotations**: use `@IsTest` with capital I/T, not `@isTest`.
- **Variable naming**: avoid case-insensitive collisions with Schema namespace identifiers. Use `acct` instead of `account`, `requestedAccess` instead of `accessType`, etc.
- **Formatting**: enforced via Prettier (`prettier-plugin-apex`). Run `npm run format` before committing.
- **Static analysis**: enforced via PMD. The ruleset is at `pmd-ruleset.xml`.

## Submitting changes

1. **Open an issue first** for non-trivial changes. Discussion before code saves everyone time.
2. **Fork and branch**: branch names should follow `<type>/<short-description>`, where `<type>` matches Conventional Commits prefixes (`feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `ci`, etc.).
3. **Commit messages**: follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/). The PR title becomes the squash-commit message, so the same convention applies there.
4. **Tests**: every code change must be accompanied by tests. Bug fixes should include a regression test.
5. **PR validation**: the `pr-validation` GitHub Action will deploy your branch to a scratch org and run all tests. PRs cannot merge until it passes.
6. **Documentation**: if your change affects the public API, update the relevant `docs/` files and the `CHANGELOG.md` under `[Unreleased]`.

## Release process

Releases are tag-driven and automated by the `release` GitHub Action.

To cut a release:

1. Ensure `main` is green and contains everything to be released.
2. Update `CHANGELOG.md`: move items from `[Unreleased]` into a new version section.
3. Bump the version in `sfdx-project.json` (`versionName` and `versionNumber`).
4. Open a PR, merge it.
5. Tag the merge commit and push:

   ```bash
   git checkout main
   git pull
   git tag -a v0.x.y -m "Release v0.x.y"
   git push origin v0.x.y
   ```

6. The release workflow creates the unlocked package version, promotes it, and publishes a GitHub release.

## Code of Conduct

By contributing to this project, you agree to abide by its [Code of Conduct](CODE_OF_CONDUCT.md).