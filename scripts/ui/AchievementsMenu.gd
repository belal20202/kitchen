extends Control
## Displays every AchievementData entry (achievements, daily missions,
## weekly missions) with progress and unlocked state. Uses an
## AchievementManager instance owned by this scene.

@onready var list_container: VBoxContainer = %ListContainer

var _achievement_manager: AchievementManager

func _ready() -> void:
	_achievement_manager = AchievementManager.new()
	add_child(_achievement_manager)
	_refresh()

func _refresh() -> void:
	for child in list_container.get_children():
		child.queue_free()

	for mission in _achievement_manager.get_all_missions():
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 56)

		var info_box := VBoxContainer.new()
		info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var kind_prefix := ["", "Daily: ", "Weekly: "][mission.kind]
		var name_label := Label.new()
		name_label.text = "%s%s" % [kind_prefix, mission.display_name]
		var desc_label := Label.new()
		desc_label.text = mission.description
		info_box.add_child(name_label)
		info_box.add_child(desc_label)
		row.add_child(info_box)

		var status_label := Label.new()
		var is_done := _achievement_manager.is_completed(mission.mission_id)
		status_label.text = "✅" if is_done else "🪙%d" % mission.reward_coins
		row.add_child(status_label)

		list_container.add_child(row)

func _on_back_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")
