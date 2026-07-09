extends Node

signal manifest_reloaded(success: bool, entry_count: int)

const MANIFEST_PATH := "res://configs/audio/audio_manifest.json"
const BUS_NAMES := ["BGM", "SFX", "UI", "AMB"]

var manifest_data: Dictionary = {}
var entries_by_id: Dictionary = {}
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var bgm_player: AudioStreamPlayer
var amb_player: AudioStreamPlayer

var _last_play_msec_by_event: Dictionary = {}
var _active_instances_by_event: Dictionary = {}
var _bgm_looping: bool = false
var _amb_looping: bool = false


func _ready() -> void:
	rng.randomize()
	_ensure_audio_buses()
	_build_persistent_players()
	reload_manifest()


func reload_manifest() -> bool:
	manifest_data.clear()
	entries_by_id.clear()

	if not FileAccess.file_exists(MANIFEST_PATH):
		push_warning("AudioService 未找到音频清单：%s" % MANIFEST_PATH)
		manifest_reloaded.emit(false, 0)
		return false

	var raw_text := FileAccess.get_file_as_string(MANIFEST_PATH)
	var parsed: Variant = JSON.parse_string(raw_text)
	if not (parsed is Dictionary):
		push_warning("AudioService 解析音频清单失败：%s" % MANIFEST_PATH)
		manifest_reloaded.emit(false, 0)
		return false

	manifest_data = parsed
	var entries: Array = manifest_data.get("entries", [])
	for raw_entry in entries:
		if not (raw_entry is Dictionary):
			continue
		var entry: Dictionary = _normalize_entry(raw_entry)
		var event_id := str(entry.get("event_id", ""))
		if event_id.is_empty():
			continue
		entries_by_id[event_id] = entry

	manifest_reloaded.emit(true, entries_by_id.size())
	return true


func has_event(event_id: String) -> bool:
	return entries_by_id.has(event_id)


func get_event_config(event_id: String) -> Dictionary:
	if not entries_by_id.has(event_id):
		return {}
	return (entries_by_id[event_id] as Dictionary).duplicate(true)


func play_sfx(event_id: String) -> Node:
	return _play_event_internal(event_id, "2d")


func play_ui(event_id: String) -> Node:
	return _play_event_internal(event_id, "2d")


func play_sfx_3d(event_id: String, world_position: Vector3) -> Node:
	return _play_event_internal(event_id, "3d", world_position)


func play_sfx_delayed(event_id: String, delay_sec: float) -> void:
	if delay_sec <= 0.0:
		_play_event_internal(event_id, "2d")
		return
	_play_event_delayed(event_id, "2d", delay_sec)


func play_sfx_3d_delayed(event_id: String, world_position: Vector3, delay_sec: float) -> void:
	if delay_sec <= 0.0:
		_play_event_internal(event_id, "3d", world_position)
		return
	_play_event_delayed(event_id, "3d", delay_sec, world_position)


func play_bgm(event_id: String, restart_if_same: bool = false) -> bool:
	var entry := _resolve_entry(event_id)
	if entry.is_empty():
		return false
	if str(entry.get("category", "")) != "bgm":
		push_warning("AudioService 事件 %s 不是 BGM 类型，仍按 BGM 播放。" % event_id)
	if str(bgm_player.get_meta("event_id", "")) == event_id and bgm_player.playing and not restart_if_same:
		return true
	return _play_persistent_event(bgm_player, entry)


func stop_bgm() -> void:
	if bgm_player != null and is_instance_valid(bgm_player):
		bgm_player.stop()
		bgm_player.set_meta("event_id", "")


func play_amb(event_id: String, restart_if_same: bool = false) -> bool:
	var entry := _resolve_entry(event_id)
	if entry.is_empty():
		return false
	if str(entry.get("category", "")) != "amb":
		push_warning("AudioService 事件 %s 不是环境音类型，仍按 AMB 播放。" % event_id)
	if str(amb_player.get_meta("event_id", "")) == event_id and amb_player.playing and not restart_if_same:
		return true
	return _play_persistent_event(amb_player, entry)


func stop_amb() -> void:
	if amb_player != null and is_instance_valid(amb_player):
		amb_player.stop()
		amb_player.set_meta("event_id", "")


func stop_event(event_id: String) -> void:
	if bgm_player != null and is_instance_valid(bgm_player) and str(bgm_player.get_meta("event_id", "")) == event_id:
		stop_bgm()
	if amb_player != null and is_instance_valid(amb_player) and str(amb_player.get_meta("event_id", "")) == event_id:
		stop_amb()


func bind_ui_button(button: BaseButton) -> void:
	if button == null or not is_instance_valid(button):
		return
	if bool(button.get_meta("audio_ui_click_bound", false)):
		return
	button.set_meta("audio_ui_click_bound", true)
	# pressed 信号无参数；多连接一次不会影响原有业务回调。
	if not button.pressed.is_connected(_on_bound_ui_button_pressed):
		button.pressed.connect(_on_bound_ui_button_pressed)


