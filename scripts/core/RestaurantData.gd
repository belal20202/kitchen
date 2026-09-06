extends Resource
class_name RestaurantData
## Data-driven definition of one of the five restaurants. Each
## restaurant has its own scene, recipe set, and unlock requirement.

@export var restaurant_id: String = ""
@export var display_name: String = ""
@export var scene_path: String = "" # res://scenes/restaurant/....tscn
@export var required_total_stars: int = 0 # Stars needed across all restaurants to unlock.
@export var background: Texture2D
@export var background_path: String = "" # res:// path; loaded into `background` at runtime by LevelManager.
@export var music_key: String = "" # Matches AudioManager._music_library key.
@export var recipe_ids: Array[String] = []
@export var equipment_ids: Array[String] = []
