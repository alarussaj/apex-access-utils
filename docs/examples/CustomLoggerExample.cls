/**
 * Example: Implementing IAccessLogger to capture stripped fields.
 *
 * apex-access-utils does not ship a logger implementation — you provide
 * one that writes to wherever you already log. This example writes to a
 * fictional AccessLog__c custom object. Adapt the persistence to your own
 * logging target: a custom object, a Platform Event, or a third-party
 * logging framework such as Nebula Logger.
 *
 * The logger fires in both strict and silent modes whenever fields are
 * stripped or a NoAccessException is caught, so it gives you an audit
 * trail even in headless contexts (batch, queueable, scheduled, triggers).
 *
 * Note: This file is for documentation only and is excluded from package
 * deployment via .forceignore. AccessLog__c is fictional; replace it with
 * your own logging mechanism. Copy and adapt to your own codebase.
 *
 * @see https://github.com/alarussaj/apex-access-utils
 */
public inherited sharing class CustomLoggerExample implements IAccessLogger {
	/**
	 * Called by AccessUtils when fields are stripped or NoAccessException
	 * is caught. Persists one log record per object that had fields
	 * stripped. For a NoAccessException the map is empty, so a single
	 * summary record is written instead.
	 *
	 * @param removedFieldsByObject Map of object API name to set of stripped field API names.
	 * @param requestedAccess The AccessType being enforced when the event occurred.
	 */
	public void logStrippedFields(Map<String, Set<String>> removedFieldsByObject, AccessType requestedAccess) {
		List<AccessLog__c> logs = new List<AccessLog__c>();

		if (removedFieldsByObject == null || removedFieldsByObject.isEmpty()) {
			// No specific fields (e.g., NoAccessException). Write a summary row.
			logs.add(
				new AccessLog__c(
					AccessType__c = String.valueOf(requestedAccess),
					ObjectApiName__c = 'unknown',
					StrippedFields__c = 'No field detail (object-level access denied)',
					RunningUser__c = UserInfo.getUserId()
				)
			);
		} else {
			for (String objectApiName : removedFieldsByObject.keySet()) {
				logs.add(
					new AccessLog__c(
						AccessType__c = String.valueOf(requestedAccess),
						ObjectApiName__c = objectApiName,
						StrippedFields__c = String.join(
							new List<String>(removedFieldsByObject.get(objectApiName)),
							', '
						),
						RunningUser__c = UserInfo.getUserId()
					)
				);
			}
		}

		// Insert in system mode so logging succeeds regardless of the
		// running user's access to the log object itself. Adjust to your
		// org's logging conventions.
		if (!logs.isEmpty()) {
			Database.insert(logs, false, AccessLevel.SYSTEM_MODE);
		}
	}
}
