# Changelog

All notable changes to `apex-access-utils` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Initial release of `AccessUtils` providing a strict-by-default wrapper around `Security.stripInaccessible`.
- `AccessOptions` with `strict()` and `silent()` factory methods, plus `withLogger()` and `withEnforcer()` builders.
- `IAccessLogger` observability hook for capturing stripped fields and no-access events in both strict and silent modes.
- `ISecurityEnforcer` seam over `Security.stripInaccessible` with `DefaultSecurityEnforcer` (production) and `MockSecurityEnforcer` (testing).
- `AccessDecision` wrapper over the platform's `SObjectAccessDecision` to enable mocking.
- `AccessUtils.hasObjectAccess` pre-flight object-level check.
- Per-transaction describe cache keyed by SObject API name, populated via `Type.forName` rather than `Schema.getGlobalDescribe`.
- Custom labels `AccessUtils_InsufficientFieldAccess` and `AccessUtils_InsufficientObjectAccess` for translatable error messages.
- Null filtering on record list inputs to avoid `NullPointerException` from the platform.
- `MockAccessLogger` test-only helper for verifying logger invocation.
- Comprehensive test suite (18 tests) covering strict/silent modes, logger behavior, null handling, mixed-type lists, and describe-cache consistency.