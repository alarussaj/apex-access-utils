# API reference

Full reference for the public surface of `apex-access-utils`.

## AccessUtils

The main entry point. All methods are static. Declared `inherited sharing`.

### checkRecordAccess(SObject, AccessType)

```apex
public static SObject checkRecordAccess(SObject record, AccessType requestedAccess)
```

Strict-mode single-record check. Equivalent to calling the three-argument overload with `AccessOptions.strict()`.

- **record** — the SObject to check; may be null
- **requestedAccess** — the `AccessType` to enforce
- **Returns** — the record with inaccessible fields stripped, or null if the input was null
- **Throws** — `AccessUtilsException` in strict mode when fields are stripped or the user has no access

### checkRecordAccess(SObject, AccessType, AccessOptions)

```apex
public static SObject checkRecordAccess(SObject record, AccessType requestedAccess, AccessOptions options)
```

Single-record check with caller-supplied options. Returns null when the input record is null.

### checkRecordAccess(List&lt;SObject&gt;, AccessType)

```apex
public static List<SObject> checkRecordAccess(List<SObject> records, AccessType requestedAccess)
```

Strict-mode bulk check. Supports mixed SObject types in the same list. Null entries are filtered out before enforcement.

- **Returns** — the records with inaccessible fields stripped, or an empty list if the input was null/empty

### checkRecordAccess(List&lt;SObject&gt;, AccessType, AccessOptions)

```apex
public static List<SObject> checkRecordAccess(List<SObject> records, AccessType requestedAccess, AccessOptions options)
```

Bulk check with caller-supplied options. Supports mixed SObject types and filters null entries.

Behavior by mode:

- **Strict** — throws `AccessUtilsException` if any field is stripped or `NoAccessException` is raised
- **Silent** — returns the stripped records; returns an empty list if `NoAccessException` is raised

In both modes, an attached logger fires whenever fields are stripped or no-access is caught.

### hasObjectAccess(SObjectType, AccessType)

```apex
public static Boolean hasObjectAccess(SObjectType objectType, AccessType requestedAccess)
```

Pre-flight object-level access check. Useful before constructing a query, when the post-hoc strip approach is too late.

- **objectType** — the `SObjectType` to check; returns false if null
- **requestedAccess** — one of `READABLE`, `CREATABLE`, `UPDATABLE`, `UPSERTABLE`
- **Returns** — true if the running user has the requested access; `UPSERTABLE` requires both create and update

## AccessOptions

Per-call behavior configuration. Declared `inherited sharing`.

### Factory methods

```apex
public static AccessOptions strict()
public static AccessOptions silent()
```

`strict()` throws on stripped fields or no access. `silent()` suppresses the exception and returns the stripped records.

### Builder methods

```apex
public AccessOptions withLogger(IAccessLogger logger)
public AccessOptions withEnforcer(ISecurityEnforcer enforcer)
```

`withLogger` attaches an observability logger. `withEnforcer` substitutes a custom enforcer (used by tests and custom wrappers). Both return the options instance for chaining.

### Mode enum

```apex
public enum Mode {
  STRICT,
  SILENT
}
```

## IAccessLogger

Observability hook. Implement to capture stripped fields and no-access events.

```apex
public interface IAccessLogger {
  void logStrippedFields(Map<String, Set<String>> removedFieldsByObject, AccessType requestedAccess);
}
```

- **removedFieldsByObject** — map of object API name to set of stripped field API names; empty for `NoAccessException` cases
- **requestedAccess** — the `AccessType` being enforced when the event occurred

`apex-access-utils` does not provide a default implementation.

## ISecurityEnforcer

Seam over `Security.stripInaccessible`.

```apex
public interface ISecurityEnforcer {
  AccessDecision stripInaccessible(AccessType requestedAccess, List<SObject> records);
}
```

Implementations:

- **DefaultSecurityEnforcer** — production default; delegates to the platform method
- **MockSecurityEnforcer** — test-only; configurable responses and call verification

## AccessDecision

Wrapper over the platform's `SObjectAccessDecision`, returned by `ISecurityEnforcer`. Exists so mocks can construct return values, since `SObjectAccessDecision` has no public constructor.

```apex
public AccessDecision(List<SObject> records, Map<String, Set<String>> removedFields)
public static AccessDecision wrap(SObjectAccessDecision decision)
public List<SObject> getRecords()
public Map<String, Set<String>> getRemovedFields()
public Boolean hasRemovedFields()
```

## AccessUtilsException

Thrown by `AccessUtils` in strict mode. Extends the standard Apex `Exception`.

```apex
public class AccessUtilsException extends Exception {
}
```

## Test helpers

These classes are annotated `@IsTest` and are available to consumer test code.

### MockSecurityEnforcer

Configurable test double for `ISecurityEnforcer`.

Configuration (fluent):

- `withRemovedFields(Map<String, Set<String>>)` — set the removed-fields map to return
- `returnsRecords(List<SObject>)` — set the records to return instead of echoing input
- `throwsNoAccess()` / `throwsNoAccess(String)` — configure the mock to throw `NoAccessException`

Verification:

- `verifyCalled()`, `verifyCalledOnce()`, `verifyCalledTimes(Integer)`, `verifyNeverCalled()`
- `verifyCalledWith(AccessType)`
- `verifyLastCallRecordCount(Integer)`

Public capture fields for custom assertions: `callCount`, `capturedAccessTypes`, `capturedRecords`.

### MockAccessLogger

Test double for `IAccessLogger`.

Verification:

- `verifyCalled()`, `verifyCalledOnce()`, `verifyNeverCalled()`
- `verifyCalledWith(AccessType)`
- `verifyLoggedFieldOn(String objectApiName, String fieldApiName)`

Public capture fields: `callCount`, `capturedRemovedFields`, `capturedAccessTypes`.

## Custom labels

Two custom labels back the error messages and can be translated via Salesforce's translation workbench:

- **AccessUtils_InsufficientFieldAccess** — `Insufficient {0} access to the following fields on {1}: {2}.`
- **AccessUtils_InsufficientObjectAccess** — `Insufficient access to {0} {1} records: {2}`
