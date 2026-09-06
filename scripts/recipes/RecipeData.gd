extends Resource
class_name RecipeData
## Data-driven definition of a single recipe. Instances are stored as
## .tres resource files under res://data/recipes/ so designers can add
## or tweak recipes without touching code.

@export var recipe_id: String = ""
@export var recipe_name: String = ""
@export var ingredients: Array[String] = [] # Ingredient IDs, in required order.
@export var equipment_required: String = "" # Equipment ID needed to cook this, e.g. "grill".
@export var price: int = 10
@export var preparation_time: float = 3.0 # Seconds to assemble/chop ingredients.
@export var cooking_time: float = 8.0 # Seconds on the equipment.
@export var unlock_level: int = 1 # Player level required to unlock this recipe.
@export var icon: Texture2D
@export var icon_path: String = "" # res:// path; loaded into `icon` at runtime by LevelManager.
@export var burn_grace_period: float = 4.0 # Extra seconds after cooking_time before it burns.

func get_total_time() -> float:
	return preparation_time + cooking_time
