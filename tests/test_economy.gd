extends TestCase
## Tests for EconomyManager: coins/gems transactions and tip/combo math.

func test_add_and_spend_coins() -> void:
	var starting: int = GameManager.coins
	EconomyManager.add_coins(100)
	assert_eq(GameManager.coins, starting + 100, "add_coins should increase balance")

	var spent := EconomyManager.spend_coins(50)
	assert_true(spent, "spend_coins should succeed when affordable")
	assert_eq(GameManager.coins, starting + 50, "spend_coins should decrease balance by amount")

func test_cannot_overspend_coins() -> void:
	GameManager.coins = 10
	var spent := EconomyManager.spend_coins(1000)
	assert_false(spent, "spend_coins should fail when insufficient funds")
	assert_eq(GameManager.coins, 10, "balance should be unchanged after a failed spend")

func test_tip_calculation_scales_with_happiness() -> void:
	var low_tip := EconomyManager.calculate_tip(100, 0.1, 0.5, 0.5)
	var high_tip := EconomyManager.calculate_tip(100, 1.0, 1.0, 1.0)
	assert_gt(high_tip, low_tip, "higher happiness/speed/quality should yield a higher tip")

func test_combo_multiplier_increases_with_combo_count() -> void:
	var m1 := EconomyManager.get_combo_multiplier(1)
	var m5 := EconomyManager.get_combo_multiplier(5)
	var m10 := EconomyManager.get_combo_multiplier(10)
	assert_eq(m1, 1.0, "combo x1 should have no bonus")
	assert_gt(m5, m1, "combo x5 should be better than x1")
	assert_gt(m10, m5, "combo x10 should be better than x5")
