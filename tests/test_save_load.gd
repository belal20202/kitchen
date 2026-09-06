extends TestCase
## Tests for SaveManager: saving and loading round-trips player progress
## correctly. Uses the real user:// save path (test-safe since CI runs
## in a throwaway container), and restores original state afterward.

var _backup: Dictionary = {}

func _backup_state() -> void:
	_backup = {
		"coins": GameManager.coins,
		"gems": GameManager.gems,
		"unlocked_restaurants": GameManager.unlocked_restaurants.duplicate(),
		"level_stars": GameManager.level_stars.duplicate(),
	}

func _restore_state() -> void:
	GameManager.coins = _backup["coins"]
	GameManager.gems = _backup["gems"]
	GameManager.unlocked_restaurants = _backup["unlocked_restaurants"]
	GameManager.level_stars = _backup["level_stars"]

func test_save_and_load_round_trip() -> void:
	_backup_state()

	GameManager.coins = 777
	GameManager.gems = 33
	GameManager.unlocked_restaurants = ["burger_restaurant", "pizza_restaurant"]
	GameManager.level_stars = {"burger_restaurant_1": 3}

	var saved := SaveManager.save_game()
	assert_true(saved, "save_game should succeed")

	# Simulate a fresh session by clearing in-memory state before loading.
	GameManager.coins = 0
	GameManager.gems = 0
	GameManager.unlocked_restaurants = []
	GameManager.level_stars = {}

	var loaded := SaveManager.load_game()
	assert_true(loaded, "load_game should succeed")
	assert_eq(GameManager.coins, 777, "loaded coins should match saved coins")
	assert_eq(GameManager.gems, 33, "loaded gems should match saved gems")
	assert_true(GameManager.unlocked_restaurants.has("pizza_restaurant"), "loaded restaurants should include pizza_restaurant")
	assert_eq(GameManager.level_stars.get("burger_restaurant_1", 0), 3, "loaded level_stars should be preserved")

	_restore_state()
	SaveManager.save_game()

func test_load_progress_restores_after_reset() -> void:
	_backup_state()

	GameManager.coins = 500
	SaveManager.save_game()
	GameManager.reset_progress()
	assert_eq(GameManager.coins, 0, "reset_progress should zero out coins")

	SaveManager.load_game()
	assert_eq(GameManager.coins, 500, "loading the game after a reset should restore the previously saved coins")

	_restore_state()
	SaveManager.save_game()
