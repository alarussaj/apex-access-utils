# Getting started

This guide walks through installing `apex-access-utils` and using it in the most common scenarios.

## Installation

Install the latest unlocked package version from the [Releases page](https://github.com/alarussaj/apex-access-utils/releases).

```bash
sf package install --package 04tg50000008D4vAAE --target-org <your-org-alias> --wait 10
```

Or via the browser using the install URL from the release.

## Core concept

`AccessUtils.checkRecordAccess` wraps the platform's `Security.stripInaccessible`. It removes fields the running user can't access for the requested operation, and — by default — throws `AccessUtilsException` if anything was stripped or the user has no access to the object at all.

This strict-by-default behavior surfaces access problems loudly instead of silently returning incomplete data.

## Step 1: A basic strict-mode check

```apex
List<Account> accounts = [SELECT Id, Name, Industry FROM Account WHERE Id IN :accountIds];

// Throws AccessUtilsException if the user can't update any of the queried fields.
List<SObject> safe = AccessUtils.checkRecordAccess(accounts, AccessType.UPDATABLE);

update safe;
```

If the running user lacks update access to, say, `Industry`, the call throws with a message like:

```
Insufficient update access to the following fields on Account: Industry.
```

## Step 2: Silent mode

When you'd rather continue processing despite stripped fields — common in batch jobs and integrations — use silent mode. It returns the stripped records instead of throwing.

```apex
List<SObject> safe = AccessUtils.checkRecordAccess(
    accounts,
    AccessType.UPDATABLE,
    AccessOptions.silent()
);

// `safe` has inaccessible fields removed. No exception thrown.
update safe;
```

## Step 3: Adding observability

Attach an `IAccessLogger` to capture what was stripped. The logger fires in both strict and silent modes, so you get an audit trail even when an exception is about to be thrown.

```apex
List<SObject> safe = AccessUtils.checkRecordAccess(
    accounts,
    AccessType.UPDATABLE,
    AccessOptions.silent().withLogger(new MyAccessLogger())
);
```

`apex-access-utils` does not ship a logger implementation — you provide one that writes to wherever you already log (a custom object, a Platform Event, a third-party framework). See the [CustomLoggerExample](examples/CustomLoggerExample.cls).

## Step 4: Pre-flight object checks

`checkRecordAccess` works on records you've already queried. Sometimes you need to check access *before* building a query — for example, to fail fast or to branch logic. Use `hasObjectAccess`:

```apex
if (!AccessUtils.hasObjectAccess(Account.SObjectType, AccessType.READABLE)) {
    // Handle the no-access case before spending a query.
    return;
}

List<Account> accounts = [SELECT Id, Name FROM Account];
```

`hasObjectAccess` supports `READABLE`, `CREATABLE`, `UPDATABLE`, and `UPSERTABLE` (the last requires both create and update).

## Testing your own code

Because `AccessUtils` uses an injectable `ISecurityEnforcer`, you can unit-test your security-dependent code without restrictive profiles or `runAs` plumbing. Inject a `MockSecurityEnforcer`:

```apex
@IsTest
static void shouldHandleStrippedFields() {
    Account acct = new Account(Name = 'Test');
    MockSecurityEnforcer mock = new MockSecurityEnforcer()
        .withRemovedFields(new Map<String, Set<String>>{
            'Account' => new Set<String>{ 'Industry' }
        });

    Boolean threw = false;
    try {
        AccessUtils.checkRecordAccess(
            new List<SObject>{ acct },
            AccessType.UPDATABLE,
            AccessOptions.strict().withEnforcer(mock)
        );
    } catch (AccessUtilsException e) {
        threw = true;
    }

    Assert.isTrue(threw, 'Expected AccessUtilsException when fields are stripped');
    mock.verifyCalledOnce();
}
```

## Next steps

- Read the [API reference](api-reference.md) for full method signatures.
- Browse the [examples](examples/) for real-world usage patterns.
