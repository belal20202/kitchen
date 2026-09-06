extends Node
## SaveManager
## Handles all local save/load logic in a single, versioned JSON file.
## Designed to be easily extended with new fields in the future without
## breaking older save files (missing keys fall back to sane defaults).

const SAVE_PATH := "user://savegame.json"
const SAVE_VERSION := 1

signal save_completed
signal load_completed

func save_game() -> bool:
	var data := {
		"save_version": SAVE_VERSION,
		"player_level": GameManager.player_level,
		"coins": GameManager.coins,
		"gems": GameManager.gems,
		"unlocked_restaurants": GameManager.unlocked_restaurants,
		"unlocked_recipes": GameManager.unlocked_recipes,
		"equipment_levels": GameManager.equipment_levels,
		"employee_levels": GameManager.employee_levels,
		"achievements_unlocked": GameManager.achievements_unlocked,
		"level_stars": GameManager.level_stars,
		"tutorial_completed": GameManager.tutorial_completed,
		"settings": {
			"music_enabled": AudioManager.music_enabled,
			"sfx_enabled": AudioManager.sfx_enabled,
			"music_volume": AudioManager.music_volume,
			"sfx_volume": AudioManager.sfx_volume,
		}
	}

	var json_string := JSON.stringify(data, "\t")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: failed to open save file for writing.")
		return false
	file.store_string(json_string)
	file.close()
	save_completed.emit()
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveManager: failed to open save file for reading.")
		return false

	var content := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_result := json.parse(content)
	if parse_result != OK:
		push_error("SaveManager: save file is corrupted, ignoring.")
		return false

	var data: Dictionary = json.data
	apply_save_data(data)
	load_completed.emit()
	return true

func apply_save_data(data: Dictionary) -> void:
	GameManager.player_level = data.get("player_level", 1)
	GameManager.coins = data.get("coins", 0)
	GameManager.gems = data.get("gems", 0)
	GameManager.unlocked_restaurants = data.get("unlocked_restaurants", ["burger_restaurant"])
	GameManager.unlocked_recipes = data.get("unlocked_recipes", ["burger", "french_fries", "juice", "coffee"])
	GameManager.equipment_levels = data.get("equipment_levels", {})
	GameManager.employee_levels = data.get("employee_levels", {})
	GameManager.achievements_unlocked = data.get("achievements_unlocked", [])
	GameManager.level_stars = data.get("level_stars", {})
	GameManager.tutorial_completed = data.get("tutorial_completed", false)

	var settings: Dictionary = data.get("settings", {})
	AudioManager.music_enabled = settings.get("music_enabled", true)
	AudioManager.sfx_enabled = settings.get("sfx_enabled", true)
	AudioManager.music_volume = settings.get("music_volume", 0.8)
	AudioManager.sfx_volume = settings.get("sfx_volume", 1.0)
	AudioManager.apply_settings()

func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	GameManager.reset_progress()
