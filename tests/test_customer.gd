extends TestCase
## Tests for Customer: patience decay, happiness, and payment/tip math.

func _make_recipe(price: int) -> RecipeData:
	var recipe := RecipeData.new()
	recipe.recipe_id = "test_recipe"
	recipe.price = price
	recipe.cooking_time = 5.0
	return recipe

func test_customer_setup_creates_orders() -> void:
	var type_data := CustomerTypeData.new()
	type_data.order_size = 2
	type_data.base_patience_seconds = 30.0
	var customer := Customer.new()
	var recipes: Array[RecipeData] = [_make_recipe(10)]
	customer.setup(type_data, recipes)
	assert_eq(customer.orders.size(), 2, "customer with order_size 2 should have 2 orders")
	customer.free()

func test_patience_decays_over_time() -> void:
	var type_data := CustomerTypeData.new()
	type_data.base_patience_seconds = 20.0
	type_data.patience_decay_multiplier = 1.0
	var customer := Customer.new()
	customer.setup(type_data, [_make_recipe(10)])
	customer.set_process(false) # avoid double-ticking from _process during the test
	customer.tick(5.0)
	assert_almost_eq(customer.patience_remaining, 15.0, 0.01, "patience should decay by elapsed time * multiplier")
	customer.free()

func test_patience_depleted_signal_fires() -> void:
	var type_data := CustomerTypeData.new()
	type_data.base_patience_seconds = 5.0
	var customer := Customer.new()
	customer.setup(type_data, [_make_recipe(10)])
	customer.set_process(false)
	var signal_fired := false
	customer.patience_depleted.connect(func(_c): signal_fired = true)
	customer.tick(6.0)
	assert_true(signal_fired, "patience_depleted should fire once patience reaches 0")
	customer.free()

func test_payment_and_tip_calculation() -> void:
	var type_data := CustomerTypeData.new()
	type_data.base_patience_seconds = 60.0
	type_data.payment_multiplier = 1.0
	type_data.tip_multiplier = 1.0
	var customer := Customer.new()
	var recipe := _make_recipe(20)
	customer.setup(type_data, [recipe])
	customer.orders[0].quality = 1.0
	customer.orders[0].mark_served()
	customer.waiting_time = 5.0
	customer.set_happiness(1.0)
	customer.calculate_payment_and_tip()
	assert_eq(customer.payment, 20, "payment should equal recipe price at full quality and multiplier 1.0")
	assert_true(customer.tip >= 0, "tip should never be negative")
	customer.free()
