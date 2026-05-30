/**
 * Example: Wrapping DefaultSecurityEnforcer with cross-cutting behavior.
 *
 * The ISecurityEnforcer seam isn't only for testing. In production you can
 * supply a custom enforcer that wraps the default to add behavior such as
 * unconditional logging of every check, feature-flag short-circuiting, or
 * metrics. This example wraps DefaultSecurityEnforcer to emit a debug log
 * on every call and to count invocations for lightweight instrumentation.
 *
 * Pass it via AccessOptions.withEnforcer():
 *
 *   AuditingSecurityEnforcer enforcer = new AuditingSecurityEnforcer();
 *   AccessUtils.checkRecordAccess(records, AccessType.UPDATABLE,
 *       AccessOptions.strict().withEnforcer(enforcer));
 *
 * Note: This file is for documentation only and is excluded from package
 * deployment via .forceignore. Copy and adapt to your own codebase.
 *
 * @see https://github.com/alarussaj/apex-access-utils
 */
public inherited sharing class CustomEnforcerExample implements ISecurityEnforcer {
	private final ISecurityEnforcer delegate;

	/**
	 * @description Running count of how many times this enforcer has been
	 * invoked in the current transaction. Useful for lightweight metrics.
	 */
	public Integer invocationCount = 0;

	/**
	 * Default constructor wraps the standard DefaultSecurityEnforcer.
	 */
	public CustomEnforcerExample() {
		this.delegate = new DefaultSecurityEnforcer();
	}

	/**
	 * Constructor allowing an arbitrary inner enforcer to be wrapped, so
	 * this auditing behavior can be layered over any enforcer.
	 *
	 * @param delegate The inner ISecurityEnforcer to delegate to.
	 */
	public CustomEnforcerExample(ISecurityEnforcer delegate) {
		this.delegate = delegate;
	}

	/**
	 * Increments the invocation counter, emits a debug log, then delegates
	 * to the wrapped enforcer. Demonstrates adding cross-cutting behavior
	 * without modifying AccessUtils itself.
	 *
	 * @param requestedAccess The AccessType being enforced.
	 * @param records The records to enforce access on.
	 * @return The AccessDecision produced by the wrapped enforcer.
	 */
	public AccessDecision stripInaccessible(AccessType requestedAccess, List<SObject> records) {
		invocationCount++;
		System.debug(
			LoggingLevel.INFO,
			'Security check #' +
				invocationCount +
				' — access=' +
				requestedAccess +
				', recordCount=' +
				(records == null ? 0 : records.size())
		);
		return delegate.stripInaccessible(requestedAccess, records);
	}
}
