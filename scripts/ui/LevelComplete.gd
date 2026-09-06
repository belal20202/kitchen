extends Control
## Shown right after a level ends. Reads the last session results that
## GameManager still holds (session_* fields) plus the stars that were
## just calculated and stored in GameManager.level_stars.

@onready var stars_label: Label = %StarsLabel
@onready var result_label: Label = %ResultLabel
@onready var money_label: Label = %MoneyLabel
@onready var tips_label: Label = %TipsLabel
@onready var customers_label: Label = %CustomersLabel
@onready var combo_label: Label = %ComboLabel

func _ready() -> void:
	var stars := GameManager.get_stars_for_level(GameManager.current_restaurant_id, GameManager.current_level_id)
	var success: bool = (GameManager.session_money_earned + GameManager.session_tips_earned) >= 0 and stars > 0

	result_label.text = "Level Complete!" if stars > 0 else "Try Again!"
	stars_label.text = "★".repeat(stars) + "☆".repeat(3 - stars)
	money_label.text = "Money Earned: $%d" % GameManager.session_money_earned
	tips_label.text = "Tips: $%d" % GameManager.session_tips_earned
	customers_label.text = "Customers Served: %d" % GameManager.session_customers_served
	combo_label.text = "Best Combo: x%d" % GameManager.session_best_combo

	if stars > 0:
		AudioManager.play_sfx("star_earned")

func _on_continue_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	get_tree().change_scene_to_file("res://scenes/menus/LevelSelect.tscn")

func _on_retry_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	get_tree().change_scene_to_file("res://scenes/kitchen/Kitchen.tscn")

func _on_menu_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")
