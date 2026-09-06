extends Node
## LevelManager
## Loads recipe / customer-type / level definitions from the JSON files
## under res://data/ and builds typed Resource instances (RecipeData,
## CustomerTypeData, LevelData) from them. JSON is used instead of
## hand-authored .tres files because it is trivial to validate, diff,
## and extend by designers who don't have the Godot editor open.

var _levels_by_restaurant: Dictionary = {} # restaurant_id -> Array[LevelData]
var _recipes: Dictionary = {} # recipe_id -> RecipeData
var _ingredients: Dictionary = {} # ingredient_id -> IngredientData
var _customer_types: Dictionary = {} # type_id (String) -> CustomerTypeData
var _restaurants: Dictionary = {} # restaurant_id -> RestaurantData

const RECIPES_JSON := "res://data/recipes/recipes.json"
const INGREDIENTS_JSON := "res://data/recipes/ingredients.json"
const CUSTOMERS_JSON := "res://data/customers/customer_types.json"
const LEVELS_DIR := "res://data/levels/"
const RESTAURANTS_JSON := "res://data/restaurants/restaurants.json"

func _ready() -> void:
	_load_ingredients()
	_load_recipes()
	_load_customer_types()
	_load_restaurants()
	_load_levels()

# ---------------------------------------------------------------------------
# JSON helpers
# ---------------------------------------------------------------------------

static func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_warning("LevelManager: missing data file %s" % path)
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	var content := file.get_as_text()
	file.close()
	var json := JSON.new()
	var err := json.parse(content)
	if err != OK:
		push_error("LevelManager: failed to parse %s (%s)" % [path, json.get_error_message()])
		return null
	return json.data

# ---------------------------------------------------------------------------
# Loading
# ---------------------------------------------------------------------------

func _load_ingredients() -> void:
	_ingredients.clear()
	var data = _read_json(INGREDIENTS_JSON)
	if data == null:
		return
	for entry in data:
		var ingredient := IngredientData.new()
		ingredient.ingredient_id = entry.get("ingredient_id", "")
		ingredient.ingredient_name = entry.get("ingredient_name", "")
		ingredient.requires_prep = entry.get("requires_prep", false)
		ingredient.prep_time = entry.get("prep_time", 1.0)
		ingredient.restock_cost = entry.get("restock_cost", 2)
		ingredient.icon_path = entry.get("icon_path", "")
		if ingredient.icon_path != "" and ResourceLoader.exists(ingredient.icon_path):
			ingredient.icon = load(ingredient.icon_path)
		_ingredients[ingredient.ingredient_id] = ingredient

func _load_recipes() -> void:
	_recipes.clear()
	var data = _read_json(RECIPES_JSON)
	if data == null:
		return
	for entry in data:
		var recipe := RecipeData.new()
		recipe.recipe_id = entry.get("recipe_id", "")
		recipe.recipe_name = entry.get("recipe_name", "")
		var ingredients: Array[String] = []
		for i in entry.get("ingredients", []):
			ingredients.append(String(i))
		recipe.ingredients = ingredients
		recipe.equipment_required = entry.get("equipment_required", "")
		recipe.price = entry.get("price", 10)
		recipe.preparation_time = entry.get("preparation_time", 3.0)
		recipe.cooking_time = entry.get("cooking_time", 8.0)
		recipe.unlock_level = entry.get("unlock_level", 1)
		recipe.burn_grace_period = entry.get("burn_grace_period", 4.0)
		recipe.icon_path = entry.get("icon_path", "")
		if recipe.icon_path != "" and ResourceLoader.exists(recipe.icon_path):
			recipe.icon = load(recipe.icon_path)
		_recipes[recipe.recipe_id] = recipe

func _load_customer_types() -> void:
	_customer_types.clear()
	var data = _read_json(CUSTOMERS_JSON)
	if data == null:
		_customer_types = CustomerTypeData.create_default_types()
		return
	var type_enum_map := {
		"NORMAL": CustomerTypeData.CustomerType.NORMAL,
		"PATIENT": CustomerTypeData.CustomerType.PATIENT,
		"IMPATIENT": CustomerTypeData.CustomerType.IMPATIENT,
		"VIP": CustomerTypeData.CustomerType.VIP,
		"FAMILY": CustomerTypeData.CustomerType.FAMILY,
		"RUSH": CustomerTypeData.CustomerType.RUSH,
	}
	for key in data.keys():
		var entry: Dictionary = data[key]
		var ctype := CustomerTypeData.new()
		ctype.type_id = type_enum_map.get(entry.get("type_id", "NORMAL"), CustomerTypeData.CustomerType.NORMAL)
		ctype.display_name = entry.get("display_name", key)
		ctype.base_patience_seconds = entry.get("base_patience_seconds", 45.0)
		ctype.patience_decay_multiplier = entry.get("patience_decay_multiplier", 1.0)
		ctype.tip_multiplier = entry.get("tip_multiplier", 1.0)
		ctype.payment_multiplier = entry.get("payment_multiplier", 1.0)
		ctype.order_size = entry.get("order_size", 1)
		ctype.spawn_weight = entry.get("spawn_weight", 1.0)
		ctype.portrait_path = entry.get("portrait_path", "")
		if ctype.portrait_path != "" and ResourceLoader.exists(ctype.portrait_path):
			ctype.portrait = load(ctype.portrait_path)
		_customer_types[key] = ctype
	if _customer_types.is_empty():
		_customer_types = CustomerTypeData.create_default_types()

