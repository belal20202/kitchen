extends Node2D
class_name Equipment
## Represents a single piece of kitchen equipment (Grill, Oven, Fryer,
## Coffee Machine, Juice Machine, Preparation Table, Counter, Refrigerator).
## Cooking time scales down as the equipment's upgrade level increases.

signal order_slot_freed

@export var equipment_id: String = "grill" # Matches UpgradeData.upgrade_id
@export var accepts_equipment_tag: String = "grill" # Must match RecipeData.equipment_required
@export var base_cooking_time_by_level: Array[float] = [8.0, 6.0, 4.0]
@export var max_slots: int = 1

var occupied_orders: Array[Order] = []

func get_current_level() -> int:
	return GameManager.get_equipment_level(equipment_id)

func get_cooking_time_multiplier() -> float:
	var level: int = clampi(get_current_level(), 1, base_cooking_time_by_level.size())
	var base_time: float = base_cooking_time_by_level[0]
	var current_time: float = base_cooking_time_by_level[level - 1]
	if base_time <= 0.0:
		return 1.0
	return current_time / base_time

func can_accept_recipe(recipe: RecipeData) -> bool:
	return recipe.equipment_required == accepts_equipment_tag and occupied_orders.size() < max_slots

func place_order(order: Order) -> bool:
	if not can_accept_recipe(order.recipe):
		return false
	# Apply the equipment's upgrade level by scaling the effective cooking time.
	order.recipe.cooking_time = order.recipe.cooking_time * get_cooking_time_multiplier()
	occupied_orders.append(order)
	order.start_cooking()
	return true

func remove_order(order: Order) -> void:
	occupied_orders.erase(order)
	order_slot_freed.emit()
