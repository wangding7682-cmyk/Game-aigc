extends Node

signal purchase_succeeded(item_type: String, item_id: String, price_gold: int, price_diamond: int)
signal purchase_failed(item_type: String, item_id: String, reason: String)


func buy_weapon(weapon_id: String) -> bool:
	var weapon_config = WeaponManager.get_weapon_config(weapon_id)
	if not weapon_config:
		purchase_failed.emit("weapon", weapon_id, "武器不存在")
		return false

	if WeaponManager.is_weapon_unlocked(weapon_id):
		purchase_failed.emit("weapon", weapon_id, "武器已解锁")
		return false

	if weapon_config.price_gold > 0 and CoreGameState.player_gold < weapon_config.price_gold:
		purchase_failed.emit("weapon", weapon_id, "金币不足")
		return false

	if weapon_config.price_gold > 0:
		CoreGameState.player_gold -= weapon_config.price_gold

	var success = WeaponManager.unlock_weapon(weapon_id)
	if success:
		purchase_succeeded.emit("weapon", weapon_id, weapon_config.price_gold, 0)
		CoreEventBus.log_event("weapon_purchased", {
			"weapon_id": weapon_id,
			"price_gold": weapon_config.price_gold,
			"price_diamond": weapon_config.price_diamond,
		})
		PlatformService.save_game(CoreGameState.build_save_payload())
	else:
		purchase_failed.emit("weapon", weapon_id, "解锁失败")

	return success


func buy_skin(skin_id: String) -> bool:
	var skin_config = WeaponManager.get_skin_config(skin_id)
	if not skin_config:
		purchase_failed.emit("skin", skin_id, "皮肤不存在")
		return false

	if WeaponManager.is_skin_unlocked(skin_id):
		purchase_failed.emit("skin", skin_id, "皮肤已解锁")
		return false

	if not WeaponManager.is_weapon_unlocked(skin_config.weapon_id):
		purchase_failed.emit("skin", skin_id, "需要先解锁对应武器")
		return false

	if skin_config.price_gold > 0 and CoreGameState.player_gold < skin_config.price_gold:
		purchase_failed.emit("skin", skin_id, "金币不足")
		return false

	if skin_config.price_gold > 0:
		CoreGameState.player_gold -= skin_config.price_gold

	var success = WeaponManager.unlock_skin(skin_id)
	if success:
		purchase_succeeded.emit("skin", skin_id, skin_config.price_gold, 0)
		CoreEventBus.log_event("skin_purchased", {
			"skin_id": skin_id,
			"weapon_id": skin_config.weapon_id,
			"price_gold": skin_config.price_gold,
			"price_diamond": skin_config.price_diamond,
		})
		PlatformService.save_game(CoreGameState.build_save_payload())
	else:
		purchase_failed.emit("skin", skin_id, "解锁失败")

	return success


func can_buy_weapon(weapon_id: String) -> bool:
	var weapon_config = WeaponManager.get_weapon_config(weapon_id)
	if not weapon_config or WeaponManager.is_weapon_unlocked(weapon_id):
		return false
	return weapon_config.price_gold <= CoreGameState.player_gold


func can_buy_skin(skin_id: String) -> bool:
	var skin_config = WeaponManager.get_skin_config(skin_id)
	if not skin_config or WeaponManager.is_skin_unlocked(skin_id):
		return false
	if not WeaponManager.is_weapon_unlocked(skin_config.weapon_id):
		return false
	return skin_config.price_gold <= CoreGameState.player_gold


func get_weapon_price(weapon_id: String) -> Dictionary:
	var weapon_config = WeaponManager.get_weapon_config(weapon_id)
	if not weapon_config:
		return {"gold": 0, "diamond": 0}
	return {"gold": weapon_config.price_gold, "diamond": weapon_config.price_diamond}


func get_skin_price(skin_id: String) -> Dictionary:
	var skin_config = WeaponManager.get_skin_config(skin_id)
	if not skin_config:
		return {"gold": 0, "diamond": 0}
	return {"gold": skin_config.price_gold, "diamond": skin_config.price_diamond}
