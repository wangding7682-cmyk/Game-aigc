extends Node

var behavior_type: String = "static"
var actor = null

var move_range: float = 0.0
var move_speed: float = 0.0

var reveal_cycle_sec: float = 0.0
var reveal_window_sec: float = 0.0
var weakpoint_open: bool = true


func setup(owner, params: Dictionary = {}) -> void:
	actor = owner
	move_range = float(params.get("move_range", 0.0))
	move_speed = float(params.get("move_speed", 0.0))
	reveal_cycle_sec = float(params.get("reveal_cycle_sec", 0.0))
	reveal_window_sec = float(params.get("reveal_window_sec", 0.0))


func _process(delta: float) -> void:
	_update_behavior(delta)


func _update_behavior(delta: float) -> void:
	pass


func is_hittable() -> bool:
	return true


func get_behavior_params() -> Dictionary:
	return {
		"behavior_type": behavior_type,
		"move_range": move_range,
		"move_speed": move_speed,
		"reveal_cycle_sec": reveal_cycle_sec,
		"reveal_window_sec": reveal_window_sec,
	}
