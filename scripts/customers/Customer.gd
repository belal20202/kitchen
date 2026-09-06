extends Node2D
class_name Customer
## Runtime representation of a single customer visiting the restaurant.
## Holds patience/happiness state and the list of Orders they placed.
## Visuals (sprite/animation) are attached in the Customer.tscn scene;
## this script only owns gameplay logic so it stays testable headless.

signal patience_depleted(customer: Customer)
signal happiness_changed(customer: Customer, happiness: float)
signal order_ready_to_place(customer: Customer)

var customer_id: int = -1
var type_data: CustomerTypeData
var orders: Array[Order] = []

var patience_remaining: float = 45.0
var happiness: float = 1.0 # 0-1
var waiting_time: float = 0.0
var payment: int = 0
var tip: int = 0
var is_being_served: bool = false

@onready var _sprite: Sprite2D = %Sprite
@onready var _patience_bar: ProgressBar = %PatienceBar

var _idle_timer: float = 0.0
var _sprite_base_y: float = 0.0
var _is_reacting: bool = false

func _ready() -> void:
	set_process(false)
	if _sprite:
		_sprite_base_y = _sprite.position.y

func setup(p_type_data: CustomerTypeData, available_recipes: Array[RecipeData], rng: RandomNumberGenerator = null) -> void:
	customer_id = GameManager.get_next_customer_id()
	type_data = p_type_data
	patience_remaining = type_data.base_patience_seconds
	happiness = 1.0
	waiting_time = 0.0
	_generate_orders(available_recipes, rng)
	if _sprite and type_data.portrait:
		_sprite.texture = type_data.portrait
	set_process(true)

func _process(delta: float) -> void:
	tick(delta)
	if _patience_bar and type_data:
		_patience_bar.value = clampf(patience_remaining / max(type_data.base_patience_seconds, 0.01), 0.0, 1.0)
	# Gentle idle "breathing" bob so customers don't feel static.
	if _sprite and not _is_reacting:
		_idle_timer += delta
		_sprite.position.y = _sprite_base_y + sin(_idle_timer * 3.0) * 3.0

func _generate_orders(available_recipes: Array[RecipeData], rng: RandomNumberGenerator) -> void:
	orders.clear()
	if available_recipes.is_empty():
		return
	var count: int = max(1, type_data.order_size)
	for i in range(count):
		var recipe: RecipeData
		if rng:
			recipe = available_recipes[rng.randi_range(0, available_recipes.size() - 1)]
		else:
			recipe = available_recipes[i % available_recipes.size()]
		orders.append(Order.new(recipe))

func tick(delta: float) -> void:
	if is_being_served:
		return
	waiting_time += delta
	patience_remaining -= delta * type_data.patience_decay_multiplier
	var patience_ratio: float = clampf(patience_remaining / type_data.base_patience_seconds, 0.0, 1.0)
	set_happiness(patience_ratio)
	if patience_remaining <= 0.0:
		patience_depleted.emit(self)

func set_happiness(value: float) -> void:
	happiness = clampf(value, 0.0, 1.0)
	happiness_changed.emit(self, happiness)

func decrease_happiness(amount: float) -> void:
	set_happiness(happiness - amount)

## Quick scale "pop" celebration played when a customer is served happy.
func play_happy_reaction() -> void:
	if _sprite == null:
		return
	_is_reacting = true
	var base_scale := _sprite.scale
	var tween := create_tween()
	tween.tween_property(_sprite, "scale", base_scale * 1.35, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_sprite, "scale", base_scale * 0.95, 0.1)
	tween.tween_property(_sprite, "scale", base_scale, 0.1)
	tween.tween_callback(func(): _is_reacting = false)

## Quick left-right shake played when a customer leaves unhappy.
func play_angry_reaction() -> void:
	if _sprite == null:
		return
	_is_reacting = true
	var start_x := _sprite.position.x
	var tween := create_tween()
	tween.tween_property(_sprite, "position:x", start_x - 8, 0.06)
	tween.tween_property(_sprite, "position:x", start_x + 8, 0.06)
	tween.tween_property(_sprite, "position:x", start_x - 6, 0.06)
	tween.tween_property(_sprite, "position:x", start_x + 4, 0.06)
	tween.tween_property(_sprite, "position:x", start_x, 0.06)
	tween.tween_callback(func(): _is_reacting = false)

func all_orders_ready() -> bool:
	for order in orders:
		if order.state != Order.OrderState.READY:
			return false
	return true

func calculate_payment_and_tip() -> void:
	var base_price := 0
	for order in orders:
		base_price += int(order.get_price() * order.quality)
	payment = int(round(base_price * type_data.payment_multiplier))
	var service_speed: float = clampf(1.0 - (waiting_time / max(type_data.base_patience_seconds, 1.0)), 0.0, 1.0)
	var avg_quality := 1.0
	if not orders.is_empty():
		var total_quality := 0.0
		for order in orders:
			total_quality += order.quality
		avg_quality = total_quality / orders.size()
	tip = int(EconomyManager.calculate_tip(base_price, happiness, service_speed, avg_quality) * type_data.tip_multiplier)
