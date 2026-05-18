/**
 * @description Test-only ISecurityEnforcer that lets tests configure what
 * stripInaccessible returns and verify how it was called, without
 * needing restrictive user profiles.
 *
 * Supports both assert-style verification (verifyXxx methods that throw)
 * and direct inspection of public capture fields for custom assertions.
 *
 * Example usage:
 * <pre>
 * MockSecurityEnforcer mock = new MockSecurityEnforcer()
 *     .withRemovedFields(new Map<String, Set<String>>{
 *         'Contact' => new Set<String>{ 'Email' }
 *     });
 *
 * AccessUtils.checkRecordAccess(records, AccessType.UPDATABLE,
 *     AccessOptions.strict().withEnforcer(mock));
 *
 * mock.verifyCalledOnce();
 * mock.verifyCalledWith(AccessType.UPDATABLE);
 *
 * // or inspect directly
 * Assert.areEqual(1, mock.callCount);
 * Assert.areEqual(records.size(), mock.capturedRecords[0].size());
 * </pre>
 *
 * @group AccessUtils
 * @see https://github.com/alarussaj/apex-access-utils
 */
@IsTest
public class MockSecurityEnforcer implements ISecurityEnforcer {
	private Map<String, Set<String>> removedFieldsToReturn;
	private List<SObject> recordsToReturn;
	private Boolean shouldThrowNoAccess = false;
	private String noAccessMessage = 'Mock: no access';

	/**
	 * @description Number of times stripInaccessible was called on this mock.
	 */
	public Integer callCount = 0;

	/**
	 * @description AccessType arguments captured from each call, in order.
	 */
	public List<AccessType> capturedAccessTypes = new List<AccessType>();

	/**
	 * @description Record-list arguments captured from each call, in order.
	 */
	public List<List<SObject>> capturedRecords = new List<List<SObject>>();

	/**
	 * @description Configures the mock to return the given removed-fields
	 * map on its next call.
	 * @param removed Map of object API name to set of stripped field API names.
	 * @return This MockSecurityEnforcer, for chaining.
	 */
	public MockSecurityEnforcer withRemovedFields(Map<String, Set<String>> removed) {
		this.removedFieldsToReturn = removed;
		return this;
	}

	/**
	 * @description Configures the mock to return the given records instead
	 * of echoing back the input.
	 * @param records The records to return from stripInaccessible.
	 * @return This MockSecurityEnforcer, for chaining.
	 */
	public MockSecurityEnforcer returnsRecords(List<SObject> records) {
		this.recordsToReturn = records;
		return this;
	}

	/**
	 * @description Configures the mock to throw NoAccessException with a
	 * default message on its next call.
	 * @return This MockSecurityEnforcer, for chaining.
	 */
	public MockSecurityEnforcer throwsNoAccess() {
		this.shouldThrowNoAccess = true;
		return this;
	}

	/**
	 * @description Configures the mock to throw NoAccessException with the
	 * given message on its next call.
	 * @param message The exception message to use.
	 * @return This MockSecurityEnforcer, for chaining.
	 */
	public MockSecurityEnforcer throwsNoAccess(String message) {
		this.shouldThrowNoAccess = true;
		this.noAccessMessage = message;
		return this;
	}

	/**
	 * @description The mocked stripInaccessible implementation. Captures
	 * the call arguments, then returns the configured response (or throws
	 * NoAccessException if configured to do so).
	 * @param requestedAccess The AccessType being enforced.
	 * @param records The records to enforce access on.
	 * @return An AccessDecision built from the mock's configured response.
	 */
	public AccessDecision stripInaccessible(AccessType requestedAccess, List<SObject> records) {
		callCount++;
		capturedAccessTypes.add(requestedAccess);
		capturedRecords.add(records);

		if (shouldThrowNoAccess) {
			NoAccessException e = new NoAccessException();
			e.setMessage(noAccessMessage);
			throw e;
		}

		List<SObject> recsOut = recordsToReturn != null ? recordsToReturn : records;
		Map<String, Set<String>> removedOut = removedFieldsToReturn != null
			? removedFieldsToReturn
			: new Map<String, Set<String>>();

		return new AccessDecision(recsOut, removedOut);
	}

	/**
	 * @description Asserts the mock was called at least once.
	 */
	public void verifyCalled() {
		Assert.isTrue(callCount > 0, 'Expected stripInaccessible to be called at least once');
	}

	/**
	 * @description Asserts the mock was called exactly once.
	 */
	public void verifyCalledOnce() {
		Assert.areEqual(
			1,
			callCount,
			'Expected stripInaccessible to be called exactly once, was called ' + callCount
		);
	}

	/**
	 * @description Asserts the mock was called the expected number of times.
	 * @param expected The expected call count.
	 */
	public void verifyCalledTimes(Integer expected) {
		Assert.areEqual(
			expected,
			callCount,
			'Expected stripInaccessible to be called ' + expected + ' times, was called ' + callCount
		);
	}

	/**
	 * @description Asserts the mock was never called.
	 */
	public void verifyNeverCalled() {
		Assert.areEqual(0, callCount, 'Expected stripInaccessible to never be called, was called ' + callCount);
	}

	/**
	 * @description Asserts the mock was called with the given AccessType
	 * at least once.
	 * @param expected The AccessType expected to have been passed.
	 */
	public void verifyCalledWith(AccessType expected) {
		Assert.isTrue(
			capturedAccessTypes.contains(expected),
			'Expected call with AccessType ' + expected + ', captured: ' + capturedAccessTypes
		);
	}

	/**
	 * @description Asserts the last call passed the given number of records.
	 * @param expected The expected record count in the most recent call.
	 */
	public void verifyLastCallRecordCount(Integer expected) {
		Assert.isTrue(callCount > 0, 'Cannot verify last call — mock was never called');
		Integer actual = capturedRecords[capturedRecords.size() - 1].size();
		Assert.areEqual(expected, actual, 'Expected last call to have ' + expected + ' records, had ' + actual);
	}
}
