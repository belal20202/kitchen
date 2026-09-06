extends Node
## EconomyManager
## Single source of truth for every Coins/Gems transaction so the game
## is never Pay-to-Win: Gems only ever buy convenience or cosmetics,
## never gameplay power that Coins cannot also eventually buy.

signal coins_changed(new_amount: int)
signal gems_changed(new_amount: int)
signal transaction_failed(reason: String)

func get_coins() -> int:
	return GameManager.coins

func get_gems() -> int:
	return GameManager.gems

func add_coins(amount: int) -> void:
	if amount <= 0:
		return
	GameManager.coins += amount
	coins_changed.emit(GameManager.coins)

func add_gems(amount: int) -> void:
	if amount <= 0:
		return
	GameManager.gems += amount
	gems_changed.emit(GameManager.gems)

func can_afford_coins(amount: int) -> bool:
	return GameManager.coins >= amount

func can_afford_gems(amount: int) -> bool:
	return GameManager.gems >= amount

## Attempts to spend coins. Returns true and deducts on success.
func spend_coins(amount: int) -> bool:
	if amount <= 0:
		return true
	if not can_afford_coins(amount):
		transaction_failed.emit("insufficient_coins")
		return false
	GameManager.coins -= amount
	coins_changed.emit(GameManager.coins)
	return true

## Attempts to spend gems. Returns true and deducts on success.
func spend_gems(amount: int) -> bool:
	if amount <= 0:
		return true
	if not can_afford_gems(amount):
		transaction_failed.emit("insufficient_gems")
		return false
	GameManager.gems -= amount
	gems_changed.emit(GameManager.gems)
	return true

## Calculates tip based on happiness (0-1), service speed (0-1) and
## order quality (0-1). Returns an integer tip amount relative to the
## order's base price.
func calculate_tip(base_price: int, happiness: float, service_speed: float, order_quality: float) -> int:
	var factor: float = clampf((happiness * 0.5) + (service_speed * 0.25) + (order_quality * 0.25), 0.0, 1.0)
	if factor < 0.2:
		return 0
	return int(round(base_price * factor * 0.5))

## Calculates a combo multiplier applied to tips/rewards.
## combo_count: how many orders served back-to-back within the combo window.
func get_combo_multiplier(combo_count: int) -> float:
	if combo_count >= 10:
		return 2.5
	elif combo_count >= 5:
		return 2.0
	elif combo_count >= 4:
		return 1.75
	elif combo_count >= 3:
		return 1.5
	elif combo_count >= 2:
		return 1.25
	return 1.0
