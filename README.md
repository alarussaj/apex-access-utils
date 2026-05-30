# apex-access-utils

[![PR Validation](https://github.com/alarussaj/apex-access-utils/actions/workflows/pr-validation.yml/badge.svg)](https://github.com/alarussaj/apex-access-utils/actions/workflows/pr-validation.yml)
[![Release](https://github.com/alarussaj/apex-access-utils/actions/workflows/release.yml/badge.svg)](https://github.com/alarussaj/apex-access-utils/actions/workflows/release.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Apex utilities for enforcing object and field-level security with consistent error handling and observability.

`AccessUtils` wraps `Security.stripInaccessible` with:

- Strict-by-default behavior that throws a clear, formatted exception when any field is stripped or the user has no access to an object
- An opt-in silent mode that returns the stripped records instead of throwing
- An optional logger that fires whenever fields are stripped or no-access is caught, in either mode
- A pre-flight `hasObjectAccess` check for cases where post-hoc stripping is too late (e.g., before building a query)
- An injectable enforcer for unit testing, so consumers can verify their security-related code without restrictive user profiles

## Why

Salesforce gives you `Security.stripInaccessible` for FLS enforcement, but the developer experience leaves gaps:

- The default behavior silently returns stripped records — easy to miss a problem
- Error messages from `NoAccessException` are terse and inconsistent
- Unit-testing the strip behavior requires either fixture users with restrictive profiles, or `runAs` plumbing that's tedious to set up
- There's no built-in observability hook for capturing what was stripped in batch or async contexts

`AccessUtils` addresses all four.

## Installation

Install the latest unlocked package:

**Production / Developer Edition:**

```
https://login.salesforce.com/packaging/installPackage.apexp?p0=<PACKAGE_VERSION_ID>
```

**Sandbox:**

```
https://test.salesforce.com/packaging/installPackage.apexp?p0=<PACKAGE_VERSION_ID>
```

**SFDX:**

```bash
sf package install --package <PACKAGE_VERSION_ID> --target-org <your-org-alias> --wait 10
```

See the [Releases page](https://github.com/alarussaj/apex-access-utils/releases) for the latest package version ID.

## Quick start

### Strict mode (default)

```apex
List<Account> accounts = [SELECT Id, Name, Industry FROM Account];

// Throws AccessUtilsException if any field is stripped or user has no access
List<SObject> safe = AccessUtils.checkRecordAccess(accounts, AccessType.UPDATABLE);

update safe;
```

### Silent mode with a logger

```apex
List<Account> accounts = [SELECT Id, Name, Industry FROM Account];

// Returns stripped records; logger captures what was stripped
List<SObject> safe = AccessUtils.checkRecordAccess(
    accounts,
    AccessType.UPDATABLE,
    AccessOptions.silent().withLogger(new MyAccessLogger())
);

update safe;
```

### Pre-flight check

```apex
if (!AccessUtils.hasObjectAccess(Account.SObjectType, AccessType.READABLE)) {
    throw new MyAppException('Account access is required for this feature.');
}

List<Account> accounts = [SELECT Id, Name FROM Account];
```

## API reference

### `AccessUtils`

| Method | Purpose |
|---|---|
| `checkRecordAccess(SObject, AccessType)` | Strict-mode single-record check |
| `checkRecordAccess(SObject, AccessType, AccessOptions)` | Single-record check with options |
| `checkRecordAccess(List<SObject>, AccessType)` | Strict-mode bulk check |
| `checkRecordAccess(List<SObject>, AccessType, AccessOptions)` | Bulk check with options |
| `hasObjectAccess(SObjectType, AccessType)` | Pre-flight object-level check |

### `AccessOptions`

| Method | Purpose |
|---|---|
| `AccessOptions.strict()` | Factory for strict-mode options |
| `AccessOptions.silent()` | Factory for silent-mode options |
| `withLogger(IAccessLogger)` | Attach an observability logger |
| `withEnforcer(ISecurityEnforcer)` | Override the security enforcer (testing or wrapping) |

### `IAccessLogger`

Interface with a single method:

```apex
void logStrippedFields(Map<String, Set<String>> removedFieldsByObject, AccessType requestedAccess);
```

Implementations write to whatever logging target the consumer prefers (custom object, Platform Event, third-party logger). `apex-access-utils` does not ship a default logger.

### `ISecurityEnforcer`

Seam over `Security.stripInaccessible`. The default implementation (`DefaultSecurityEnforcer`) calls the platform method. Tests substitute `MockSecurityEnforcer`. Custom implementations can wrap the default with caching, logging, feature flags, etc.

## Documentation

- [Getting started](docs/getting-started.md)
- [API reference](docs/api-reference.md)
- [Examples](docs/examples/)

## Versioning

Pre-1.0 releases (0.x.y) are considered unstable; minor versions may include breaking changes. The API will stabilize at 1.0.0.

## Contributing

Issues and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup and submission guidelines.

## License

[MIT](LICENSE)