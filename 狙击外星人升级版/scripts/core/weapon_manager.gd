extends Node

const WEAPON_CONFIG_PATHS: Dictionary = {
	"default_sniper": "res://configs/weapon/cfg_weapon_default.tres",
	"precision_sniper": "res://configs/weapon/cfg_weapon_precision.tres",
	"auto_sniper": "res://configs/weapon/cfg_weapon_auto.tres",
	"plasma_sniper": "res://configs/weapon/cfg_weapon_plasma.tres",
}

const SKIN_CONFIG_PATHS: Dictionary = {
	"skin_default": "res://configs/skin/cfg_skin_default.tres",
	"skin_precision": "res://configs/skin/cfg_skin_precision.tres",
	"skin_auto": "res://configs/skin/cfg_skin_auto.tres",
	"skin_plasma": "res://configs/skin/cfg_skin_plasma.tres",
	"skin_rainbow_trail": "res://configs/skin/cfg_skin_rainbow_trail.tres",
}

var _weapon_configs: Dictionary = {}
var _skin_configs: Dictionary = {}

var unlocked_weapons: Array[String] = ["default_sniper"]
var unlocked_skins: Array[String] = ["skin_default"]
var equipped_weapon_id: String = "default_sniper"
var equipped_skin_ids: Dictionary = {"default_sniper": "skin_default"}


func _ready() -> void:
	_load_all_configs()


func _load_all_configs() -> void:
	for weapon_id in WEAPON_CONFIG_PATHS:
		var config: Resource = load(WEAPON_CONFIG_PATHS[weapon_id])
		if config:
			_weapon_configs[weapon_id] = config
			if config.has_method("is_default") and config.is_default and weapon_id not in unlocked_weapons:
				unlocked_weapons.append(weapon_id)

	for skin_id in SKIN_CONFIG_PATHS:
		var config: Resource = load(SKIN_CONFIG_PATHS[skin_id])
		if config:
			_skin_configs[skin_id] = config
			if config.has_method("price_gold") and config.price_gold == 0 and skin_id not in unlocked_skins:
				unlocked_skins.append(skin_id)


func get_weapon_config(weapon_id: String) -> Resource:
	return _weapon_configs.get(weapon_id, null)


func get_skin_config(skin_id: String) -> Resource:
	return _skin_configs.get(skin_id, null)


func get_all_weapon_configs() -> Array[Resource]:
	return _weapon_configs.values()


func get_all_skin_configs() -> Array[Resource]:
	return _skin_configs.values()


func get_unlocked_weapons() -> Array[Resource]:
	var result: Array[Resource] = []
	for weapon_id in unlocked_weapons:
		var config = get_weapon_config(weapon_id)
		if config:
			result.append(config)
	return result


func get_unlocked_skins(weapon_id: String = "") -> Array[Resource]:
	var result: Array[Resource] = []
	for skin_id in unlocked_skins:
		var config = get_skin_config(skin_id)
		if config and (weapon_id.is_empty() or config.weapon_id == weapon_id):
			result.append(config)
	return result


func is_weapon_unlocked(weapon_id: String) -> bool:
	return weapon_id in unlocked_weapons


func is_skin_unlocked(skin_id: String) -> bool:
	return skin_id in unlocked_skins


func unlock_weapon(weapon_id: String) -> bool:
	if weapon_id in unlocked_weapons:
		return false
	if weapon_id not in _weapon_configs:
		return false

	unlocked_weapons.append(weapon_id)
	CoreEventBus.log_event("weapon_unlocked", {
		"weapon_id": weapon_id,
		"display_name": _weapon_configs[weapon_id].display_name,
	})
	return true


func unlock_skin(skin_id: String) -> bool:
	if skin_id in unlocked_skins:
		return false
	if skin_id not in _skin_configs:
		return false

	unlocked_skins.append(skin_id)
	CoreEventBus.log_event("skin_unlocked", {
		"skin_id": skin_id,
		"display_name": _skin_configs[skin_id].display_name,
	})
	return true


func equip_weapon(weapon_id: String) -> bool:
	if not is_weapon_unlocked(weapon_id):
		return false

	equipped_weapon_id = weapon_id
	CoreEventBus.weapon_equipped.emit(weapon_id)
	CoreEventBus.log_event("weapon_equipped", {
		"weapon_id": weapon_id,
	})
	return true


