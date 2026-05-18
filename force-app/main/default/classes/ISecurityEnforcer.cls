/**
 * @description Seam over Security.stripInaccessible. The default
 * implementation (DefaultSecurityEnforcer) calls the platform method;
 * tests substitute MockSecurityEnforcer. Custom implementations can
 * also wrap the default with caching, logging, or other cross-cutting
 * concerns.
 *
 * Returns AccessDecision (a wrapper) rather than SObjectAccessDecision
 * so that mocks can construct return values directly, since
 * SObjectAccessDecision has no public constructor.
 *
 * @group AccessUtils
 * @see https://github.com/alarussaj/apex-access-utils
 */
public interface ISecurityEnforcer {
	/**
	 * @description Enforces field-level security on the given records,
	 * returning an AccessDecision describing what was stripped.
	 * @param requestedAccess The AccessType being enforced.
	 * @param records The records to enforce access on.
	 * @return An AccessDecision wrapping the stripped records and the
	 * removed-fields metadata.
	 */
	AccessDecision stripInaccessible(AccessType requestedAccess, List<SObject> records);
}
