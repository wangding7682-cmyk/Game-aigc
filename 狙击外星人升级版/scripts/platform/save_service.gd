extends Node


const SAVE_DIR := "user://saves"
const SAVE_FILE_PREFIX := "save_slot_"
const SAVE_FILE_SUFFIX := ".json"
const MAX_SLOTS := 3


func _get_save_path(slot_index: int) -> String:
	return "%s/%s%d%s" % [SAVE_DIR, SAVE_FILE_PREFIX, slot_index, SAVE_FILE_SUFFIX]


func save_profile(payload: Dictionary) -> bool:
	return save_to_slot(payload, 1)


func load_profile() -> Dictionary:
	return load_from_slot(1)


func clear_profile() -> void:
	clear_slot(1)


func save_to_slot(payload: Dictionary, slot_index: int) -> bool:
	if slot_index < 1 or slot_index > MAX_SLOTS:
		push_error("无效的存档档位：%d" % slot_index)
		return false

	var dir := DirAccess.open(SAVE_DIR)
	if dir == null:
		DirAccess.make_dir_absolute(ProjectSettings.globalize_path(SAVE_DIR))

	var path := _get_save_path(slot_index)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("无法写入存档文件：%s" % path)
		return false

	var save_data: Dictionary = {
		"slot_index": slot_index,
		"saved_at": Time.get_datetime_string_from_system(),
		"payload": payload.duplicate(true),
	}

	file.store_string(JSON.stringify(save_data, "\t"))
	return true


func load_from_slot(slot_index: int) -> Dictionary:
	if slot_index < 1 or slot_index > MAX_SLOTS:
		push_error("无效的存档档位：%d" % slot_index)
		return {}

	var path := _get_save_path(slot_index)
	if not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("无法读取存档文件：%s" % path)
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed.get("payload", {})

	return {}


func clear_slot(slot_index: int) -> void:
	if slot_index < 1 or slot_index > MAX_SLOTS:
		return

	var path := _get_save_path(slot_index)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func get_slot_info(slot_index: int) -> Dictionary:
	if slot_index < 1 or slot_index > MAX_SLOTS:
		return {}

	var path := _get_save_path(slot_index)
	if not FileAccess.file_exists(path):
		return {
			"slot_index": slot_index,
			"exists": false,
			"saved_at": "",
			"level_id": 0,
			"player_gold": 0,
		}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {
			"slot_index": slot_index,
			"exists": false,
			"saved_at": "",
			"level_id": 0,
			"player_gold": 0,
		}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		var payload: Dictionary = parsed.get("payload", {})
		return {
			"slot_index": slot_index,
			"exists": true,
			"saved_at": str(parsed.get("saved_at", "")),
			"level_id": int(payload.get("current_level_id", 0)),
			"player_gold": int(payload.get("player_gold", 0)),
		}

	return {
		"slot_index": slot_index,
		"exists": false,
		"saved_at": "",
		"level_id": 0,
		"player_gold": 0,
	}


func get_all_slots_info() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for i in range(1, MAX_SLOTS + 1):
		result.append(get_slot_info(i))
	return result
