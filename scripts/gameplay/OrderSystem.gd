extends Node
class_name OrderSystem
## Manages every active Order during a kitchen session: creation,
## per-frame cooking progression, burning, and completion/removal.
## Attach as a child node inside the Kitchen scene (not an autoload,
## since orders only exist while a level is being played).

signal order_added(order: Order)
signal order_ready(order: Order)
signal order_burned(order: Order)
signal order_completed(order: Order)

@export var max_concurrent_orders: int = 3

var active_orders: Array[Order] = []

func can_accept_new_order() -> bool:
	return active_orders.size() < max_concurrent_orders

func create_order(recipe: RecipeData) -> Order:
	if not can_accept_new_order():
		return null
	var order := Order.new(recipe)
	active_orders.append(order)
	order_added.emit(order)
	return order

func start_cooking(order: Order) -> void:
	order.start_cooking()

func _process(delta: float) -> void:
	for order in active_orders:
		if order.state == Order.OrderState.COOKING:
			var was_ready := order.state == Order.OrderState.READY
			order.tick_cooking(delta)
			if order.state == Order.OrderState.READY and not was_ready:
				order_ready.emit(order)
			elif order.state == Order.OrderState.BURNED:
				order_burned.emit(order)

func complete_order(order: Order) -> void:
	order.mark_served()
	active_orders.erase(order)
	order_completed.emit(order)

func cancel_order(order: Order) -> void:
	order.state = Order.OrderState.CANCELLED
	active_orders.erase(order)

func get_order_by_id(order_id: int) -> Order:
	for order in active_orders:
		if order.order_id == order_id:
			return order
	return null

func reset() -> void:
	active_orders.clear()
