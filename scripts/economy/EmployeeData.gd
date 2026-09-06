extends Resource
class_name EmployeeData
## Data-driven definition of a hireable employee type (Chef, Waiter,
## Cashier). Runtime hiring state (which employees the player owns and
## at what level) is tracked in GameManager.employee_levels.

enum EmployeeRole { CHEF, WAITER, CASHIER }

@export var employee_id: String = ""
@export var display_name: String = ""
@export var role: EmployeeRole = EmployeeRole.CHEF
@export var base_speed_bonus: float = 0.1 # e.g. 0.1 = 10% faster cooking/serving/checkout.
@export var speed_bonus_per_level: float = 0.05
@export var max_level: int = 5
@export var base_salary: int = 20 # Coins deducted at the end of each level played.
@export var salary_growth_per_level: float = 0.2
@export var hire_cost: int = 100
@export var portrait: Texture2D

func get_speed_bonus(level: int) -> float:
	return base_speed_bonus + (speed_bonus_per_level * max(level - 1, 0))

func get_salary(level: int) -> int:
	return int(round(base_salary * (1.0 + salary_growth_per_level * max(level - 1, 0))))
