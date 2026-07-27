# Contributing

Thanks for considering a contribution to **apex-access-utils**. This document describes how to set up your local environment, the standards the codebase follows, and the process for submitting changes.

## Development setup

You'll need:

- [Node.js](https://nodejs.org/) 18 or later
- [Salesforce CLI](https://developer.salesforce.com/tools/sfdxcli) (`sf`)
- A Salesforce **Dev Hub** org (a free [Developer Edition](https://developer.salesforce.com/signup) works)

### One-time setup

```bash
# Clone the repo
git clone https://github.com/alarussaj/apex-access-utils.git
cd apex-access-utils

# Install Node dependencies (Prettier, Husky, lint-staged)
npm install

# Authorize your Dev Hub
sf org login web --set-default-dev-hub --alias DevHub
```

### Running tests locally

```bash
# Create a scratch org
sf org create scratch --definition-file config/project-scratch-def.json --alias aau-scratch --set-default --duration-days 7

# Deploy the source
sf project deploy start --source-dir force-app --target-org aau-scratch

# Run the tests
sf apex run test --target-org aau-scratch --tests AccessUtils_Test --code-coverage --result-format human --wait 10
```

### Formatting

This project uses [Prettier](https://prettier.io/) with [`prettier-plugin-apex`](https://github.com/dangmai/prettier-plugin-apex).

```bash
# Format all files
npm run format

# Check formatting without changing files (matches CI)
npm run format:check
```

CI will reject pull requests with unformatted files. Run `npm run format` before pushing.

### Static analysis (PMD)

The project uses a custom PMD ruleset (see `pmd-ruleset.xml`). PMD runs in CI on every pull request.

To run PMD locally:

```bash
# Download PMD if you haven't already (https://pmd.github.io/)
pmd check -d force-app -R pmd-ruleset.xml -f text
```

## Pull request process

1. **Open an issue first** for non-trivial changes. Discussion before code saves everyone time.
2. **Fork** the repo and create a feature branch from `main`. Branch names follow `<type>/<short-description>`, where `<type>` matches Conventional Commits prefixes (`feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `ci`, etc.).
3. **Make your changes** with tests covering new behavior.
4. **Run formatting and tests** locally before pushing.
5. **Open a pull request** against `main`. Fill in the PR template. The PR title must follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) — it becomes the squash-commit message on `main`.
6. **CI must pass** — PR title check, Prettier, PMD, scratch org deploy, and all Apex tests.
7. **Wait for review.**

## Coding standards

- **Visibility / sharing**: production classes use `inherited sharing` unless there's a specific reason not to.
- **ApexDoc**: every public class and method has `@description`, `@param`, `@return`, and `@throws` tags as appropriate. Test methods are exempt from `@description`.
- **Test annotations**: use `@IsTest` with capital I/T, not `@isTest`.
- **Tests**: use the `Assert` class (not `System.assert`). Every assertion has a descriptive message. Test methods follow `shouldDoThingWhenCondition` naming. Use `// Arrange`, `// Act`, `// Assert` block comments where they aid readability.
- **Variable naming**: avoid case-insensitive collisions with Schema namespace identifiers. Use `acct` instead of `account`, `requestedAccess` instead of `accessType`, etc.
- **No empty lines inside method bodies.** If a separation is meaningful, add a comment explaining why.

## Release process

Releases are tag-driven and automated by the `release` GitHub Action.

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

## Versioning

This project uses [Semantic Versioning](https://semver.org/). Releases are tagged `vMAJOR.MINOR.PATCH`. Pre-1.0 releases (0.x.y) are considered unstable; minor versions may include breaking changes.

## Code of Conduct

By participating you agree to the [Code of Conduct](CODE_OF_CONDUCT.md).
