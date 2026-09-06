extends Resource
class_name IngredientData
## Data-driven definition of a raw ingredient used by recipes.

@export var ingredient_id: String = ""
@export var ingredient_name: String = ""
@export var icon: Texture2D
@export var icon_path: String = "" # res:// path; loaded into `icon` at runtime by LevelManager.
@export var requires_prep: bool = false # e.g. must be chopped before use.
@export var prep_time: float = 1.0
@export var restock_cost: int = 2 # Coins cost to restock this ingredient in inventory.