func equip_skin(weapon_id: String, skin_id: String) -> bool:
	if not is_weapon_unlocked(weapon_id):
		return false
	if not is_skin_unlocked(skin_id):
		return false

	var skin_config = get_skin_config(skin_id)
	if skin_config and skin_config.weapon_id != weapon_id:
		return false

	equipped_skin_ids[weapon_id] = skin_id
	CoreEventBus.skin_equipped.emit(weapon_id, skin_id)
	CoreEventBus.log_event("skin_equipped", {
		"weapon_id": weapon_id,
		"skin_id": skin_id,
	})
	return true


func get_equipped_weapon() -> Resource:
	return get_weapon_config(equipped_weapon_id)


func get_equipped_skin(weapon_id: String = "") -> Resource:
	var target_weapon_id = weapon_id if not weapon_id.is_empty() else equipped_weapon_id
	var skin_id = equipped_skin_ids.get(target_weapon_id, "")
	return get_skin_config(skin_id)


func get_equipped_weapon_profile() -> Dictionary:
	var weapon_config = get_equipped_weapon()
	if not weapon_config:
		return {}

	var skin_config = get_equipped_skin(equipped_weapon_id)
	var profile = weapon_config.get_profile()
	profile["geometry_type"] = weapon_config.geometry_type
	if skin_config:
		profile["primary_color"] = skin_config.primary_color
		profile["secondary_color"] = skin_config.secondary_color
		profile["accent_color"] = skin_config.accent_color
		profile["glow_color"] = skin_config.glow_color
		profile["has_glow"] = skin_config.has_glow
		profile["glow_intensity"] = skin_config.glow_intensity
	else:
		profile["primary_color"] = weapon_config.primary_color
		profile["secondary_color"] = weapon_config.secondary_color
		profile["accent_color"] = weapon_config.primary_color
		profile["glow_color"] = Color(0.0, 0.0, 0.0)
		profile["has_glow"] = false
		profile["glow_intensity"] = 0.0

	return profile


func switch_to_next_weapon() -> String:
	var unlocked = get_unlocked_weapons()
	if unlocked.size() <= 1:
		return equipped_weapon_id

	var current_index = unlocked.find(get_equipped_weapon())
	var next_index = (current_index + 1) % unlocked.size()
	var next_weapon = unlocked[next_index]

	equip_weapon(next_weapon.weapon_id)
	return next_weapon.weapon_id


func switch_to_previous_weapon() -> String:
	var unlocked = get_unlocked_weapons()
	if unlocked.size() <= 1:
		return equipped_weapon_id

	var current_index = unlocked.find(get_equipped_weapon())
	var prev_index = (current_index - 1 + unlocked.size()) % unlocked.size()
	var prev_weapon = unlocked[prev_index]

	equip_weapon(prev_weapon.weapon_id)
	return prev_weapon.weapon_id


func build_save_payload() -> Dictionary:
	return {
		"unlocked_weapons": unlocked_weapons.duplicate(),
		"unlocked_skins": unlocked_skins.duplicate(),
		"equipped_weapon_id": equipped_weapon_id,
		"equipped_skin_ids": equipped_skin_ids.duplicate(true),
	}


func _restore_string_array(value: Variant, fallback: Array[String]) -> Array[String]:
	var restored: Array[String] = []
	if value is Array:
		for entry in value:
			restored.append(str(entry))

	if restored.is_empty():
		return fallback.duplicate()
	return restored


func restore_from_payload(payload: Dictionary) -> void:
	if payload.has("unlocked_weapons"):
		unlocked_weapons = _restore_string_array(payload.get("unlocked_weapons", []), ["default_sniper"])

	if payload.has("unlocked_skins"):
		unlocked_skins = _restore_string_array(payload.get("unlocked_skins", []), ["skin_default"])

	if payload.has("equipped_weapon_id"):
		var new_weapon_id = str(payload.get("equipped_weapon_id", "default_sniper"))
		if is_weapon_unlocked(new_weapon_id):
			equipped_weapon_id = new_weapon_id

	if payload.has("equipped_skin_ids"):
		equipped_skin_ids = payload.get("equipped_skin_ids", {}).duplicate(true)
