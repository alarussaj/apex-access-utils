/**
 * @description Utility for enforcing object and field-level security using
 * Security.stripInaccessible, with consistent error messaging and an
 * injectable logger for observability.
 *
 * Default behavior is strict: throws AccessUtilsException when any field
 * is stripped or when the user has no access to the object at all. Use
 * AccessOptions.silent() to suppress the exception and return the
 * stripped records instead.
 *
 * An optional IAccessLogger fires whenever fields are stripped or
 * NoAccessException is caught, in both strict and silent modes, for
 * audit and debugging in contexts without UI.
 *
 * Describe results are cached per-transaction by SObject API name to
 * avoid the cost of repeated getDescribe() calls (and to bypass
 * Schema.getGlobalDescribe() entirely, which is expensive).
 *
 * @group AccessUtils
 * @see https://github.com/alarussaj/apex-access-utils
 */
public inherited sharing class AccessUtils {
	private static final Map<AccessType, String> ACCESS_TYPE_LABELS = new Map<AccessType, String>{
		AccessType.CREATABLE => 'insert',
		AccessType.READABLE => 'read',
		AccessType.UPDATABLE => 'update',
		AccessType.UPSERTABLE => 'upsert'
	};

	/**
	 * @description Per-transaction cache of describes keyed by SObject
	 * API name. Lazy-initialized on first access. Cached null values
	 * represent confirmed misses to avoid retrying Type.forName lookups
	 * for invalid names.
	 */
	private static Map<String, DescribeSObjectResult> describesByApiName {
		get {
			if (describesByApiName == null) {
				describesByApiName = new Map<String, DescribeSObjectResult>();
			}
			return describesByApiName;
		}
		set;
	}

	/**
	 * @description Checks access for a single record using default options (strict mode).
	 * @param record The SObject to check; may be null.
	 * @param requestedAccess The AccessType to enforce.
	 * @return The record with inaccessible fields stripped, or null if the input was null.
	 * @throws AccessUtilsException in strict mode when fields are stripped
	 * or when the user has no access to the object.
	 */
	public static SObject checkRecordAccess(SObject record, AccessType requestedAccess) {
		return checkRecordAccess(record, requestedAccess, AccessOptions.strict());
	}

	/**
	 * @description Checks access for a single record using caller-supplied options.
	 * @param record The SObject to check; may be null.
	 * @param requestedAccess The AccessType to enforce.
	 * @param options Behavior options (strict vs silent, optional logger, optional enforcer).
	 * @return The record with inaccessible fields stripped, or null if the input was null or empty.
	 * @throws AccessUtilsException in strict mode when fields are stripped
	 * or when the user has no access to the object.
	 */
	public static SObject checkRecordAccess(SObject record, AccessType requestedAccess, AccessOptions options) {
		if (record == null) {
			return null;
		}
		List<SObject> result = checkRecordAccess(new List<SObject>{ record }, requestedAccess, options);
		return result.isEmpty() ? null : result.get(0);
	}

	/**
	 * @description Checks access for a list of records using default options (strict mode).
	 * Supports mixed SObject types in the same list. Null entries are filtered out.
	 * @param records The records to check; may be null or empty.
	 * @param requestedAccess The AccessType to enforce.
	 * @return The records with inaccessible fields stripped, or an empty list if input was null/empty.
	 * @throws AccessUtilsException in strict mode when fields are stripped
	 * or when the user has no access to the object.
	 */
	public static List<SObject> checkRecordAccess(List<SObject> records, AccessType requestedAccess) {
		return checkRecordAccess(records, requestedAccess, AccessOptions.strict());
	}

	/**
	 * @description Checks access for a list of records using caller-supplied options.
	 * Supports mixed SObject types in the same list. Null entries are filtered out.
	 * @param records The records to check; may contain multiple SObject types or nulls.
	 * @param requestedAccess The AccessType to enforce.
	 * @param options Behavior options (strict vs silent, optional logger, optional enforcer).
	 * @return The records with inaccessible fields stripped.
	 * @throws AccessUtilsException in strict mode when fields are stripped
	 * or when the user has no access to the object.
	 */
	public static List<SObject> checkRecordAccess(
		List<SObject> records,
		AccessType requestedAccess,
		AccessOptions options
	) {
		if (records == null || records.isEmpty()) {
			return new List<SObject>();
		}

		List<SObject> nonNullRecords = new List<SObject>();
		for (SObject record : records) {
			if (record != null) {
				nonNullRecords.add(record);
			}
		}
		if (nonNullRecords.isEmpty()) {
			return new List<SObject>();
		}

		if (options == null) {
			options = AccessOptions.strict();
		}

		ISecurityEnforcer enforcer = options.enforcer != null ? options.enforcer : new DefaultSecurityEnforcer();

		try {
			AccessDecision decision = enforcer.stripInaccessible(requestedAccess, nonNullRecords);

			if (decision.hasRemovedFields()) {
				if (options.logger != null) {
					options.logger.logStrippedFields(decision.getRemovedFields(), requestedAccess);
				}
				if (options.mode == AccessOptions.Mode.STRICT) {
					throw new AccessUtilsException(
						buildFieldErrorMessage(decision.getRemovedFields(), requestedAccess)
					);
				}
			}

			return decision.getRecords();
		} catch (NoAccessException e) {
			String objectLabel = inferObjectLabel(nonNullRecords);
			String message = String.format(
				System.Label.AccessUtils_InsufficientObjectAccess,
				new List<String>{ ACCESS_TYPE_LABELS.get(requestedAccess), objectLabel, e.getMessage() }
			);
			if (options.logger != null) {
				options.logger.logStrippedFields(new Map<String, Set<String>>(), requestedAccess);
			}
			if (options.mode == AccessOptions.Mode.STRICT) {
				throw new AccessUtilsException(message);
			}
			return new List<SObject>();
		}
	}

	/**
	 * @description Pre-flight object-level access check. Useful before
	 * constructing a query, when stripInaccessible's post-hoc approach
	 * is too late.
	 * @param objectType The SObjectType to check; may be null.
	 * @param requestedAccess The AccessType to evaluate.
	 * @return True if the running user has the requested access on the object, false otherwise.
	 */
	public static Boolean hasObjectAccess(SObjectType objectType, AccessType requestedAccess) {
		if (objectType == null) {
			return false;
		}
		DescribeSObjectResult describe = getDescribeByType(objectType);
		if (describe == null) {
			return false;
		}
		switch on requestedAccess {
			when CREATABLE {
				return describe.isCreateable();
			}
			when READABLE {
				return describe.isAccessible();
			}
			when UPDATABLE {
				return describe.isUpdateable();
			}
			when UPSERTABLE {
				return describe.isCreateable() && describe.isUpdateable();
			}
			when else {
				return false;
			}
		}
	}

	/**
	 * @description Returns the DescribeSObjectResult for an SObject by API
	 * name. Results are cached per-transaction. Returns null if the API
	 * name does not correspond to a known SObject type.
	 * @param sObjectApiName The API name of the SObject.
	 * @return The DescribeSObjectResult, or null if the type is unknown.
	 */
	private static DescribeSObjectResult getDescribeByApiName(String sObjectApiName) {
		if (String.isBlank(sObjectApiName)) {
			return null;
		}
		if (!describesByApiName.containsKey(sObjectApiName)) {
			Type sObjectClass = Type.forName(sObjectApiName);
			if (sObjectClass == null) {
				describesByApiName.put(sObjectApiName, null);
			} else {
				describesByApiName.put(
					sObjectApiName,
					((SObject) sObjectClass.newInstance()).getSObjectType().getDescribe()
				);
			}
		}
		return describesByApiName.get(sObjectApiName);
	}

	/**
	 * @description Returns the DescribeSObjectResult for an SObject by
	 * SObjectType token. Routes through the API-name cache to avoid
	 * duplicate describes for the same type.
	 * @param objectType The SObjectType token.
	 * @return The DescribeSObjectResult, or null if the type is null.
	 */
	private static DescribeSObjectResult getDescribeByType(SObjectType objectType) {
		if (objectType == null) {
			return null;
		}
		return getDescribeByApiName(String.valueOf(objectType));
	}

	/**
	 * @description Builds the field-level access error message by formatting the
	 * AccessUtils_InsufficientFieldAccess custom label with the access verb,
	 * object label, and comma-separated list of stripped fields.
	 * @param removed Map of object API name to set of stripped field API names.
	 * @param requestedAccess The AccessType being enforced.
	 * @return Formatted error message string.
	 */
	private static String buildFieldErrorMessage(Map<String, Set<String>> removed, AccessType requestedAccess) {
		List<String> errors = new List<String>();
		for (String objectApiName : removed.keySet()) {
			errors.add(
				String.format(
					System.Label.AccessUtils_InsufficientFieldAccess,
					new List<String>{
						ACCESS_TYPE_LABELS.get(requestedAccess),
						getObjectLabel(objectApiName),
						String.join(new List<String>(removed.get(objectApiName)), ', ')
					}
				)
			);
		}
		return String.join(errors, '\n');
	}

	/**
	 * @description Resolves the user-facing label for an SObject by its API name.
	 * Falls back to the API name if the type is not found.
	 * @param objectApiName The API name of the SObject.
	 * @return The object's label, or the API name if the type is not found.
	 */
	private static String getObjectLabel(String objectApiName) {
		DescribeSObjectResult describe = getDescribeByApiName(objectApiName);
		return describe == null ? objectApiName : describe.getLabel();
	}

	/**
	 * @description Builds a human-readable label describing the SObject type(s)
	 * in the given record list. For mixed-type lists, returns a comma-separated
	 * list of unique labels. Used in NoAccessException error messages so the
	 * caller knows which object the user lacked access to.
	 * @param records The records being checked; may contain multiple SObject types.
	 * @return A comma-separated list of unique SObject labels, or 'unknown' if the
	 * list is empty or types cannot be determined.
	 */
	private static String inferObjectLabel(List<SObject> records) {
		if (records == null || records.isEmpty()) {
			return 'unknown';
		}
		Set<String> uniqueLabels = new Set<String>();
		for (SObject record : records) {
			Schema.SObjectType objectType = record.getSObjectType();
			if (objectType != null) {
				DescribeSObjectResult describe = getDescribeByType(objectType);
				if (describe != null) {
					uniqueLabels.add(describe.getLabel());
				}
			}
		}
		if (uniqueLabels.isEmpty()) {
			return 'unknown';
		}
		return String.join(new List<String>(uniqueLabels), ', ');
	}
}