func _load_restaurants() -> void:
	_restaurants.clear()
	var data = _read_json(RESTAURANTS_JSON)
	if data == null:
		return
	for entry in data:
		var restaurant := RestaurantData.new()
		restaurant.restaurant_id = entry.get("restaurant_id", "")
		restaurant.display_name = entry.get("display_name", "")
		restaurant.scene_path = entry.get("scene_path", "")
		restaurant.required_total_stars = entry.get("required_total_stars", 0)
		restaurant.music_key = entry.get("music_key", "")
		restaurant.background_path = entry.get("background_path", "")
		if restaurant.background_path != "" and ResourceLoader.exists(restaurant.background_path):
			restaurant.background = load(restaurant.background_path)
		var recipe_ids: Array[String] = []
		for r in entry.get("recipe_ids", []):
			recipe_ids.append(String(r))
		restaurant.recipe_ids = recipe_ids
		var equipment_ids: Array[String] = []
		for e in entry.get("equipment_ids", []):
			equipment_ids.append(String(e))
		restaurant.equipment_ids = equipment_ids
		_restaurants[restaurant.restaurant_id] = restaurant

func _load_levels() -> void:
	_levels_by_restaurant.clear()
	var dir := DirAccess.open(LEVELS_DIR)
	if dir == null:
		push_warning("LevelManager: missing levels directory %s" % LEVELS_DIR)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			var data = _read_json(LEVELS_DIR + file_name)
			if data != null:
				for entry in data:
					var level := LevelData.new()
					level.level_id = entry.get("level_id", 1)
					level.restaurant_id = entry.get("restaurant_id", "burger_restaurant")
					level.time_limit_seconds = entry.get("time_limit_seconds", 120.0)
					level.customer_count = entry.get("customer_count", 8)
					level.target_money = entry.get("target_money", 100)
					level.target_happiness = entry.get("target_happiness", 0.7)
					var recipes: Array[String] = []
					for r in entry.get("available_recipes", []):
						recipes.append(String(r))
					level.available_recipes = recipes
					level.difficulty = entry.get("difficulty", 1)
					level.customer_type_weights = entry.get("customer_type_weights", {"NORMAL": 1.0})
					level.max_concurrent_orders = entry.get("max_concurrent_orders", 3)
					level.three_star_money = entry.get("three_star_money", 0)
					level.two_star_money = entry.get("two_star_money", 0)
					if not _levels_by_restaurant.has(level.restaurant_id):
						_levels_by_restaurant[level.restaurant_id] = []
					_levels_by_restaurant[level.restaurant_id].append(level)
		file_name = dir.get_next()
	for restaurant_id in _levels_by_restaurant.keys():
		_levels_by_restaurant[restaurant_id].sort_custom(
			func(a: LevelData, b: LevelData) -> bool: return a.level_id < b.level_id
		)

# ---------------------------------------------------------------------------
# Lookup API
# ---------------------------------------------------------------------------

func get_recipe(recipe_id: String) -> RecipeData:
	return _recipes.get(recipe_id, null)

func get_all_recipes() -> Dictionary:
	return _recipes

func get_customer_type(type_id: String) -> CustomerTypeData:
	var key := type_id.to_upper()
	return _customer_types.get(key, _customer_types.values()[0] if not _customer_types.is_empty() else null)

func get_ingredient(ingredient_id: String) -> IngredientData:
	return _ingredients.get(ingredient_id, null)

func get_restaurant(restaurant_id: String) -> RestaurantData:
	return _restaurants.get(restaurant_id, null)

func get_all_restaurants() -> Dictionary:
	return _restaurants

func get_levels_for_restaurant(restaurant_id: String) -> Array:
	return _levels_by_restaurant.get(restaurant_id, [])

func get_level(restaurant_id: String, level_id: int) -> LevelData:
	for level in get_levels_for_restaurant(restaurant_id):
		if level.level_id == level_id:
			return level
	return null

func is_level_unlocked(restaurant_id: String, level_id: int) -> bool:
	if level_id <= 1:
		return true
	# A level is unlocked once the previous one has at least 1 star.
	return GameManager.get_stars_for_level(restaurant_id, level_id - 1) >= 1

# ---------------------------------------------------------------------------
# Star rating
# ---------------------------------------------------------------------------

func calculate_stars(restaurant_id: String, level_id: int, money_earned: int, customers_served: int, best_combo: int) -> int:
	var level := get_level(restaurant_id, level_id)
	if level == null:
		return 1 if money_earned > 0 else 0

	var three_star_target: int = level.three_star_money if level.three_star_money > 0 else int(level.target_money * 2.0)
	var two_star_target: int = level.two_star_money if level.two_star_money > 0 else int(level.target_money * 1.5)

	if money_earned >= three_star_target:
		return 3
	elif money_earned >= two_star_target:
		return 2
	elif money_earned >= level.target_money:
		return 1
	return 0
