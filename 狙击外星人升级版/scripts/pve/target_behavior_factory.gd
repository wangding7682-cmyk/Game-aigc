extends Node

const TARGET_BEHAVIOR_STATIC_SCRIPT = preload("res://scripts/pve/target_behavior_static.gd")
const TARGET_BEHAVIOR_MOVING_SCRIPT = preload("res://scripts/pve/target_behavior_moving.gd")
const TARGET_BEHAVIOR_WEAKPOINT_SCRIPT = preload("res://scripts/pve/target_behavior_weakpoint.gd")
const TARGET_BEHAVIOR_CIVILIAN_SCRIPT = preload("res://scripts/pve/target_behavior_civilian.gd")


func create_behavior(behavior_type: String, owner, params: Dictionary = {}):
	match behavior_type:
		"moving":
			var behavior = TARGET_BEHAVIOR_MOVING_SCRIPT.new()
			behavior.setup(owner, params)
			return behavior
		"weakpoint":
			var behavior = TARGET_BEHAVIOR_WEAKPOINT_SCRIPT.new()
			behavior.setup(owner, params)
			return behavior
		"civilian":
			var behavior = TARGET_BEHAVIOR_CIVILIAN_SCRIPT.new()
			behavior.setup(owner, params)
			return behavior
		_:
			var behavior = TARGET_BEHAVIOR_STATIC_SCRIPT.new()
			behavior.setup(owner, params)
			return behavior


func create_and_attach(behavior_type: String, owner, params: Dictionary = {}):
	var behavior = create_behavior(behavior_type, owner, params)
	owner.add_child(behavior)
	return behavior
