extends TestCase
## Tests for LevelManager: level data loading, star-rating math, and
## the level-unlock rule.

func test_levels_loaded_for_burger_restaurant() -> void:
	var levels := LevelManager.get_levels_for_restaurant("burger_restaurant")
	assert_eq(levels.size(), 20, "burger_restaurant should have exactly 20 levels defined")

func test_level_1_is_always_unlocked() -> void:
	assert_true(LevelManager.is_level_unlocked("burger_restaurant", 1), "level 1 should always be unlocked")

func test_level_2_locked_until_level_1_has_a_star() -> void:
	var backup: int = GameManager.get_stars_for_level("burger_restaurant", 1)
	GameManager.level_stars.erase("burger_restaurant_1")
	assert_false(LevelManager.is_level_unlocked("burger_restaurant", 2), "level 2 should be locked with 0 stars on level 1")
	GameManager.level_stars["burger_restaurant_1"] = 1
	assert_true(LevelManager.is_level_unlocked("burger_restaurant", 2), "level 2 should unlock once level 1 has >= 1 star")
	if backup > 0:
		GameManager.level_stars["burger_restaurant_1"] = backup
	else:
		GameManager.level_stars.erase("burger_restaurant_1")

func test_star_calculation_thresholds() -> void:
	var level := LevelManager.get_level("burger_restaurant", 1)
	assert_true(level != null, "level 1 data should exist")
	var zero_stars := LevelManager.calculate_stars("burger_restaurant", 1, 0, 0, 0)
	var one_star := LevelManager.calculate_stars("burger_restaurant", 1, level.target_money, 5, 0)
	var three_stars := LevelManager.calculate_stars("burger_restaurant", 1, level.target_money * 3, 5, 5)
	assert_eq(zero_stars, 0, "earning nothing should give 0 stars")
	assert_eq(one_star, 1, "earning exactly the target should give at least 1 star")
	assert_eq(three_stars, 3, "earning well above target should give 3 stars")

func test_end_level_awards_coins_and_stars() -> void:
	var restaurant_id := "burger_restaurant"
	var level_id := 1
	var previous_coins: int = GameManager.coins
	var previous_stars: int = GameManager.get_stars_for_level(restaurant_id, level_id)

	GameManager.start_level(restaurant_id, level_id)
	var level := LevelManager.get_level(restaurant_id, level_id)
	GameManager.session_money_earned = level.target_money * 2
	GameManager.session_tips_earned = 10
	GameManager.session_customers_served = 5
	GameManager.session_best_combo = 3

	var result := GameManager.end_level(true)

	assert_true(result["success"], "end_level(true) should report success")
	assert_gt(result["stars"], 0, "a successful level should award at least 1 star")
	assert_eq(GameManager.coins, previous_coins + level.target_money * 2 + 10, "coins should increase by money + tips earned")

	# Restore star record so repeated test runs stay deterministic.
	if previous_stars > 0:
		GameManager.level_stars["%s_%d" % [restaurant_id, level_id]] = previous_stars
	else:
		GameManager.level_stars.erase("%s_%d" % [restaurant_id, level_id])
