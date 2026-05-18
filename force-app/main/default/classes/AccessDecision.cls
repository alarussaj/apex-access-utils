/**
 * @description Wrapper over Salesforce's SObjectAccessDecision. Exists so
 * that ISecurityEnforcer implementations (including mocks) can return a
 * result that callers can inspect, without being constrained by the fact
 * that SObjectAccessDecision has no public constructor.
 *
 * The default enforcer wraps a real SObjectAccessDecision via wrap();
 * the mock enforcer constructs one directly from configured records and
 * removed-fields data via the public constructor.
 *
 * @group AccessUtils
 * @see https://github.com/alarussaj/apex-access-utils
 */
public inherited sharing class AccessDecision {
	private List<SObject> records;
	private Map<String, Set<String>> removedFields;

	/**
	 * @description Constructs an AccessDecision from raw values. Used by
	 * mocks (constructing arbitrary decisions) and by the default
	 * enforcer's wrap() factory.
	 * @param records The records remaining after stripping; null is
	 * treated as an empty list.
	 * @param removedFields Map of object API name to set of stripped
	 * field API names; null is treated as an empty map.
	 */
	public AccessDecision(List<SObject> records, Map<String, Set<String>> removedFields) {
		this.records = records == null ? new List<SObject>() : records;
		this.removedFields = removedFields == null ? new Map<String, Set<String>>() : removedFields;
	}

	/**
	 * @description Constructs an AccessDecision by wrapping a real
	 * SObjectAccessDecision returned by Security.stripInaccessible.
	 * @param decision The platform's SObjectAccessDecision; null is
	 * treated as an empty decision.
	 * @return A new AccessDecision wrapping the platform's data.
	 */
	public static AccessDecision wrap(SObjectAccessDecision decision) {
		if (decision == null) {
			return new AccessDecision(new List<SObject>(), new Map<String, Set<String>>());
		}
		return new AccessDecision(decision.getRecords(), decision.getRemovedFields());
	}

	/**
	 * @description Returns the records remaining after stripping inaccessible fields.
	 * @return The list of records, never null.
	 */
	public List<SObject> getRecords() {
		return records;
	}

	/**
	 * @description Returns a map of object API name to set of stripped
	 * field API names.
	 * @return The removed-fields map, never null.
	 */
	public Map<String, Set<String>> getRemovedFields() {
		return removedFields;
	}

	/**
	 * @description Indicates whether any fields were stripped from any object.
	 * @return True if at least one field was stripped, false otherwise.
	 */
	public Boolean hasRemovedFields() {
		return removedFields != null && !removedFields.isEmpty();
	}
}
