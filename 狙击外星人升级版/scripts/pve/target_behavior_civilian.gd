extends "res://scripts/pve/target_behavior.gd"

var _phase_offset: float = 0.0

var false_clue_profile: Array[String] = []
var false_clue_active: bool = false
var false_clue_until: float = 0.0
var false_clue_cycle_sec: float = 0.0
var false_clue_window_sec: float = 0.0


func _ready() -> void:
	behavior_type = "civilian"


func setup(owner, params: Dictionary = {}) -> void:
	super.setup(owner, params)
	_phase_offset = float(params.get("phase_offset", 0.0))
	move_speed = float(params.get("move_speed", 0.55))
	
	false_clue_profile.clear()
	for clue in params.get("false_clue_profile", []):
		false_clue_profile.append(str(clue))
	false_clue_cycle_sec = float(params.get("false_clue_cycle_sec", 0.0))
	false_clue_window_sec = float(params.get("false_clue_window_sec", 0.0))


func _update_behavior(delta: float) -> void:
	if actor == null or not is_instance_valid(actor):
		return

	var now: float = Time.get_ticks_msec() / 1000.0
	var local_time: float = now + _phase_offset

	if false_clue_cycle_sec > 0.0 and false_clue_window_sec > 0.0:
		false_clue_active = fmod(local_time, false_clue_cycle_sec) <= false_clue_window_sec
	else:
		false_clue_active = false_clue_active and now <= false_clue_until

	actor.global_position = actor.origin_position + Vector2(
		sin(local_time * move_speed),
		0.0
	) * Vector2(move_range * 0.55, 0.0)


func is_hittable() -> bool:
	return true


func trigger_false_clue(seconds: float) -> void:
	false_clue_active = true
	false_clue_until = maxf(false_clue_until, Time.get_ticks_msec() / 1000.0 + seconds)


func has_false_clue_active() -> bool:
	return false_clue_active


func get_false_clue_summary() -> String:
	if false_clue_active and not false_clue_profile.is_empty():
		return "、".join(false_clue_profile)
	return ""
