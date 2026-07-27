/**
 * @description Test-only IAccessLogger that captures invocations for
 * verification in tests, without writing to any backing store.
 *
 * Supports both assert-style verification (verifyXxx methods that throw)
 * and direct inspection of public capture fields for custom assertions.
 *
 * Example usage:
 * <pre>
 * MockAccessLogger logger = new MockAccessLogger();
 * AccessUtils.checkRecordAccess(records, AccessType.READABLE,
 *     AccessOptions.silent().withLogger(logger));
 *
 * logger.verifyCalledOnce();
 * logger.verifyLoggedFieldOn('Contact', 'Email');
 * </pre>
 *
 * @group AccessUtils
 * @see https://github.com/alarussaj/apex-access-utils
 */
@IsTest
public class MockAccessLogger implements IAccessLogger {
	/**
	 * @description Number of times logStrippedFields was called on this mock.
	 */
	public Integer callCount = 0;

	/**
	 * @description Removed-fields maps captured from each call, in order.
	 */
	public List<Map<String, Set<String>>> capturedRemovedFields = new List<Map<String, Set<String>>>();

	/**
	 * @description AccessType arguments captured from each call, in order.
	 */
	public List<AccessType> capturedAccessTypes = new List<AccessType>();

	/**
	 * @description The mocked logStrippedFields implementation. Captures
	 * the call arguments without performing any logging.
	 * @param removedFieldsByObject Map of object API name to set of
	 * stripped field API names.
	 * @param requestedAccess The AccessType being enforced.
	 */
	public void logStrippedFields(Map<String, Set<String>> removedFieldsByObject, AccessType requestedAccess) {
		callCount++;
		capturedRemovedFields.add(removedFieldsByObject);
		capturedAccessTypes.add(requestedAccess);
	}

	/**
	 * @description Asserts the logger was called at least once.
	 */
	public void verifyCalled() {
		Assert.isTrue(callCount > 0, 'Expected logStrippedFields to be called at least once');
	}

	/**
	 * @description Asserts the logger was called exactly once.
	 */
	public void verifyCalledOnce() {
		Assert.areEqual(1, callCount, 'Expected logStrippedFields to be called exactly once, was called ' + callCount);
	}

	/**
	 * @description Asserts the logger was never called.
	 */
	public void verifyNeverCalled() {
		Assert.areEqual(0, callCount, 'Expected logStrippedFields to never be called, was called ' + callCount);
	}

	/**
	 * @description Asserts the logger was called with the given AccessType
	 * at least once.
	 * @param expected The AccessType expected to have been passed.
	 */
	public void verifyCalledWith(AccessType expected) {
		Assert.isTrue(
			capturedAccessTypes.contains(expected),
			'Expected logger call with AccessType ' + expected + ', captured: ' + capturedAccessTypes
		);
	}

	/**
	 * @description Asserts at least one call recorded the given field as
	 * stripped from the given object.
	 * @param objectApiName The object API name to look for.
	 * @param fieldApiName The field API name to look for.
	 */
	public void verifyLoggedFieldOn(String objectApiName, String fieldApiName) {
		Boolean found = false;
		for (Map<String, Set<String>> removed : capturedRemovedFields) {
			Set<String> fields = removed.get(objectApiName);
			if (fields != null && fields.contains(fieldApiName)) {
				found = true;
				break;
			}
		}
		Assert.isTrue(found, 'Expected logger to have recorded ' + objectApiName + '.' + fieldApiName + ' as stripped');
	}
}
