/**
 * Example: Strict-mode field access enforcement before an update.
 *
 * This is the 80% case for AccessUtils. Before performing DML, enforce
 * that the running user can actually write every field being touched.
 * In strict mode (the default), AccessUtils throws AccessUtilsException
 * the moment any field is stripped, so the problem surfaces loudly
 * instead of silently writing partial data.
 *
 * Note: This file is for documentation only and is excluded from package
 * deployment via .forceignore. Copy and adapt to your own service classes.
 *
 * @see https://github.com/alarussaj/apex-access-utils
 */
public inherited sharing class StrictUpdateExample {
	/**
	 * Updates the Industry on a set of Accounts, but only after confirming
	 * the running user has update access to every field involved. If the
	 * user lacks access to any field, AccessUtilsException is thrown before
	 * any DML runs.
	 *
	 * @param accountIds The Ids of Accounts to update.
	 * @param newIndustry The new industry value.
	 */
	public static void updateIndustry(Set<Id> accountIds, String newIndustry) {
		List<Account> accounts = [SELECT Id, Industry FROM Account WHERE Id IN :accountIds];

		for (Account acct : accounts) {
			acct.Industry = newIndustry;
		}

		// Strict mode: throws AccessUtilsException if the user can't update
		// any of the populated fields. The returned list has inaccessible
		// fields stripped (irrelevant here since we throw on strip).
		List<SObject> safe = AccessUtils.checkRecordAccess(accounts, AccessType.UPDATABLE);

		update safe;
	}

	/**
	 * Single-record variant. Returns the access-checked record, or null if
	 * the input was null.
	 *
	 * @param accountId The Id of the Account to update.
	 * @param newIndustry The new industry value.
	 */
	public static void updateSingleAccount(Id accountId, String newIndustry) {
		Account acct = [SELECT Id, Industry FROM Account WHERE Id = :accountId LIMIT 1];
		acct.Industry = newIndustry;

		SObject safe = AccessUtils.checkRecordAccess(acct, AccessType.UPDATABLE);

		if (safe != null) {
			update safe;
		}
	}
}
