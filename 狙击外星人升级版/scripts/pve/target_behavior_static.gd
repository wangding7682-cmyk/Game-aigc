extends "res://scripts/pve/target_behavior.gd"

func _ready() -> void:
	behavior_type = "static"


func _update_behavior(delta: float) -> void:
	pass


func is_hittable() -> bool:
	return true
