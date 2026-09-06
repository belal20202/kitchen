extends Node
class_name CustomerSpawner
## Spawns Customer instances over time according to the active LevelData:
## total customer_count, weighted random type selection, and simple
## pacing so customers don't all arrive at once.

signal customer_spawned(customer: Customer)

@export var customer_scene: PackedScene
@export var spawn_point: Node2D

var _level: LevelData
var _available_recipes: Array[RecipeData] = []
var _spawned_count: int = 0
var _time_until_next_spawn: float = 0.0
var _rng := RandomNumberGenerator.new()
var _active: bool = false

func start(level: LevelData) -> void:
	_level = level
	_available_recipes.clear()
	for recipe_id in level.available_recipes:
		var recipe := LevelManager.get_recipe(recipe_id)
		if recipe:
			_available_recipes.append(recipe)
	_spawned_count = 0
	_rng.randomize()
	_time_until_next_spawn = 1.0
	_active = true

func stop() -> void:
	_active = false

func _process(delta: float) -> void:
	if not _active or _level == null:
		return
	if _spawned_count >= _level.customer_count:
		_active = false
		return
	_time_until_next_spawn -= delta
	if _time_until_next_spawn <= 0.0:
		_spawn_customer()
		var pacing: float = _level.time_limit_seconds / float(max(_level.customer_count, 1))
		_time_until_next_spawn = max(pacing * 0.6, 2.0)

func _spawn_customer() -> void:
	var type_id: String = _pick_weighted_type()
	var type_data := LevelManager.get_customer_type(type_id)

	var customer: Customer
	if customer_scene:
		customer = customer_scene.instantiate()
	else:
		customer = Customer.new()

	if spawn_point:
		add_sibling_if_needed(customer)
		customer.global_position = spawn_point.global_position
	else:
		get_parent().add_child(customer)

	customer.setup(type_data, _available_recipes, _rng)
	_spawned_count += 1
	customer_spawned.emit(customer)

func add_sibling_if_needed(node: Node) -> void:
	if node.get_parent() == null:
		get_parent().add_child(node)

func _pick_weighted_type() -> String:
	var weights: Dictionary = _level.customer_type_weights
	if weights.is_empty():
		return "normal"
	var total := 0.0
	for key in weights.keys():
		total += float(weights[key])
	var roll: float = _rng.randf_range(0.0, total)
	var cumulative := 0.0
	for key in weights.keys():
		cumulative += float(weights[key])
		if roll <= cumulative:
			return key
	return weights.keys()[0]

func has_finished_spawning() -> bool:
	return _spawned_count >= (_level.customer_count if _level else 0)
