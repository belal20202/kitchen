extends SceneTree
## TestRunner
## A minimal, dependency-free test runner: each file in res://tests/
## that extends "TestCase" and whose methods start with "test_" is
## executed automatically. Run with:
##   godot --headless --script res://tests/test_runner.gd
## Exits with code 0 if all tests pass, 1 if any test fails - suitable
## for CI (see .github/workflows/android.yml which can optionally call
## this before building).
##
## IMPORTANT: tests run from _process(), not _initialize(). Autoload
## singletons (GameManager, LevelManager, AudioManager, ...) only get
## their _ready() called once the engine processes its first frame -
## _initialize() fires BEFORE that, so autoload state (loaded JSON
## data, created child nodes, etc.) would not exist yet if we ran
## tests there. Waiting for the first _process() call guarantees every
## autoload is fully ready.

const TEST_SCRIPTS := [
	"res://tests/test_economy.gd",
	"res://tests/test_recipe.gd",
	"res://tests/test_order.gd",
	"res://tests/test_customer.gd",
	"res://tests/test_save_load.gd",
	"res://tests/test_level.gd",
]

var _has_run: bool = false

func _process(_delta: float) -> bool:
	if _has_run:
		return true
	_has_run = true
	_run_all_tests()
	return true # Quit the main loop after this frame.

func _run_all_tests() -> void:
	var total := 0
	var failed := 0

	for path in TEST_SCRIPTS:
		var script: GDScript = load(path)
		var instance: TestCase = script.new()
		instance.setup_autoloads(self)
		for method in script.get_script_method_list():
			var method_name: String = method["name"]
			if method_name.begins_with("test_"):
				total += 1
				instance.reset()
				var ok := true
				var error_message := ""
				instance.callv(method_name, [])
				if instance.has_failure():
					ok = false
					error_message = instance.get_failure_message()
				if ok:
					print("[PASS] %s::%s" % [path.get_file(), method_name])
				else:
					failed += 1
					print("[FAIL] %s::%s -> %s" % [path.get_file(), method_name, error_message])

	print("\n%d tests run, %d failed." % [total, failed])
	quit(1 if failed > 0 else 0)
