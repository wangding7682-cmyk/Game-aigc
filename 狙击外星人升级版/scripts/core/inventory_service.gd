extends Node

var item_stock: Dictionary = {
	"scan_radar": 3,
	"freeze_bomb": 2,
	"precision_locator": 2,
	"time_extend": 1,
	"range_scan": 3,
}


func get_item_count(item_id: String) -> int:
	return int(item_stock.get(item_id, 0))


func add_item(item_id: String, count: int = 1) -> void:
	if item_id not in item_stock:
		item_stock[item_id] = 0
	item_stock[item_id] += count
	CoreEventBus.log_event("item_added", {
		"item_id": item_id,
		"count": count,
	})


func consume_item(item_id: String, count: int = 1) -> bool:
	if get_item_count(item_id) < count:
		return false
	item_stock[item_id] -= count
	CoreEventBus.log_event("item_consumed", {
		"item_id": item_id,
		"count": count,
	})
	return true


func buy_item(item_id: String, price_gold: int, count: int = 1) -> bool:
	if CoreGameState.player_gold < price_gold * count:
		return false

	CoreGameState.player_gold -= price_gold * count
	add_item(item_id, count)
	CoreEventBus.log_event("item_purchased", {
		"item_id": item_id,
		"price_gold": price_gold,
		"count": count,
	})
	return true


func build_save_payload() -> Dictionary:
	return {
		"item_stock": item_stock.duplicate(true),
	}


func restore_from_payload(payload: Dictionary) -> void:
	if payload.has("item_stock"):
		item_stock = payload.get("item_stock", {}).duplicate(true)
