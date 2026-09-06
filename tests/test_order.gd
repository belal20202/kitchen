extends TestCase
## Tests for Order and OrderSystem: cooking progression, burning, and
## order lifecycle transitions.

func test_order_starts_waiting() -> void:
	var recipe := RecipeData.new()
	recipe.cooking_time = 5.0
	var order := Order.new(recipe)
	assert_eq(order.state, Order.OrderState.WAITING, "a new order should start in WAITING state")

func test_order_cooks_and_becomes_ready() -> void:
	var recipe := RecipeData.new()
	recipe.cooking_time = 5.0
	recipe.burn_grace_period = 3.0
	var order := Order.new(recipe)
	order.start_cooking()
	order.tick_cooking(5.5)
	assert_eq(order.state, Order.OrderState.READY, "order should be READY once cooking_time has elapsed")

func test_order_burns_after_grace_period() -> void:
	var recipe := RecipeData.new()
	recipe.cooking_time = 5.0
	recipe.burn_grace_period = 2.0
	var order := Order.new(recipe)
	order.start_cooking()
	order.tick_cooking(10.0)
	assert_eq(order.state, Order.OrderState.BURNED, "order should be BURNED after cooking_time + burn_grace_period")
	assert_eq(order.quality, 0.0, "a burned order should have zero quality")

func test_order_system_respects_max_concurrent_orders() -> void:
	var recipe := RecipeData.new()
	recipe.cooking_time = 5.0
	var system := OrderSystem.new()
	system.max_concurrent_orders = 2
	var o1 := system.create_order(recipe)
	var o2 := system.create_order(recipe)
	var o3 := system.create_order(recipe)
	assert_true(o1 != null, "first order should be accepted")
	assert_true(o2 != null, "second order should be accepted")
	assert_true(o3 == null, "third order should be rejected when at capacity")
	system.free()

func test_order_system_completion_removes_order() -> void:
	var recipe := RecipeData.new()
	var system := OrderSystem.new()
	var order := system.create_order(recipe)
	assert_eq(system.active_orders.size(), 1, "one order should be active")
	system.complete_order(order)
	assert_eq(system.active_orders.size(), 0, "completed orders should be removed from active_orders")
	assert_eq(order.state, Order.OrderState.SERVED, "completed order should be marked SERVED")
	system.free()
