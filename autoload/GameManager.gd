extends Node
## GameManager
## Central hub for global game state, current session data, and
## coordination between the other manager singletons.
## This is an Autoload (Singleton) - accessible from anywhere as `GameManager`.

signal level_started(level_id: int)
signal level_ended(result: Dictionary)
signal customer_served(customer_id: int, happiness: float)
signal combo_changed(combo_count: int)
signal money_changed(new_amount: int)

enum GameState { MENU, PLAYING, PAUSED, LEVEL_COMPLETE, LEVEL_FAILED }

var current_state: int = GameState.MENU

# --- Player progression (persisted via SaveManager) ---
var player_level: int = 1
var coins: int = 0
var gems: int = 0
var unlocked_restaurants: Array = ["burger_restaurant"]
var unlocked_recipes: Array = ["burger", "french_fries", "juice", "coffee"]
var equipment_levels: Dictionary = {}
var employee_levels: Dictionary = {}
var achievements_unlocked: Array = []
var level_stars: Dictionary = {} # level_id (String) -> stars earned (int)

# --- Current session state (not persisted, reset each level) ---
var current_restaurant_id: String = "burger_restaurant"
var current_level_id: int = 1
var session_money_earned: int = 0
var session_tips_earned: int = 0
var session_customers_served: int = 0
var session_best_combo: int = 0
var current_combo: int = 0
var combo_timer: float = 0.0
const COMBO_WINDOW_SECONDS: float = 6.0

# --- Simple ID generators (kept here instead of "static var" on Order/
#     Customer so the project stays compatible with Godot 4.0-4.2, where
#     per-class static variables are not yet available). ---
var _next_order_id: int = 1
var _next_customer_id: int = 1

func get_next_order_id() -> int:
	var id := _next_order_id
	_next_order_id += 1
	return id

func get_next_customer_id() -> int:
	var id := _next_customer_id
	_next_customer_id += 1
	return id

# --- Onboarding ---
var tutorial_completed: bool = false

func _ready() -> void:
	set_process(false)

func _process(delta: float) -> void:
	if current_combo > 0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			reset_combo()

func start_level(restaurant_id: String, level_id: int) -> void:
	current_restaurant_id = restaurant_id
	current_level_id = level_id
	session_money_earned = 0
	session_tips_earned = 0
	session_customers_served = 0
	session_best_combo = 0
	current_combo = 0
	current_state = GameState.PLAYING
	set_process(true)
	level_started.emit(level_id)

func end_level(success: bool) -> Dictionary:
	set_process(false)
	current_state = GameState.LEVEL_COMPLETE if success else GameState.LEVEL_FAILED
	var stars := 0
	if success:
		stars = LevelManager.calculate_stars(
			current_restaurant_id,
			current_level_id,
			session_money_earned,
			session_customers_served,
			session_best_combo
		)
		var key := "%s_%d" % [current_restaurant_id, current_level_id]
		var previous_best: int = level_stars.get(key, 0)
		if stars > previous_best:
			level_stars[key] = stars
		coins += session_money_earned + session_tips_earned
		money_changed.emit(coins)
	var result := {
		"success": success,
		"stars": stars,
		"money_earned": session_money_earned,
		"tips_earned": session_tips_earned,
		"customers_served": session_customers_served,
		"best_combo": session_best_combo,
	}
	level_ended.emit(result)
	SaveManager.save_game()
	return result

func register_order_completed(base_payment: int, tip: int, happiness: float) -> void:
	session_money_earned += base_payment
	session_tips_earned += tip
	session_customers_served += 1
	register_combo_hit()

func register_combo_hit() -> void:
	current_combo += 1
	combo_timer = COMBO_WINDOW_SECONDS
	if current_combo > session_best_combo:
		session_best_combo = current_combo
	combo_changed.emit(current_combo)

func reset_combo() -> void:
	current_combo = 0
	combo_timer = 0.0
	combo_changed.emit(current_combo)

func unlock_restaurant(restaurant_id: String) -> void:
	if not unlocked_restaurants.has(restaurant_id):
		unlocked_restaurants.append(restaurant_id)

func unlock_recipe(recipe_id: String) -> void:
	if not unlocked_recipes.has(recipe_id):
		unlocked_recipes.append(recipe_id)

func get_equipment_level(equipment_id: String) -> int:
	return equipment_levels.get(equipment_id, 1)

func set_equipment_level(equipment_id: String, level: int) -> void:
	equipment_levels[equipment_id] = level

func unlock_achievement(achievement_id: String) -> void:
	if not achievements_unlocked.has(achievement_id):
		achievements_unlocked.append(achievement_id)

func get_stars_for_level(restaurant_id: String, level_id: int) -> int:
	var key := "%s_%d" % [restaurant_id, level_id]
	return level_stars.get(key, 0)

func get_total_stars() -> int:
	var total := 0
	for key in level_stars.keys():
		total += level_stars[key]
	return total

func reset_progress() -> void:
	player_level = 1
	coins = 0
	gems = 0
	unlocked_restaurants = ["burger_restaurant"]
	unlocked_recipes = ["burger", "french_fries", "juice", "coffee"]
	equipment_levels.clear()
	employee_levels.clear()
	achievements_unlocked.clear()
	level_stars.clear()
