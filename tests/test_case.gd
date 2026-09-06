extends RefCounted
class_name TestCase
## Minimal assertion helper base class used by every test_*.gd file.
## Not a full testing framework by design - kept intentionally small
## so it has zero external dependencies and is easy to audit.

var _failed: bool = false
var _failure_message: String = ""
var _tree: SceneTree

func setup_autoloads(tree: SceneTree) -> void:
	_tree = tree

func reset() -> void:
	_failed = false
	_failure_message = ""

func has_failure() -> bool:
	return _failed

func get_failure_message() -> String:
	return _failure_message

func _fail(message: String) -> void:
	if not _failed: # keep the first failure message
		_failed = true
		_failure_message = message

func assert_true(condition: bool, message: String = "expected true") -> void:
	if not condition:
		_fail(message)

func assert_false(condition: bool, message: String = "expected false") -> void:
	if condition:
		_fail(message)

func assert_eq(actual, expected, message: String = "") -> void:
	if actual != expected:
		_fail("%s (got %s, expected %s)" % [message, str(actual), str(expected)])

func assert_gt(actual, threshold, message: String = "") -> void:
	if not (actual > threshold):
		_fail("%s (got %s, expected > %s)" % [message, str(actual), str(threshold)])

func assert_almost_eq(actual: float, expected: float, tolerance: float = 0.01, message: String = "") -> void:
	if abs(actual - expected) > tolerance:
		_fail("%s (got %f, expected ~%f)" % [message, actual, expected])
