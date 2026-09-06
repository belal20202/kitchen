extends Control
## Kitchen
## Drives one playable level: spawns customers, lets the player tap
## ingredients in the correct order to prep a recipe, tap the matching
## equipment to cook it, then tap Serve once it's ready. Simplified to
## tap-based sequencing (rather than drag/drop) so it stays fast,
## readable, and fully testable without a physics/input rig.

@onready var order_system: OrderSystem = $OrderSystem
@onready var customer_spawner: CustomerSpawner = $CustomerSpawner
@onready var background_rect: TextureRect = $Background

@onready var money_label: Label = %MoneyLabel
@onready var timer_label: Label = %TimerLabel
@onready var goal_label: Label = %GoalLabel
@onready var combo_label: Label = %ComboLabel
@onready var order_ticket_label: Label = %OrderTicketLabel
@onready var order_icon_rect: TextureRect = %OrderIconRect
@onready var current_step_label: Label = %CurrentStepLabel

@onready var customer_row: HBoxContainer = %CustomerRow
@onready var ingredient_row: HBoxContainer = %IngredientRow
@onready var equipment_row: HBoxContainer = %EquipmentRow
@onready var serve_button: Button = %ServeButton
@onready var pause_panel: Control = %PausePanel
@onready var tutorial_panel: Control = %TutorialPanel

var _level: LevelData
var _time_remaining: float = 0.0
var _selected_customer: Customer = null
var _active_order: Order = null
var _prep_progress: int = 0 # index into recipe.ingredients the player has matched so far.
var _is_paused: bool = false
var _tutorial_active: bool = false
var _employee_manager: EmployeeManager

const EQUIPMENT_ICON_PATHS := {
	"grill": "res://assets/sprites/equipment/grill.svg",
	"oven": "res://assets/sprites/equipment/oven.svg",
	"fryer": "res://assets/sprites/equipment/fryer.svg",
	"coffee_machine": "res://assets/sprites/equipment/coffee_machine.svg",
	"juice_machine": "res://assets/sprites/equipment/juice_machine.svg",
}

func _ready() -> void:
	_level = LevelManager.get_level(GameManager.current_restaurant_id, GameManager.current_level_id)
	if _level == null:
		push_error("Kitchen: no LevelData found for %s level %d" % [GameManager.current_restaurant_id, GameManager.current_level_id])
		get_tree().change_scene_to_file("res://scenes/menus/LevelSelect.tscn")
		return

	var restaurant := LevelManager.get_restaurant(GameManager.current_restaurant_id)
	if restaurant and restaurant.music_key != "":
		AudioManager.play_music(restaurant.music_key)
	if restaurant and restaurant.background:
		background_rect.texture = restaurant.background

	order_system.max_concurrent_orders = _level.max_concurrent_orders
	_time_remaining = _level.time_limit_seconds
	pause_panel.visible = false

	GameManager.start_level(GameManager.current_restaurant_id, GameManager.current_level_id)
	customer_spawner.start(_level)
	customer_spawner.customer_spawned.connect(_on_customer_spawned)
	order_system.order_ready.connect(_on_order_ready)
	order_system.order_burned.connect(_on_order_burned)
	GameManager.combo_changed.connect(_on_combo_changed)

	_build_equipment_row()
	_refresh_hud()
	serve_button.disabled = true

	tutorial_panel.visible = false
	if not GameManager.tutorial_completed and GameManager.current_restaurant_id == "burger_restaurant" and GameManager.current_level_id == 1:
		_start_tutorial()

func _start_tutorial() -> void:
	_tutorial_active = true
	customer_spawner.set_process(false)
	tutorial_panel.visible = true

func _on_tutorial_dismissed() -> void:
	tutorial_panel.visible = false
	_tutorial_active = false
	customer_spawner.set_process(true)
	GameManager.tutorial_completed = true
	SaveManager.save_game()

func _process(delta: float) -> void:
	if _is_paused or _tutorial_active or GameManager.current_state != GameManager.GameState.PLAYING:
		return

	_time_remaining -= delta
	if _time_remaining <= 0.0:
		_time_remaining = 0.0
		_finish_level()
		return

	_refresh_hud()
	_update_serve_button_pulse()

# ---------------------------------------------------------------------------
# HUD
# ---------------------------------------------------------------------------

func _refresh_hud() -> void:
	money_label.text = "$%d" % (GameManager.session_money_earned + GameManager.session_tips_earned)
	var minutes := int(_time_remaining) / 60
	var seconds := int(_time_remaining) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]
	goal_label.text = "Goal: $%d" % _level.target_money
	combo_label.visible = GameManager.current_combo > 1
	combo_label.text = "Combo x%d" % GameManager.current_combo

func _on_combo_changed(_count: int) -> void:
	_refresh_hud()

