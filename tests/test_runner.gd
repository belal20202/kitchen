extends SceneTree
## TestRunner
## A minimal, dependency-free test runner: each file in res://tests/
## that extends "TestCase" and whose methods start with "test_" is
## executed automatically. Run with:
##   godot --headless --script res://tests/test_runner.gd
## Exits with code 0 if all tests pass, 1 if any test fails - suitable
## for CI (see .github/workflows/android.yml which can optionally call
## this before building).

const TEST_SCRIPTS := [
	"res://tests/test_economy.gd",
	"res://tests/test_recipe.gd",
	"res://tests/test_order.gd",
	"res://tests/test_customer.gd",
	"res://tests/test_save_load.gd",
	"res://tests/test_level.gd",
]

func _initialize() -> void:
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
				var err = instance.callv(method_name, [])
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
