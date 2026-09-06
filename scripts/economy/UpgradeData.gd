extends Resource
class_name UpgradeData
## Data-driven definition of an upgrade path for equipment, the
## restaurant itself, storage, or customer capacity.

@export var upgrade_id: String = ""
@export var display_name: String = ""
@export var max_level: int = 3
@export var base_cost: int = 50
@export var cost_growth: float = 1.6 # Cost multiplier per level.
@export var effect_description: String = "" # Human-readable, e.g. "Cooking Time -2s"
@export var effect_values: Array[float] = [] # Per-level effect value, index 0 = level 1's effect.

func get_cost_for_level(current_level: int) -> int:
	if current_level >= max_level:
		return -1 # Already maxed.
	return int(round(base_cost * pow(cost_growth, current_level - 1)))

func get_effect_for_level(level: int) -> float:
	var index: int = clampi(level - 1, 0, effect_values.size() - 1)
	if effect_values.is_empty():
		return 0.0
	return effect_values[index]
