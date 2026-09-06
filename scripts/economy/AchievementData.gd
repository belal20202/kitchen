extends Resource
class_name AchievementData
## Data-driven definition of a single achievement / daily / weekly mission.

enum MissionKind { ACHIEVEMENT, DAILY, WEEKLY }
enum MetricType { CUSTOMERS_SERVED, COINS_EARNED, RECIPE_MADE, STARS_EARNED, COMBO_REACHED }

@export var mission_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var kind: MissionKind = MissionKind.ACHIEVEMENT
@export var metric: MetricType = MetricType.CUSTOMERS_SERVED
@export var target_value: int = 20
@export var recipe_filter: String = "" # Used only when metric == RECIPE_MADE.
@export var reward_coins: int = 50
@export var reward_gems: int = 0
