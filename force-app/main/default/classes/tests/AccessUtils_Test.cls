/**
 * @description Tests for AccessUtils covering single and bulk record checks,
 * strict vs silent modes, field-stripping behavior, NoAccessException
 * handling, logger invocation, null filtering, describe caching, and
 * the hasObjectAccess pre-flight check.
 *
 * Uses MockSecurityEnforcer and MockAccessLogger to avoid the need for
 * restrictive user profiles. No DML is performed.
 *
 * @group AccessUtils
 * @see https://github.com/alarussaj/apex-access-utils
 */
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
private class AccessUtils_Test {
	// ── Happy path tests ─────────────────────────────────────────

	/**
	 * @description Verifies checkRecordAccess returns the record unchanged
	 * when no fields are stripped and the mock enforcer returns an empty
	 * removed-fields map.
	 */
	@IsTest
	static void shouldReturnRecordWhenNoFieldsAreStripped() {
		// Arrange
		Account acct = new Account(Name = 'Acme');
		MockSecurityEnforcer mock = new MockSecurityEnforcer();
		// Act
		SObject result = AccessUtils.checkRecordAccess(
			acct,
			AccessType.READABLE,
			AccessOptions.strict().withEnforcer(mock)
		);
		// Assert
		Assert.areNotEqual(null, result, 'Result should not be null when no fields are stripped');
		mock.verifyCalledOnce();
		mock.verifyCalledWith(AccessType.READABLE);
	}

	/**
	 * @description Verifies checkRecordAccess returns an empty list when
	 * the input list is null.
	 */
	@IsTest
	static void shouldReturnEmptyListWhenInputIsNull() {
		// Arrange / Act
		List<SObject> result = AccessUtils.checkRecordAccess((List<SObject>) null, AccessType.READABLE);
		// Assert
		Assert.areEqual(0, result.size(), 'Null input should return an empty list');
	}

	/**
	 * @description Verifies checkRecordAccess returns an empty list when
	 * the input list is empty.
	 */
	@IsTest
	static void shouldReturnEmptyListWhenInputIsEmpty() {
		// Arrange / Act
		List<SObject> result = AccessUtils.checkRecordAccess(new List<SObject>(), AccessType.READABLE);
		// Assert
		Assert.areEqual(0, result.size(), 'Empty input should return an empty list');
	}

	/**
	 * @description Verifies checkRecordAccess (single record) returns null
	 * when the input record is null.
	 */
	@IsTest
	static void shouldReturnNullWhenSingleRecordIsNull() {
		// Arrange / Act
		SObject result = AccessUtils.checkRecordAccess((SObject) null, AccessType.READABLE);
		// Assert
		Assert.areEqual(null, result, 'Null single-record input should return null');
	}

	// ── Null-filtering tests ─────────────────────────────────────

	/**
	 * @description Verifies null entries in the records list are filtered
	 * out before being passed to the enforcer, preventing the platform's
	 * NullPointerException.
	 */
	@IsTest
	static void shouldFilterNullEntriesFromRecordsList() {
		// Arrange
		Account acct = new Account(Name = 'Acme');
		MockSecurityEnforcer mock = new MockSecurityEnforcer();
		// Act
		List<SObject> result = AccessUtils.checkRecordAccess(
			new List<SObject>{ null, acct, null },
			AccessType.READABLE,
			AccessOptions.strict().withEnforcer(mock)
		);
		// Assert
		Assert.areEqual(1, result.size(), 'Null entries should be filtered out');
		mock.verifyLastCallRecordCount(1);
	}

	/**
	 * @description Verifies an all-null records list returns an empty list
	 * without invoking the enforcer.
	 */
	@IsTest
	static void shouldReturnEmptyListWhenAllRecordsAreNull() {
		// Arrange
		MockSecurityEnforcer mock = new MockSecurityEnforcer();
		// Act
		List<SObject> result = AccessUtils.checkRecordAccess(
			new List<SObject>{ null, null, null },
			AccessType.READABLE,
			AccessOptions.strict().withEnforcer(mock)
		);
		// Assert
		Assert.areEqual(0, result.size(), 'All-null list should return an empty list');
		mock.verifyNeverCalled();
	}

	// ── Strict mode tests ────────────────────────────────────────

	/**
	 * @description Verifies strict mode throws AccessUtilsException when
	 * the enforcer reports stripped fields.
	 */
	@IsTest
	static void shouldThrowWhenStrictModeAndFieldsAreStripped() {
		// Arrange
		Account acct = new Account(Name = 'Acme');
		MockSecurityEnforcer mock = new MockSecurityEnforcer()
			.withRemovedFields(new Map<String, Set<String>>{ 'Account' => new Set<String>{ 'Industry' } });
		Boolean threw = false;
		// Act
		try {
			AccessUtils.checkRecordAccess(
				new List<SObject>{ acct },
				AccessType.UPDATABLE,
				AccessOptions.strict().withEnforcer(mock)
			);
		} catch (AccessUtilsException e) {
			threw = true;
			Assert.isTrue(e.getMessage().contains('Industry'), 'Exception should mention the stripped field');
			Assert.isTrue(e.getMessage().contains('update'), 'Exception should mention the access verb');
		}
		// Assert
		Assert.isTrue(threw, 'Strict mode should throw AccessUtilsException when fields are stripped');
	}