func _on_bound_ui_button_pressed() -> void:
	play_ui("ui_button_click")


func _play_event_internal(event_id: String, preferred_mode: String = "", world_position: Vector3 = Vector3.ZERO) -> Node:
	var entry := _resolve_entry(event_id)
	if entry.is_empty():
		return null
	if not _can_play_event(entry):
		return null

	var variant := _pick_variant(entry)
	var stream := _load_stream_from_variant(variant)
	if stream == null:
		push_warning("AudioService 事件 %s 没有可用音频资源。" % event_id)
		return null

	var resolved_mode := preferred_mode if not preferred_mode.is_empty() else str(entry.get("play_mode", "2d"))
	var pitch_scale := _roll_pitch(entry)
	var volume_db := float(entry.get("default_volume_db", 0.0))
	var bus_name := str(entry.get("bus", "SFX"))

	var player: Node = null
	if resolved_mode == "3d":
		player = _spawn_one_shot_3d(event_id, stream, bus_name, volume_db, pitch_scale, world_position)
	else:
		player = _spawn_one_shot_2d(event_id, stream, bus_name, volume_db, pitch_scale)

	if player != null:
		_last_play_msec_by_event[event_id] = Time.get_ticks_msec()
		_increment_active_instance(event_id)
	return player


func _play_event_delayed(event_id: String, preferred_mode: String, delay_sec: float, world_position: Vector3 = Vector3.ZERO) -> void:
	var tree := get_tree()
	if tree == null:
		_play_event_internal(event_id, preferred_mode, world_position)
		return
	await tree.create_timer(delay_sec).timeout
	_play_event_internal(event_id, preferred_mode, world_position)


func _play_persistent_event(player: AudioStreamPlayer, entry: Dictionary) -> bool:
	if player == null or not is_instance_valid(player):
		return false
	var variant := _pick_variant(entry)
	var stream := _load_stream_from_variant(variant)
	if stream == null:
		push_warning("AudioService 持续音频事件 %s 没有可用资源。" % str(entry.get("event_id", "")))
		return false

	player.stop()
	player.stream = stream
	player.set("bus", str(entry.get("bus", "Master")))
	player.volume_db = float(entry.get("default_volume_db", 0.0))
	player.pitch_scale = _roll_pitch(entry)
	player.set_meta("event_id", str(entry.get("event_id", "")))
	player.set_meta("loop_enabled", bool(entry.get("loop", false)))
	player.play()
	return true


