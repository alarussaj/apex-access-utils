/**
 * Example: Silent-mode enforcement in a batch / integration context.
 *
 * When syncing data from an external system or processing records in
 * bulk, you often want to continue past records or fields the running
 * user can't access, rather than aborting the whole job with an
 * exception. Silent mode returns the stripped records so processing
 * continues, while an attached logger captures what was stripped for
 * later audit.
 *
 * Note: This file is for documentation only and is excluded from package
 * deployment via .forceignore. Copy and adapt to your own service classes.
 *
 * @see https://github.com/alarussaj/apex-access-utils
 */
public inherited sharing class SilentSyncExample implements Database.Batchable<SObject> {
	private final String newSegment;
	private final IAccessLogger logger;

	/**
	 * @param newSegment The segment value to apply to each Account.
	 * @param logger An IAccessLogger to capture any stripped fields during the run.
	 */
	public SilentSyncExample(String newSegment, IAccessLogger logger) {
		this.newSegment = newSegment;
		this.logger = logger;
	}

	/**
	 * Selects the Accounts to process.
	 *
	 * @param context The batch context.
	 * @return A query locator over the Accounts to sync.
	 */
	public Database.QueryLocator start(Database.BatchableContext context) {
		return Database.getQueryLocator([SELECT Id, Description FROM Account]);
	}

	/**
	 * Applies the segment to each Account, enforcing field access in silent
	 * mode so the batch continues even if some fields are stripped. The
	 * logger records anything that was stripped.
	 *
	 * @param context The batch context.
	 * @param scope The current batch of Accounts.
	 */
	public void execute(Database.BatchableContext context, List<Account> scope) {
		for (Account acct : scope) {
			acct.Description = newSegment;
		}

		// Silent mode: returns stripped records instead of throwing.
		// The logger fires if any field was stripped, giving an audit trail
		// without aborting the batch.
		List<SObject> safe = AccessUtils.checkRecordAccess(
			scope,
			AccessType.UPDATABLE,
			AccessOptions.silent().withLogger(logger)
		);

		if (!safe.isEmpty()) {
			Database.update(safe, false, AccessLevel.USER_MODE);
		}
	}

	/**
	 * No-op finish. Hook for post-processing or notifications.
	 *
	 * @param context The batch context.
	 */
	public void finish(Database.BatchableContext context) {
		// Intentionally empty — add notifications or chaining here if needed.
	}
}