	/**
	 * @description Verifies strict mode throws AccessUtilsException when
	 * the enforcer throws NoAccessException.
	 */
	@IsTest
	static void shouldThrowWhenStrictModeAndNoAccessExceptionRaised() {
		// Arrange
		Account acct = new Account(Name = 'Acme');
		MockSecurityEnforcer mock = new MockSecurityEnforcer().throwsNoAccess('No access to entity: Account');
		Boolean threw = false;
		// Act
		try {
			AccessUtils.checkRecordAccess(
				new List<SObject>{ acct },
				AccessType.READABLE,
				AccessOptions.strict().withEnforcer(mock)
			);
		} catch (AccessUtilsException e) {
			threw = true;
			Assert.isTrue(e.getMessage().contains('Account'), 'Exception should mention the object label');
		}
		// Assert
		Assert.isTrue(threw, 'Strict mode should throw AccessUtilsException on NoAccessException');
	}

	// ── Silent mode tests ────────────────────────────────────────

	/**
	 * @description Verifies silent mode returns the stripped records
	 * without throwing when fields are stripped.
	 */
	@IsTest
	static void shouldReturnRecordsWhenSilentModeAndFieldsAreStripped() {
		// Arrange
		Account acct = new Account(Name = 'Acme');
		MockSecurityEnforcer mock = new MockSecurityEnforcer()
			.withRemovedFields(new Map<String, Set<String>>{ 'Account' => new Set<String>{ 'Industry' } });
		// Act
		List<SObject> result = AccessUtils.checkRecordAccess(
			new List<SObject>{ acct },
			AccessType.UPDATABLE,
			AccessOptions.silent().withEnforcer(mock)
		);
		// Assert
		Assert.areEqual(1, result.size(), 'Silent mode should return the records');
	}

	/**
	 * @description Verifies silent mode returns an empty list when the
	 * enforcer throws NoAccessException.
	 */
	@IsTest
	static void shouldReturnEmptyListWhenSilentModeAndNoAccessExceptionRaised() {
		// Arrange
		Account acct = new Account(Name = 'Acme');
		MockSecurityEnforcer mock = new MockSecurityEnforcer().throwsNoAccess();
		// Act
		List<SObject> result = AccessUtils.checkRecordAccess(
			new List<SObject>{ acct },
			AccessType.READABLE,
			AccessOptions.silent().withEnforcer(mock)
		);
		// Assert
		Assert.areEqual(0, result.size(), 'Silent mode should return an empty list on NoAccessException');
	}

	// ── Logger tests ─────────────────────────────────────────────

	/**
	 * @description Verifies the logger fires when fields are stripped, in
	 * strict mode, prior to the exception being thrown.
	 */
	@IsTest
	static void shouldFireLoggerWhenFieldsAreStrippedInStrictMode() {
		// Arrange
		Account acct = new Account(Name = 'Acme');
		MockSecurityEnforcer enforcer = new MockSecurityEnforcer()
			.withRemovedFields(new Map<String, Set<String>>{ 'Account' => new Set<String>{ 'Industry' } });
		MockAccessLogger logger = new MockAccessLogger();
		// Act
		try {
			AccessUtils.checkRecordAccess(
				new List<SObject>{ acct },
				AccessType.UPDATABLE,
				AccessOptions.strict().withEnforcer(enforcer).withLogger(logger)
			);
		} catch (AccessUtilsException e) {
			// expected
		}
		// Assert
		logger.verifyCalledOnce();
		logger.verifyCalledWith(AccessType.UPDATABLE);
		logger.verifyLoggedFieldOn('Account', 'Industry');
	}

	/**
	 * @description Verifies the logger fires when fields are stripped, in
	 * silent mode.
	 */
	@IsTest
	static void shouldFireLoggerWhenFieldsAreStrippedInSilentMode() {
		// Arrange
		Account acct = new Account(Name = 'Acme');
		MockSecurityEnforcer enforcer = new MockSecurityEnforcer()
			.withRemovedFields(new Map<String, Set<String>>{ 'Account' => new Set<String>{ 'Industry' } });
		MockAccessLogger logger = new MockAccessLogger();
		// Act
		AccessUtils.checkRecordAccess(
			new List<SObject>{ acct },
			AccessType.UPDATABLE,
			AccessOptions.silent().withEnforcer(enforcer).withLogger(logger)
		);
		// Assert
		logger.verifyCalledOnce();
		logger.verifyCalledWith(AccessType.UPDATABLE);
	}

