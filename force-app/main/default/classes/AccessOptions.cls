/**
 * @description Per-call options for AccessUtils. Default is strict (throws
 * on stripped fields or no access). Use silent() to suppress the
 * exception and return stripped records. An optional IAccessLogger fires
 * whenever fields are stripped or NoAccessException is caught, regardless
 * of mode.
 *
 * The enforcer is overridable for testing and for custom wrappers;
 * production callers should leave it unset to get the default
 * Security.stripInaccessible behavior.
 *
 * Example usage:
 * <pre>
 * // Production
 * AccessUtils.checkRecordAccess(records, AccessType.UPDATABLE);
 *
 * // Silent mode with a logger
 * AccessUtils.checkRecordAccess(records, AccessType.UPDATABLE,
 *     AccessOptions.silent().withLogger(new MyLogger()));
 *
 * // Tests
 * AccessUtils.checkRecordAccess(records, AccessType.UPDATABLE,
 *     AccessOptions.strict().withEnforcer(mockEnforcer));
 * </pre>
 *
 * @group AccessUtils
 * @see https://github.com/alarussaj/apex-access-utils
 */
public inherited sharing class AccessOptions {
	/**
	 * @description Behavior mode controlling whether AccessUtils throws on
	 * stripped fields or returns the stripped records silently.
	 */
	public enum Mode {
		STRICT,
		SILENT
	}

	/**
	 * @description The behavior mode for this options instance.
	 */
	public Mode mode { get; private set; }

	/**
	 * @description Optional logger for observability. Fires in both strict
	 * and silent modes whenever fields are stripped or NoAccessException
	 * is caught.
	 */
	public IAccessLogger logger { get; private set; }

	/**
	 * @description Optional security enforcer override. Defaults to
	 * DefaultSecurityEnforcer when left unset. Tests substitute
	 * MockSecurityEnforcer; custom implementations can wrap the default
	 * with caching, logging, or other cross-cutting concerns.
	 */
	public ISecurityEnforcer enforcer { get; private set; }

	/**
	 * @description Private constructor enforcing creation via the
	 * strict() and silent() factory methods.
	 * @param mode The behavior mode.
	 */
	private AccessOptions(Mode mode) {
		this.mode = mode;
	}

	/**
	 * @description Creates an options instance in strict mode, which causes
	 * AccessUtils to throw AccessUtilsException when fields are stripped
	 * or the user has no access.
	 * @return A new AccessOptions configured in strict mode.
	 */
	public static AccessOptions strict() {
		return new AccessOptions(Mode.STRICT);
	}

	/**
	 * @description Creates an options instance in silent mode, which causes
	 * AccessUtils to suppress AccessUtilsException and return the stripped
	 * records (or an empty list for NoAccessException) instead.
	 * @return A new AccessOptions configured in silent mode.
	 */
	public static AccessOptions silent() {
		return new AccessOptions(Mode.SILENT);
	}

	/**
	 * @description Attaches an observability logger that fires whenever
	 * fields are stripped or NoAccessException is caught.
	 * @param logger The IAccessLogger implementation to attach.
	 * @return This AccessOptions, for chaining.
	 */
	public AccessOptions withLogger(IAccessLogger logger) {
		this.logger = logger;
		return this;
	}

	/**
	 * @description Substitutes a custom ISecurityEnforcer. Used primarily
	 * by tests to inject a MockSecurityEnforcer.
	 * @param enforcer The ISecurityEnforcer implementation to use.
	 * @return This AccessOptions, for chaining.
	 */
	public AccessOptions withEnforcer(ISecurityEnforcer enforcer) {
		this.enforcer = enforcer;
		return this;
	}
}