func _update_serve_button_pulse() -> void:
	if serve_button.disabled:
		serve_button.scale = Vector2.ONE
		return
	var pulse: float = 1.0 + 0.07 * sin(Time.get_ticks_msec() / 140.0)
	serve_button.pivot_offset = serve_button.size / 2.0
	serve_button.scale = Vector2(pulse, pulse)

# ---------------------------------------------------------------------------
# Customers
# ---------------------------------------------------------------------------

func _on_customer_spawned(customer: Customer) -> void:
	# The customer's own Node2D visual lives in the CustomersWorld layer
	# (placed there by CustomerSpawner); here we only add its UI button.
	customer.patience_depleted.connect(_on_customer_patience_depleted)
	var button := Button.new()
	button.name = "CustomerButton_%d" % customer.customer_id
	button.text = "#%d" % customer.customer_id
	button.custom_minimum_size = Vector2(64, 64)
	if customer.type_data and customer.type_data.portrait:
		button.icon = customer.type_data.portrait
		button.expand_icon = true
	button.set_meta("customer_id", customer.customer_id)
	button.pressed.connect(_on_customer_button_pressed.bind(customer))
	customer_row.add_child(button)
	customer.set_meta("ui_button", button)

func _on_customer_button_pressed(customer: Customer) -> void:
	if customer.is_being_served:
		return
	_selected_customer = customer
	_prep_progress = 0
	_active_order = null
	_update_order_ticket()
	AudioManager.play_sfx("ui_click")

func _on_customer_patience_depleted(customer: Customer) -> void:
	# Customer leaves unhappy: no payment, small happiness penalty logged.
	_remove_customer(customer, false)
	AudioManager.play_sfx("customer_angry")

func _remove_customer(customer: Customer, was_served: bool) -> void:
	var button: Button = customer.get_meta("ui_button", null)
	if button:
		button.queue_free()
	if _selected_customer == customer:
		_selected_customer = null
		_active_order = null
		_prep_progress = 0
		_update_order_ticket()

	if was_served and customer.happiness > 0.6:
		customer.play_happy_reaction()
	elif not was_served:
		customer.play_angry_reaction()

	# Let the reaction animation play for a moment before removing the customer.
	var timer := get_tree().create_timer(0.6)
	timer.timeout.connect(customer.queue_free)

# ---------------------------------------------------------------------------
# Ingredient prep
# ---------------------------------------------------------------------------

func _build_equipment_row() -> void:
	for child in equipment_row.get_children():
		child.queue_free()
	var restaurant := LevelManager.get_restaurant(GameManager.current_restaurant_id)
	if restaurant == null:
		return
	for equipment_id in restaurant.equipment_ids:
		var button := Button.new()
		button.text = equipment_id.capitalize()
		button.custom_minimum_size = Vector2(100, 72)
		var icon_path: String = EQUIPMENT_ICON_PATHS.get(equipment_id, "")
		if icon_path != "" and ResourceLoader.exists(icon_path):
			button.icon = load(icon_path)
			button.expand_icon = true
			button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.pressed.connect(_on_equipment_pressed.bind(equipment_id, button))
		equipment_row.add_child(button)

func _rebuild_ingredient_row(recipe: RecipeData) -> void:
	for child in ingredient_row.get_children():
		child.queue_free()
	for ingredient_id in recipe.ingredients:
		var ingredient := LevelManager.get_ingredient(ingredient_id)
		var button := Button.new()
		button.text = ingredient.ingredient_name if ingredient else ingredient_id.capitalize()
		button.custom_minimum_size = Vector2(90, 72)
		if ingredient and ingredient.icon:
			button.icon = ingredient.icon
			button.expand_icon = true
			button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.pressed.connect(_on_ingredient_pressed.bind(ingredient_id, button))
		ingredient_row.add_child(button)

func _update_order_ticket() -> void:
	if _selected_customer == null or _selected_customer.orders.is_empty():
		order_ticket_label.text = "Select a customer"
		current_step_label.text = ""
		order_icon_rect.texture = null
		ingredient_row.visible = false
		serve_button.disabled = true
		return

	# Find the first order for this customer that isn't served yet.
	var pending_order: Order = null
	for order in _selected_customer.orders:
		if order.state != Order.OrderState.SERVED:
			pending_order = order
			break

	if pending_order == null:
		order_ticket_label.text = "All dishes ready!"
		order_icon_rect.texture = null
		return

	order_ticket_label.text = "Order: %s ($%d)" % [pending_order.recipe.recipe_name, pending_order.recipe.price]
	order_icon_rect.texture = pending_order.recipe.icon

	if pending_order.state == Order.OrderState.WAITING:
		ingredient_row.visible = true
		_rebuild_ingredient_row(pending_order.recipe)
		var next_ingredient: String = pending_order.recipe.ingredients[_prep_progress] if _prep_progress < pending_order.recipe.ingredients.size() else ""
		current_step_label.text = "Add: %s" % next_ingredient.capitalize()
		serve_button.disabled = true
	elif pending_order.state == Order.OrderState.COOKING:
		ingredient_row.visible = false
		current_step_label.text = "Cooking on %s..." % pending_order.recipe.equipment_required.capitalize()
		serve_button.disabled = true
	elif pending_order.state == Order.OrderState.READY:
		ingredient_row.visible = false
		current_step_label.text = "Ready to serve!"
		serve_button.disabled = false
	elif pending_order.state == Order.OrderState.BURNED:
		ingredient_row.visible = false
		current_step_label.text = "Burned! Serve anyway or it will be wasted."
		serve_button.disabled = false

	_active_order = pending_order