func _spawn_one_shot_2d(event_id: String, stream: AudioStream, bus_name: String, volume_db: float, pitch_scale: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = "AudioOneShot2D_%s" % event_id
	player.stream = stream
	player.set("bus", bus_name)
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	add_child(player)
	player.finished.connect(_on_one_shot_finished.bind(event_id, player))
	player.play()
	return player


func _spawn_one_shot_3d(event_id: String, stream: AudioStream, bus_name: String, volume_db: float, pitch_scale: float, world_position: Vector3) -> AudioStreamPlayer3D:
	var host: Node = get_tree().current_scene if get_tree() != null else self
	if host == null:
		host = self

	var player := AudioStreamPlayer3D.new()
	player.name = "AudioOneShot3D_%s" % event_id
	player.stream = stream
	player.set("bus", bus_name)
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.max_distance = 28.0
	player.unit_size = 4.0
	host.add_child(player)
	player.global_position = world_position
	player.finished.connect(_on_one_shot_finished.bind(event_id, player))
	player.play()
	return player


func _on_one_shot_finished(event_id: String, player: Node) -> void:
	_decrement_active_instance(event_id)
	if player != null and is_instance_valid(player):
		player.queue_free()


func _resolve_entry(event_id: String) -> Dictionary:
	if not entries_by_id.has(event_id):
		push_warning("AudioService 未找到事件：%s" % event_id)
		return {}
	return entries_by_id[event_id] as Dictionary


func _normalize_entry(raw_entry: Dictionary) -> Dictionary:
	var entry := raw_entry.duplicate(true)
	entry["event_id"] = str(entry.get("event_id", ""))
	entry["display_name"] = str(entry.get("display_name", entry["event_id"]))
	entry["category"] = str(entry.get("category", "sfx")).to_lower()
	entry["bus"] = _normalize_bus_name(str(entry.get("bus", _default_bus_for_category(str(entry.get("category", "sfx"))))))
	entry["play_mode"] = str(entry.get("play_mode", "2d")).to_lower()
	entry["loop"] = bool(entry.get("loop", false))
	entry["default_volume_db"] = float(entry.get("default_volume_db", 0.0))
	entry["pitch_random_min"] = float(entry.get("pitch_random_min", 1.0))
	entry["pitch_random_max"] = float(entry.get("pitch_random_max", 1.0))
	entry["cooldown_ms"] = int(entry.get("cooldown_ms", 0))
	entry["max_instances"] = int(entry.get("max_instances", 0))
	entry["status"] = str(entry.get("status", "planned"))
	if not entry.has("variants") or not (entry["variants"] is Array):
		entry["variants"] = []
	return entry


func _default_bus_for_category(category: String) -> String:
	match category.to_lower():
		"bgm":
			return "BGM"
		"ui":
			return "UI"
		"amb":
			return "AMB"
		_:
			return "SFX"


func _normalize_bus_name(bus_name: String) -> String:
	var normalized := bus_name.strip_edges()
	if normalized.is_empty():
		return "SFX"
	match normalized.to_lower():
		"master":
			return "Master"
		"bgm":
			return "BGM"
		"ui":
			return "UI"
		"amb":
			return "AMB"
		_:
			return "SFX"


func _can_play_event(entry: Dictionary) -> bool:
	var event_id := str(entry.get("event_id", ""))
	if event_id.is_empty():
		return false

	var cooldown_ms := int(entry.get("cooldown_ms", 0))
	if cooldown_ms > 0:
		var now_msec := Time.get_ticks_msec()
		var last_msec := int(_last_play_msec_by_event.get(event_id, -cooldown_ms - 1))
		if now_msec - last_msec < cooldown_ms:
			return false

	var max_instances := int(entry.get("max_instances", 0))
	if max_instances > 0:
		var active_count := int(_active_instances_by_event.get(event_id, 0))
		if active_count >= max_instances:
			return false

	return true


func _increment_active_instance(event_id: String) -> void:
	_active_instances_by_event[event_id] = int(_active_instances_by_event.get(event_id, 0)) + 1


func _decrement_active_instance(event_id: String) -> void:
	var next_value: int = max(0, int(_active_instances_by_event.get(event_id, 0)) - 1)
	if next_value <= 0:
		_active_instances_by_event.erase(event_id)
		return
	_active_instances_by_event[event_id] = next_value


func _pick_variant(entry: Dictionary) -> Dictionary:
	var variants: Array = entry.get("variants", [])
	if variants.is_empty():
		return {}

	var total_weight := 0
	for item in variants:
		if item is Dictionary:
			total_weight += max(1, int(item.get("weight", 1)))
	if total_weight <= 0:
		return variants[0] as Dictionary

	var roll := rng.randi_range(1, total_weight)
	var cursor := 0
	for item in variants:
		if not (item is Dictionary):
			continue
		cursor += max(1, int(item.get("weight", 1)))
		if roll <= cursor:
			return item as Dictionary
	return variants[0] as Dictionary


func _load_stream_from_variant(variant: Dictionary) -> AudioStream:
	if variant.is_empty():
		return null
	var asset_path := str(variant.get("asset_path", ""))
	if asset_path.is_empty():
		return null
	var loaded: Variant = load(asset_path)
	return loaded if loaded is AudioStream else null


func _roll_pitch(entry: Dictionary) -> float:
	var min_pitch := float(entry.get("pitch_random_min", 1.0))
	var max_pitch := float(entry.get("pitch_random_max", 1.0))
	if max_pitch < min_pitch:
		var temp := min_pitch
		min_pitch = max_pitch
		max_pitch = temp
	if is_equal_approx(min_pitch, max_pitch):
		return min_pitch
	return rng.randf_range(min_pitch, max_pitch)


func _ensure_audio_buses() -> void:
	for bus_name in BUS_NAMES:
		if AudioServer.get_bus_index(bus_name) != -1:
			continue
		AudioServer.add_bus()
		var bus_index := AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(bus_index, bus_name)
		AudioServer.set_bus_send(bus_index, "Master")


func _build_persistent_players() -> void:
	if bgm_player == null:
		bgm_player = AudioStreamPlayer.new()
		bgm_player.name = "BgmPlayer"
		bgm_player.set("bus", "BGM")
		add_child(bgm_player)
		if not bgm_player.finished.is_connected(_on_bgm_finished):
			bgm_player.finished.connect(_on_bgm_finished)

	if amb_player == null:
		amb_player = AudioStreamPlayer.new()
		amb_player.name = "AmbPlayer"
		amb_player.set("bus", "AMB")
		add_child(amb_player)
		if not amb_player.finished.is_connected(_on_amb_finished):
			amb_player.finished.connect(_on_amb_finished)


func _on_bgm_finished() -> void:
	if bgm_player == null or not is_instance_valid(bgm_player):
		return
	if not bool(bgm_player.get_meta("loop_enabled", false)):
		return
	var event_id := str(bgm_player.get_meta("event_id", ""))
	if event_id.is_empty():
		return
	# 结束后重播：可能有极短间隙，但能保证最小可用的循环行为。
	play_bgm(event_id, true)


func _on_amb_finished() -> void:
	if amb_player == null or not is_instance_valid(amb_player):
		return
	if not bool(amb_player.get_meta("loop_enabled", false)):
		return
	var event_id := str(amb_player.get_meta("event_id", ""))
	if event_id.is_empty():
		return
	play_amb(event_id, true)
