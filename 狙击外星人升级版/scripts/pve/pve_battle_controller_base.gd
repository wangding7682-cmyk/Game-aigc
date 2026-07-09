extends Node3D

@warning_ignore("unused_signal")
signal battle_finished(result: Dictionary)

var level_config = null
var hud = null
var tutorial_flow: Control = null

var feedback_messages: Array[Dictionary] = []
var feedback_lifespan_sec: float = 2.2

var cover_scan_fade_timer: float = 0.0
var cover_scan_fade_total: float = 0.0

var last_identification_replay: String = ""
var identification_replay_timer: float = 0.0

var tutorial_primary_target = null
var locator_target = null
var locator_hint_timer: float = 0.0


func _ready() -> void:
	pass


func setup_level() -> void:
	level_config = CoreGameState.get_level_config()


func mount_hud(hud_scene: PackedScene) -> void:
	hud = hud_scene.instantiate()
	add_child(hud)


func mount_tutorial(tutorial_scene: PackedScene) -> void:
	if not CoreGameState.is_tutorial_active():
		return

	tutorial_flow = tutorial_scene.instantiate()
	add_child(tutorial_flow)
	tutorial_flow.show_step(CoreGameState.get_tutorial_step_data())
	CoreGameState.record_tutorial_started(level_config.level_id)


func push_feedback(text: String, color: Color = Color.WHITE) -> void:
	feedback_messages.append({
		"text": text,
		"color": color,
		"lifetime": feedback_lifespan_sec,
		"time": Time.get_ticks_msec(),
	})


func update_feedback(delta: float) -> void:
	for i in range(feedback_messages.size() - 1, -1, -1):
		feedback_messages[i]["lifetime"] -= delta
		if feedback_messages[i]["lifetime"] <= 0.0:
			feedback_messages.remove_at(i)


func update_cover_fade(cover_obstacles: Array) -> void:
	if cover_obstacles.is_empty():
		return
	var ratio := 0.0
	if cover_scan_fade_total > 0.0:
		ratio = clampf(cover_scan_fade_timer / cover_scan_fade_total, 0.0, 1.0)
	for obstacle in cover_obstacles:
		if obstacle != null and is_instance_valid(obstacle):
			obstacle.set_scan_fade_ratio(ratio)


func is_tutorial_active() -> bool:
	return CoreGameState.is_tutorial_active()


func can_execute_tutorial_action(action_name: StringName) -> bool:
	if not is_tutorial_active():
		return true

	if CoreGameState.is_tutorial_action_unlocked(action_name):
		return true

	CoreEventBus.log_event("tutorial_blocked", {
		"step_index": CoreGameState.get_tutorial_step_data().get("index", 0),
		"expected_text": CoreGameState.get_tutorial_step_data().get("expected_text", ""),
	})
	return false


func try_progress_tutorial(action_name: StringName, extra: Dictionary = {}) -> Dictionary:
	if not is_tutorial_active():
		return {"progressed": false}

	var progress: Dictionary = CoreGameState.try_progress_tutorial(action_name, extra)
	if bool(progress.get("progressed", false)):
		if bool(progress.get("completed", false)):
			push_feedback("教程完成，道具和战斗操作已全部开放。", Color(0.58, 1.0, 0.72))
		else:
			var next_step: Dictionary = progress.get("step", {})
			push_feedback("教程推进：%s" % str(next_step.get("title", "")), Color(0.68, 0.9, 1.0))
	return progress


func describe_direction_from_position(from_pos: Vector2, to_pos: Vector2) -> String:
	var delta: Vector2 = to_pos - from_pos
	var horizontal := ""
	var vertical := ""

	if delta.x < -40.0:
		horizontal = "左侧"
	elif delta.x > 40.0:
		horizontal = "右侧"

	if delta.y < -40.0:
		vertical = "上方"
	elif delta.y > 40.0:
		vertical = "下方"

	if not horizontal.is_empty() and not vertical.is_empty():
		return "%s%s" % [vertical, horizontal]
	if not vertical.is_empty():
		return vertical
	if not horizontal.is_empty():
		return horizontal
	return "正前方"


func handle_common_input(_event: InputEvent) -> bool:
	if Input.is_action_just_pressed("ui_back"):
		if has_method("_request_pause_overlay"):
			call("_request_pause_overlay", "keyboard_back")
		return true
	return false


func log_level_entered() -> void:
	CoreEventBus.log_event("level_entered", {
		"level_id": level_config.level_id,
		"level_name": level_config.display_name,
		"tutorial_active": CoreGameState.is_tutorial_active(),
		"target_goal": int(level_config.required_targets),
		"moving_targets": int(level_config.moving_targets),
		"weakpoint_targets": int(level_config.weakpoint_targets),
	})
	if level_config.level_id == 1:
		CoreEventBus.log_event("level_1_entered", {
			"tutorial_active": CoreGameState.is_tutorial_active(),
		})
