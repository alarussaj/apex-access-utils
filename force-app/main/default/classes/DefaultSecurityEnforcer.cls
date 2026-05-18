/**
 * @description Default ISecurityEnforcer implementation. Delegates to the
 * platform's Security.stripInaccessible and wraps the result in an
 * AccessDecision.
 *
 * Production callers of AccessUtils get this enforcer automatically when
 * no override is supplied via AccessOptions.withEnforcer().
 *
 * @group AccessUtils
 * @see https://github.com/alarussaj/apex-access-utils
 */
public inherited sharing class DefaultSecurityEnforcer implements ISecurityEnforcer {
	/**
	 * @description Delegates to Security.stripInaccessible and wraps the
	 * platform's SObjectAccessDecision in an AccessDecision so callers
	 * receive a consistent return type across the default and mocked
	 * enforcers.
	 * @param requestedAccess The AccessType being enforced.
	 * @param records The records to enforce access on.
	 * @return An AccessDecision wrapping the platform's result.
	 */
	public AccessDecision stripInaccessible(AccessType requestedAccess, List<SObject> records) {
		SObjectAccessDecision decision = Security.stripInaccessible(requestedAccess, records);
		return AccessDecision.wrap(decision);
	}
}
