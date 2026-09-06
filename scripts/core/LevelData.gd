extends Resource
class_name LevelData
## Data-driven definition of a single playable level within a restaurant.

@export var level_id: int = 1
@export var restaurant_id: String = "burger_restaurant"
@export var time_limit_seconds: float = 120.0
@export var customer_count: int = 8
@export var target_money: int = 100
@export var target_happiness: float = 0.7 # 0-1, average happiness required to pass.
@export var available_recipes: Array[String] = []
@export var difficulty: int = 1 # 1-5, used for UI display and spawn tuning.
@export var customer_type_weights: Dictionary = {"normal": 1.0}
@export var max_concurrent_orders: int = 3

# Star thresholds, evaluated in order 3 -> 2 -> 1.
@export var three_star_money: int = 0 # 0 = auto-calc as target_money * 2
@export var two_star_money: int = 0 # 0 = auto-calc as target_money * 1.5
