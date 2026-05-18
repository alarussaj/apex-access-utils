/**
 * @description Optional observability hook. Implementations are invoked
 * by AccessUtils whenever fields are stripped or NoAccessException is
 * caught, in both strict and silent modes. Use to capture audit trails
 * in contexts without UI (batch, queueable, triggers, scheduled jobs).
 *
 * AccessUtils does not include a default logger implementation;
 * consumers wire in their own logging infrastructure (custom object,
 * Platform Event, third-party logger, etc.) by implementing this
 * interface.
 *
 * @group AccessUtils
 * @see https://github.com/alarussaj/apex-access-utils
 */
public interface IAccessLogger {
	/**
	 * @description Called by AccessUtils when fields are stripped or
	 * NoAccessException is caught. For NoAccessException, the
	 * removedFieldsByObject map will be empty since the platform did not
	 * report individual stripped fields.
	 * @param removedFieldsByObject Map of object API name to set of
	 * stripped field API names; empty for NoAccessException cases.
	 * @param requestedAccess The AccessType being enforced when the strip
	 * or no-access event occurred.
	 */
	void logStrippedFields(Map<String, Set<String>> removedFieldsByObject, AccessType requestedAccess);
}
