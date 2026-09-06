extends RefCounted
class_name Order
## Represents one order tied to a customer. A Customer with `order_size`
## greater than 1 (e.g. Family type) owns multiple Order instances.

enum OrderState { WAITING, PREPARING, COOKING, READY, BURNED, SERVED, CANCELLED }

var order_id: int = -1
var recipe: RecipeData
var state: int = OrderState.WAITING
var elapsed_cook_time: float = 0.0
var quality: float = 1.0 # 0-1, degrades if left burning or handled poorly.

func _init(p_recipe: RecipeData) -> void:
	recipe = p_recipe
	order_id = GameManager.get_next_order_id()

func start_preparing() -> void:
	state = OrderState.PREPARING

func start_cooking() -> void:
	state = OrderState.COOKING
	elapsed_cook_time = 0.0

func tick_cooking(delta: float) -> void:
	if state != OrderState.COOKING:
		return
	elapsed_cook_time += delta
	if elapsed_cook_time >= recipe.cooking_time and elapsed_cook_time < recipe.cooking_time + recipe.burn_grace_period:
		state = OrderState.READY
	elif elapsed_cook_time >= recipe.cooking_time + recipe.burn_grace_period:
		state = OrderState.BURNED
		quality = 0.0

func mark_served() -> void:
	state = OrderState.SERVED

func get_price() -> int:
	if recipe == null:
		return 0
	return recipe.price
