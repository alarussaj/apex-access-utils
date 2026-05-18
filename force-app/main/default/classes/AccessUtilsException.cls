/**
 * @description Exception thrown by AccessUtils in strict mode when fields
 * are stripped by Security.stripInaccessible, or when the user has no
 * access to the SObject being checked.
 *
 * In silent mode, this exception is not thrown; AccessUtils returns the
 * stripped records (or an empty list for NoAccessException) instead.
 *
 * @group AccessUtils
 * @see https://github.com/alarussaj/apex-access-utils
 */
public class AccessUtilsException extends Exception {
}