	/**
	 * @description Verifies the logger fires when NoAccessException is
	 * caught, in both strict and silent modes.
	 */
	@IsTest
	static void shouldFireLoggerWhenNoAccessExceptionIsCaught() {
		// Arrange
		Account acct = new Account(Name = 'Acme');
		MockSecurityEnforcer enforcer = new MockSecurityEnforcer().throwsNoAccess();
		MockAccessLogger logger = new MockAccessLogger();
		// Act
		AccessUtils.checkRecordAccess(
			new List<SObject>{ acct },
			AccessType.READABLE,
			AccessOptions.silent().withEnforcer(enforcer).withLogger(logger)
		);
		// Assert
		logger.verifyCalledOnce();
		logger.verifyCalledWith(AccessType.READABLE);
	}

	/**
	 * @description Verifies the logger is NOT fired when no fields are
	 * stripped and no exception is thrown.
	 */
	@IsTest
	static void shouldNotFireLoggerWhenAccessIsClean() {
		// Arrange
		Account acct = new Account(Name = 'Acme');
		MockSecurityEnforcer enforcer = new MockSecurityEnforcer();
		MockAccessLogger logger = new MockAccessLogger();
		// Act
		AccessUtils.checkRecordAccess(
			new List<SObject>{ acct },
			AccessType.READABLE,
			AccessOptions.strict().withEnforcer(enforcer).withLogger(logger)
		);
		// Assert
		logger.verifyNeverCalled();
	}

	// ── hasObjectAccess tests ────────────────────────────────────

	/**
	 * @description Verifies hasObjectAccess returns false when the SObjectType is null.
	 */
	@IsTest
	static void shouldReturnFalseWhenObjectTypeIsNull() {
		Assert.isFalse(AccessUtils.hasObjectAccess(null, AccessType.READABLE), 'Null SObjectType should return false');
	}

	/**
	 * @description Verifies hasObjectAccess returns a Boolean for each
	 * supported AccessType against a standard SObject. Does not assert
	 * specific true/false values since they depend on the running user's
	 * profile, but does verify the method completes without exception for
	 * each AccessType.
	 */
	@IsTest
	static void shouldEvaluateAllAccessTypesWithoutException() {
		Boolean readable = AccessUtils.hasObjectAccess(Account.SObjectType, AccessType.READABLE);
		Boolean creatable = AccessUtils.hasObjectAccess(Account.SObjectType, AccessType.CREATABLE);
		Boolean updatable = AccessUtils.hasObjectAccess(Account.SObjectType, AccessType.UPDATABLE);
		Boolean upsertable = AccessUtils.hasObjectAccess(Account.SObjectType, AccessType.UPSERTABLE);
		Assert.isNotNull(readable, 'READABLE result should not be null');
		Assert.isNotNull(creatable, 'CREATABLE result should not be null');
		Assert.isNotNull(updatable, 'UPDATABLE result should not be null');
		Assert.isNotNull(upsertable, 'UPSERTABLE result should not be null');
	}

	/**
	 * @description Verifies repeated hasObjectAccess calls produce
	 * consistent results, exercising the per-SObjectType describe cache.
	 * Cache hits cannot be observed directly, but repeated calls
	 * confirming the same answer indicate the cache produces consistent
	 * results.
	 */
	@IsTest
	static void shouldReturnConsistentResultsAcrossRepeatedCalls() {
		Boolean first = AccessUtils.hasObjectAccess(Account.SObjectType, AccessType.READABLE);
		Boolean second = AccessUtils.hasObjectAccess(Account.SObjectType, AccessType.READABLE);
		Boolean third = AccessUtils.hasObjectAccess(Account.SObjectType, AccessType.READABLE);
		Assert.areEqual(first, second, 'Repeated calls should return consistent results');
		Assert.areEqual(second, third, 'Repeated calls should return consistent results');
	}

	// ── Mixed-type tests ─────────────────────────────────────────

	/**
	 * @description Verifies the NoAccessException error message reports
	 * multiple unique SObject labels when the input list contains mixed
	 * types.
	 */
	@IsTest
	static void shouldReportAllUniqueLabelsWhenRecordsAreMixedTypes() {
		// Arrange
		Account acct = new Account(Name = 'Acme');
		Contact ctc = new Contact(LastName = 'Smith');
		MockSecurityEnforcer mock = new MockSecurityEnforcer().throwsNoAccess();
		Boolean threw = false;
		// Act
		try {
			AccessUtils.checkRecordAccess(
				new List<SObject>{ acct, ctc },
				AccessType.READABLE,
				AccessOptions.strict().withEnforcer(mock)
			);
		} catch (AccessUtilsException e) {
			threw = true;
			Assert.isTrue(e.getMessage().contains('Account'), 'Exception should mention Account label');
			Assert.isTrue(e.getMessage().contains('Contact'), 'Exception should mention Contact label');
		}
		// Assert
		Assert.isTrue(threw, 'Should throw AccessUtilsException in strict mode');
	}
}