func _on_ingredient_pressed(ingredient_id: String, button: Button) -> void:
	if _active_order == null or _active_order.state != Order.OrderState.WAITING:
		return
	var recipe := _active_order.recipe
	if _prep_progress >= recipe.ingredients.size():
		return
	if recipe.ingredients[_prep_progress] == ingredient_id:
		_prep_progress += 1
		AudioManager.play_sfx("chop")
		_punch_button(button)
		if _prep_progress >= recipe.ingredients.size():
			_active_order.start_preparing()
			current_step_label.text = "Ready to cook! Tap: %s" % recipe.equipment_required.capitalize()
			ingredient_row.visible = false
		else:
			_update_order_ticket()
	else:
		# Wrong ingredient: small happiness penalty for the waiting customer.
		if _selected_customer:
			_selected_customer.decrease_happiness(0.05)
		_shake_button(button)
		AudioManager.play_sfx("burn_warning")

func _punch_button(button: Button) -> void:
	if button == null or not is_instance_valid(button):
		return
	button.pivot_offset = button.size / 2.0
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2(1.18, 1.18), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2.ONE, 0.1)

func _shake_button(button: Button) -> void:
	if button == null or not is_instance_valid(button):
		return
	var start_x := button.position.x
	var tween := create_tween()
	tween.tween_property(button, "position:x", start_x - 6, 0.05)
	tween.tween_property(button, "position:x", start_x + 6, 0.05)
	tween.tween_property(button, "position:x", start_x - 4, 0.05)
	tween.tween_property(button, "position:x", start_x, 0.05)

func _on_equipment_pressed(equipment_id: String, button: Button) -> void:
	if _active_order == null:
		return
	if _active_order.state != Order.OrderState.PREPARING:
		return
	if _active_order.recipe.equipment_required != equipment_id:
		if _selected_customer:
			_selected_customer.decrease_happiness(0.05)
		_shake_button(button)
		return
	order_system.start_cooking(_active_order)
	AudioManager.play_sfx("sizzle")
	_punch_button(button)
	_update_order_ticket()

func _on_order_ready(order: Order) -> void:
	AudioManager.play_sfx("plate_up")
	if order == _active_order:
		_update_order_ticket()

func _on_order_burned(order: Order) -> void:
	if order == _active_order:
		_update_order_ticket()

func _on_serve_pressed() -> void:
	if _selected_customer == null or _active_order == null:
		return
	if _active_order.state != Order.OrderState.READY and _active_order.state != Order.OrderState.BURNED:
		return

	order_system.complete_order(_active_order)
	_prep_progress = 0

	if _selected_customer.all_orders_ready() or _all_customer_orders_served(_selected_customer):
		_selected_customer.calculate_payment_and_tip()
		var combo_multiplier := EconomyManager.get_combo_multiplier(GameManager.current_combo)
		var final_payment := _selected_customer.payment
		var final_tip := int(_selected_customer.tip * combo_multiplier)
		GameManager.register_order_completed(final_payment, final_tip, _selected_customer.happiness)
		AudioManager.play_sfx("cash_register")
		if _selected_customer.happiness > 0.6:
			AudioManager.play_sfx("customer_happy")
		_remove_customer(_selected_customer, true)
	else:
		_update_order_ticket()

	_refresh_hud()

func _all_customer_orders_served(customer: Customer) -> bool:
	for order in customer.orders:
		if order.state != Order.OrderState.SERVED:
			return false
	return true

# ---------------------------------------------------------------------------
# Level end / pause
# ---------------------------------------------------------------------------

func _finish_level() -> void:
	customer_spawner.stop()
	var success: bool = (GameManager.session_money_earned + GameManager.session_tips_earned) >= _level.target_money
	var result := GameManager.end_level(success)
	get_tree().change_scene_to_file("res://scenes/menus/LevelComplete.tscn")
	# LevelComplete reads the result from GameManager's last session_* fields.

func _on_pause_pressed() -> void:
	_is_paused = not _is_paused
	pause_panel.visible = _is_paused
	get_tree().paused = _is_paused

func _on_resume_pressed() -> void:
	_is_paused = false
	pause_panel.visible = false
	get_tree().paused = false

func _on_quit_to_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")
