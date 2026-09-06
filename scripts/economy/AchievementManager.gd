extends Node
class_name AchievementManager
## Tracks lifetime + daily/weekly counters and unlocks AchievementData
## entries once their target is reached. Instantiated inside the
## Achievements menu scene; persists its counters via GameManager so
## SaveManager picks them up automatically (stored inside achievements
## metadata dictionary for simplicity).

signal mission_completed(mission: AchievementData)

var _catalog: Array[AchievementData] = []
var counters: Dictionary = {} # metric name (String) -> int

const ACHIEVEMENTS_JSON := "res://data/upgrades/achievements.json"

func _ready() -> void:
	_load_catalog()

func _load_catalog() -> void:
	_catalog.clear()
	if not FileAccess.file_exists(ACHIEVEMENTS_JSON):
		push_warning("AchievementManager: missing %s" % ACHIEVEMENTS_JSON)
		return
	var file := FileAccess.open(ACHIEVEMENTS_JSON, FileAccess.READ)
	var content := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(content) != OK:
		push_error("AchievementManager: failed to parse %s" % ACHIEVEMENTS_JSON)
		return
	var kind_map := {
		"ACHIEVEMENT": AchievementData.MissionKind.ACHIEVEMENT,
		"DAILY": AchievementData.MissionKind.DAILY,
		"WEEKLY": AchievementData.MissionKind.WEEKLY,
	}
	var metric_map := {
		"CUSTOMERS_SERVED": AchievementData.MetricType.CUSTOMERS_SERVED,
		"COINS_EARNED": AchievementData.MetricType.COINS_EARNED,
		"RECIPE_MADE": AchievementData.MetricType.RECIPE_MADE,
		"STARS_EARNED": AchievementData.MetricType.STARS_EARNED,
		"COMBO_REACHED": AchievementData.MetricType.COMBO_REACHED,
	}
	for entry in json.data:
		var data := AchievementData.new()
		data.mission_id = entry.get("mission_id", "")
		data.display_name = entry.get("display_name", "")
		data.description = entry.get("description", "")
		data.kind = kind_map.get(entry.get("kind", "ACHIEVEMENT"), AchievementData.MissionKind.ACHIEVEMENT)
		data.metric = metric_map.get(entry.get("metric", "CUSTOMERS_SERVED"), AchievementData.MetricType.CUSTOMERS_SERVED)
		data.target_value = entry.get("target_value", 20)
		data.recipe_filter = entry.get("recipe_filter", "")
		data.reward_coins = entry.get("reward_coins", 50)
		data.reward_gems = entry.get("reward_gems", 0)
		_catalog.append(data)

func get_all_missions() -> Array[AchievementData]:
	return _catalog

func register_progress(metric_name: String, amount: int = 1) -> void:
	counters[metric_name] = counters.get(metric_name, 0) + amount
	_check_completions(metric_name)

func _check_completions(metric_name: String) -> void:
	for mission in _catalog:
		if AchievementData.MetricType.keys()[mission.metric] != metric_name:
			continue
		if GameManager.achievements_unlocked.has(mission.mission_id):
			continue
		if counters.get(metric_name, 0) >= mission.target_value:
			_complete_mission(mission)

func _complete_mission(mission: AchievementData) -> void:
	GameManager.unlock_achievement(mission.mission_id)
	EconomyManager.add_coins(mission.reward_coins)
	if mission.reward_gems > 0:
		EconomyManager.add_gems(mission.reward_gems)
	mission_completed.emit(mission)

func is_completed(mission_id: String) -> bool:
	return GameManager.achievements_unlocked.has(mission_id)
