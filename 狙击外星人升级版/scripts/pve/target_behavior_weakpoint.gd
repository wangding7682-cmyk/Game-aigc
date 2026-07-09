extends "res://scripts/pve/target_behavior.gd"

var _phase_offset: float = 0.0


func _ready() -> void:
	behavior_type = "weakpoint"


func setup(owner, params: Dictionary = {}) -> void:
	super.setup(owner, params)
	_phase_offset = float(params.get("phase_offset", 0.0))
	if reveal_cycle_sec <= 0.0:
		reveal_cycle_sec = 2.2
	if reveal_window_sec <= 0.0:
		reveal_window_sec = 0.9


func _update_behavior(delta: float) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	var local_time: float = now + _phase_offset
	weakpoint_open = fmod(local_time, reveal_cycle_sec) <= reveal_window_sec


func is_hittable() -> bool:
	return weakpoint_open
