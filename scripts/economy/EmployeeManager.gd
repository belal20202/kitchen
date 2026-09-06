extends Node
class_name EmployeeManager
## Lightweight helper (instantiated by the Employees menu, not an
## autoload) that wraps hiring/upgrading logic on top of
## GameManager.employee_levels and EconomyManager transactions.

var _catalog: Dictionary = {} # employee_id -> EmployeeData

const EMPLOYEES_JSON := "res://data/upgrades/employees.json"

func _ready() -> void:
	_load_catalog()

func _load_catalog() -> void:
	_catalog.clear()
	if not FileAccess.file_exists(EMPLOYEES_JSON):
		push_warning("EmployeeManager: missing %s" % EMPLOYEES_JSON)
		return
	var file := FileAccess.open(EMPLOYEES_JSON, FileAccess.READ)
	var content := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(content) != OK:
		push_error("EmployeeManager: failed to parse %s" % EMPLOYEES_JSON)
		return
	var role_map := {
		"CHEF": EmployeeData.EmployeeRole.CHEF,
		"WAITER": EmployeeData.EmployeeRole.WAITER,
		"CASHIER": EmployeeData.EmployeeRole.CASHIER,
	}
	for entry in json.data:
		var data := EmployeeData.new()
		data.employee_id = entry.get("employee_id", "")
		data.display_name = entry.get("display_name", "")
		data.role = role_map.get(entry.get("role", "CHEF"), EmployeeData.EmployeeRole.CHEF)
		data.base_speed_bonus = entry.get("base_speed_bonus", 0.1)
		data.speed_bonus_per_level = entry.get("speed_bonus_per_level", 0.05)
		data.max_level = entry.get("max_level", 5)
		data.base_salary = entry.get("base_salary", 20)
		data.salary_growth_per_level = entry.get("salary_growth_per_level", 0.2)
		data.hire_cost = entry.get("hire_cost", 100)
		_catalog[data.employee_id] = data

func get_employee_data(employee_id: String) -> EmployeeData:
	return _catalog.get(employee_id, null)

func get_all_employees() -> Dictionary:
	return _catalog

func is_hired(employee_id: String) -> bool:
	return GameManager.employee_levels.has(employee_id)

func hire(employee_id: String) -> bool:
	if is_hired(employee_id):
		return false
	var data := get_employee_data(employee_id)
	if data == null:
		return false
	if not EconomyManager.spend_coins(data.hire_cost):
		return false
	GameManager.employee_levels[employee_id] = 1
	return true

func upgrade(employee_id: String) -> bool:
	if not is_hired(employee_id):
		return false
	var data := get_employee_data(employee_id)
	var current_level: int = GameManager.employee_levels[employee_id]
	if current_level >= data.max_level:
		return false
	var cost: int = int(round(data.hire_cost * 0.5 * current_level))
	if not EconomyManager.spend_coins(cost):
		return false
	GameManager.employee_levels[employee_id] = current_level + 1
	return true

func get_total_speed_bonus() -> float:
	var total := 0.0
	for employee_id in GameManager.employee_levels.keys():
		var data := get_employee_data(employee_id)
		if data:
			total += data.get_speed_bonus(GameManager.employee_levels[employee_id])
	return total
