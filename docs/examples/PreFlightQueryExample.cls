/**
 * Example: Pre-flight object access check before building a query.
 *
 * Security.stripInaccessible (and thus AccessUtils.checkRecordAccess)
 * operates on records you've already queried — it's a post-hoc filter.
 * Sometimes you need to know up front whether the user can even read or
 * create an object, so you can branch logic or fail fast before spending
 * a query or attempting DML. hasObjectAccess covers that case.
 *
 * Note: This file is for documentation only and is excluded from package
 * deployment via .forceignore. Copy and adapt to your own service classes.
 *
 * @see https://github.com/alarussaj/apex-access-utils
 */
public inherited sharing class PreFlightQueryExample {
	/**
	 * Returns recent Accounts only if the running user can read the object.
	 * Avoids spending a query (and avoids a confusing empty result) when
	 * the user has no read access at all.
	 *
	 * @return A list of Accounts, or an empty list if the user lacks read access.
	 */
	public static List<Account> getRecentAccountsIfAllowed() {
		if (!AccessUtils.hasObjectAccess(Account.SObjectType, AccessType.READABLE)) {
			// User can't read Accounts — return empty rather than querying.
			return new List<Account>();
		}

		return [SELECT Id, Name FROM Account ORDER BY CreatedDate DESC LIMIT 10];
	}

	/**
	 * Guards a create operation. Throws a domain-specific exception up front
	 * if the user can't create the object, instead of letting the DML fail
	 * with a less friendly platform error deeper in the call stack.
	 *
	 * @param name The name for the new Account.
	 * @return The Id of the created Account.
	 */
	public static Id createAccountIfAllowed(String name) {
		if (!AccessUtils.hasObjectAccess(Account.SObjectType, AccessType.CREATABLE)) {
			throw new AccessUtilsException('You do not have permission to create Accounts.');
		}

		Account acct = new Account(Name = name);
		insert acct;
		return acct.Id;
	}

	/**
	 * Demonstrates an upsert pre-check, which requires both create and
	 * update access.
	 *
	 * @return True if the user can upsert Accounts, false otherwise.
	 */
	public static Boolean canUpsertAccounts() {
		return AccessUtils.hasObjectAccess(Account.SObjectType, AccessType.UPSERTABLE);
	}
}
