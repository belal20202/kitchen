extends Control
## Lets the player hire Chef/Waiter/Cashier employees and upgrade them.
## Uses an EmployeeManager instance (not an autoload) since it's only
## needed while this menu is open.

@onready var list_container: VBoxContainer = %ListContainer
@onready var coins_label: Label = %CoinsLabel

var _employee_manager: EmployeeManager

func _ready() -> void:
	_employee_manager = EmployeeManager.new()
	add_child(_employee_manager)
	_refresh()
	EconomyManager.coins_changed.connect(func(_v): _refresh())

func _refresh() -> void:
	coins_label.text = "🪙 %d" % GameManager.coins
	for child in list_container.get_children():
		child.queue_free()

	for employee_id in _employee_manager.get_all_employees().keys():
		var data: EmployeeData = _employee_manager.get_employee_data(employee_id)
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 64)

		var info_box := VBoxContainer.new()
		info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name_label := Label.new()
		var is_hired := _employee_manager.is_hired(employee_id)
		var level: int = GameManager.employee_levels.get(employee_id, 0)
		name_label.text = "%s%s" % [data.display_name, (" (Lv. %d/%d)" % [level, data.max_level]) if is_hired else " (Not Hired)"]
		var effect_label := Label.new()
		effect_label.text = "Speed Bonus: +%d%%" % int(round(data.get_speed_bonus(max(level, 1)) * 100))
		info_box.add_child(name_label)
		info_box.add_child(effect_label)
		row.add_child(info_box)

		var button := Button.new()
		if not is_hired:
			button.text = "Hire\n🪙 %d" % data.hire_cost
			button.disabled = not EconomyManager.can_afford_coins(data.hire_cost)
			button.pressed.connect(_on_hire_pressed.bind(employee_id))
		elif level >= data.max_level:
			button.text = "MAX"
			button.disabled = true
		else:
			var upgrade_cost: int = int(round(data.hire_cost * 0.5 * level))
			button.text = "Upgrade\n🪙 %d" % upgrade_cost
			button.disabled = not EconomyManager.can_afford_coins(upgrade_cost)
			button.pressed.connect(_on_upgrade_pressed.bind(employee_id))
		row.add_child(button)

		list_container.add_child(row)

func _on_hire_pressed(employee_id: String) -> void:
	if _employee_manager.hire(employee_id):
		AudioManager.play_sfx("ui_confirm")
		SaveManager.save_game()
		_refresh()

func _on_upgrade_pressed(employee_id: String) -> void:
	if _employee_manager.upgrade(employee_id):
		AudioManager.play_sfx("ui_confirm")
		SaveManager.save_game()
		_refresh()

func _on_back_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")
