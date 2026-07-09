extends "res://scripts/pve/target_behavior.gd"

var _phase_offset: float = 0.0


func _ready() -> void:
	behavior_type = "moving"


func setup(owner, params: Dictionary = {}) -> void:
	super.setup(owner, params)
	_phase_offset = float(params.get("phase_offset", 0.0))


func _update_behavior(delta: float) -> void:
	if actor == null or not is_instance_valid(actor):
		return

	var now: float = Time.get_ticks_msec() / 1000.0
	var local_time: float = now + _phase_offset
	actor.global_position = actor.origin_position + Vector2(
		sin(local_time * move_speed),
		cos(local_time * move_speed * 0.65) * 0.25
	) * Vector2(move_range, actor.body_radius * 0.9)


func is_hittable() -> bool:
	return true
